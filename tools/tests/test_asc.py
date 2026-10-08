"""scripts/ios/asc.py: the ES256 JWT it sends to App Store Connect must verify with the key."""
import base64
import importlib.util
import json
import shutil
import subprocess

import pytest

from astrolex_tools import repo_root

spec = importlib.util.spec_from_file_location("asc", repo_root() / "scripts/ios/asc.py")
asc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(asc)

needs_openssl = pytest.mark.skipif(shutil.which("openssl") is None, reason="openssl not installed")


def unb64(text):
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def raw_to_der(raw):
    def integer(b):
        b = b.lstrip(b"\x00") or b"\x00"
        if b[0] & 0x80:
            b = b"\x00" + b
        return b"\x02" + bytes([len(b)]) + b
    body = integer(raw[:32]) + integer(raw[32:])
    return b"\x30" + bytes([len(body)]) + body


def test_der_to_raw_pads_and_strips():
    r = b"\x00" + b"\x80" + b"\x11" * 31  # 33 bytes with sign padding
    s = b"\x05" * 30  # short integer
    der = b"\x30" + bytes([4 + len(r) + len(s)]) + b"\x02" + bytes([len(r)]) + r + b"\x02" + bytes([len(s)]) + s
    raw = asc.der_to_raw(der)
    assert len(raw) == 64
    assert raw[:32] == r[1:]
    assert raw[32:] == b"\x00\x00" + s


def test_der_to_raw_rejects_garbage():
    with pytest.raises(ValueError):
        asc.der_to_raw(b"\x31\x00")


def test_trim_notes_respects_limit():
    assert asc.trim_notes("  hi \n") == "hi"
    long = "- change\n" * 1000
    trimmed = asc.trim_notes(long)
    assert len(trimmed) <= asc.WHATS_NEW_LIMIT


@needs_openssl
def test_token_verifies_with_public_key(tmp_path):
    key = tmp_path / "AuthKey_TEST.p8"
    pub = tmp_path / "pub.pem"
    subprocess.run(["openssl", "genpkey", "-algorithm", "EC", "-pkeyopt", "ec_paramgen_curve:P-256",
                    "-out", str(key)], check=True, capture_output=True)
    subprocess.run(["openssl", "pkey", "-in", str(key), "-pubout", "-out", str(pub)], check=True, capture_output=True)

    token = asc.make_token("KEY123", "issuer-uuid", str(key), now=1_700_000_000)
    head, payload, sig = token.split(".")
    assert json.loads(unb64(head)) == {"alg": "ES256", "kid": "KEY123", "typ": "JWT"}
    claims = json.loads(unb64(payload))
    assert claims == {"iss": "issuer-uuid", "iat": 1_700_000_000, "exp": 1_700_001_200, "aud": "appstoreconnect-v1"}
    assert claims["exp"] - claims["iat"] <= 1200  # Apple rejects tokens living longer than 20 minutes

    raw = unb64(sig)
    assert len(raw) == 64
    sig_file = tmp_path / "sig.der"
    sig_file.write_bytes(raw_to_der(raw))
    verify = subprocess.run(["openssl", "dgst", "-sha256", "-verify", str(pub), "-signature", str(sig_file)],
                            input=f"{head}.{payload}".encode(), capture_output=True)
    assert verify.returncode == 0, verify.stdout + verify.stderr
