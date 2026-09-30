#!/usr/bin/env python3
"""App Store Connect follow-up for a TestFlight upload (standard library only, Python 3.9+).

Waits for the build to finish processing, then sets its "What to Test" notes and, when asked,
adds it to an external TestFlight group and submits it for Beta App Review. Run in the
background by ship-testflight.sh; it never fails the ship, it only logs.

    python3 scripts/ios/asc.py --bundle-id com.example.astrolex --version 0.1.0 \
        --build 260930.1432 --notes build/notes-260930.1432.txt [--external-group Friends]

Reads ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH from the environment.
HTTP goes through curl so macOS certificate handling is the system's.
"""
import argparse
import base64
import json
import os
import subprocess
import sys
import time
import urllib.parse

API = "https://api.appstoreconnect.apple.com/v1"
WHATS_NEW_LIMIT = 4000


def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _der_read(data, pos, tag):
    if data[pos] != tag:
        raise ValueError("DER: expected tag 0x%02x at %d, found 0x%02x" % (tag, pos, data[pos]))
    pos += 1
    length = data[pos]
    pos += 1
    if length & 0x80:
        count = length & 0x7F
        length = int.from_bytes(data[pos:pos + count], "big")
        pos += count
    return data[pos:pos + length], pos + length


def der_to_raw(der, size=32):
    """ECDSA signature: DER SEQUENCE{INTEGER r, INTEGER s} -> r||s, each `size` bytes (JWS ES256)."""
    body, _ = _der_read(der, 0, 0x30)
    r, pos = _der_read(body, 0, 0x02)
    s, _ = _der_read(body, pos, 0x02)
    out = b""
    for part in (r, s):
        part = part.lstrip(b"\x00")
        if len(part) > size:
            raise ValueError("DER integer longer than %d bytes" % size)
        out += part.rjust(size, b"\x00")
    return out


def make_token(key_id, issuer_id, key_path, now=None, lifetime=1200):
    """ES256 JWT for the App Store Connect API, signed with openssl."""
    now = int(time.time() if now is None else now)
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {"iss": issuer_id, "iat": now, "exp": now + lifetime, "aud": "appstoreconnect-v1"}
    signing_input = (
        b64url(json.dumps(header, separators=(",", ":")).encode())
        + "."
        + b64url(json.dumps(payload, separators=(",", ":")).encode())
    )
    der = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", key_path],
        input=signing_input.encode(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    ).stdout
    return signing_input + "." + b64url(der_to_raw(der))


def trim_notes(text, limit=WHATS_NEW_LIMIT):
    text = text.strip()
    if len(text) <= limit:
        return text
    return text[: limit - 2].rstrip() + "\n…"


class Client:
    def __init__(self, key_id, issuer_id, key_path):
        self.key_id, self.issuer_id, self.key_path = key_id, issuer_id, key_path
        self._token, self._token_at = None, 0

    def token(self):
        if self._token is None or time.time() - self._token_at > 900:
            self._token = make_token(self.key_id, self.issuer_id, self.key_path)
            self._token_at = time.time()
        return self._token

    def call(self, method, path, params=None, body=None):
        url = API + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        cmd = [
            "curl", "-sS", "-X", method, url,
            "-H", "Authorization: Bearer " + self.token(),
            "-H", "Content-Type: application/json",
            "-w", "\n%{http_code}",
        ]
        if body is not None:
            cmd += ["--data-binary", "@-"]
        result = subprocess.run(
            cmd,
            input=json.dumps(body).encode() if body is not None else None,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if result.returncode != 0:
            raise RuntimeError("curl failed: " + result.stderr.decode(errors="replace").strip())
        text, _, status = result.stdout.decode(errors="replace").rpartition("\n")
        status = int(status or 0)
        data = json.loads(text) if text.strip() else {}
        if status >= 400:
            raise RuntimeError("%s %s -> %d: %s" % (method, path, status, json.dumps(data.get("errors", data))[:600]))
        return data


def log(message):
    print(time.strftime("%H:%M:%S ") + message, flush=True)


def find_app(client, bundle_id):
    apps = client.call("GET", "/apps", {"filter[bundleId]": bundle_id, "fields[apps]": "bundleId,name"})["data"]
    if not apps:
        raise RuntimeError("No App Store Connect app with bundle ID %s. Create the app record first." % bundle_id)
    return apps[0]["id"]


def wait_for_build(client, app_id, version, build, timeout_s, poll_s):
    params = {
        "filter[app]": app_id,
        "filter[version]": build,
        "filter[preReleaseVersion.version]": version,
        "fields[builds]": "version,processingState",
    }
    deadline = time.time() + timeout_s
    state = "not visible yet"
    while time.time() < deadline:
        builds = client.call("GET", "/builds", params)["data"]
        if builds:
            state = builds[0]["attributes"]["processingState"]
            if state == "VALID":
                return builds[0]["id"]
            if state in ("FAILED", "INVALID"):
                raise RuntimeError("Build %s processing ended as %s; check App Store Connect email." % (build, state))
        log("build %s: %s" % (build, state))
        time.sleep(poll_s)
    raise RuntimeError("Build %s still %s after %d minutes." % (build, state, timeout_s // 60))


def set_whats_new(client, build_id, notes, locale="en-US"):
    existing = client.call("GET", "/builds/%s/betaBuildLocalizations" % build_id)["data"]
    for loc in existing:
        if loc["attributes"].get("locale") == locale:
            client.call("PATCH", "/betaBuildLocalizations/" + loc["id"], body={"data": {
                "type": "betaBuildLocalizations", "id": loc["id"], "attributes": {"whatsNew": notes}}})
            return
    client.call("POST", "/betaBuildLocalizations", body={"data": {
        "type": "betaBuildLocalizations",
        "attributes": {"locale": locale, "whatsNew": notes},
        "relationships": {"build": {"data": {"type": "builds", "id": build_id}}},
    }})


def send_to_external_group(client, app_id, build_id, group_name):
    groups = client.call("GET", "/betaGroups", {"filter[app]": app_id, "filter[name]": group_name})["data"]
    if not groups:
        raise RuntimeError("No TestFlight group named %r. Create it in App Store Connect first." % group_name)
    client.call("POST", "/betaGroups/%s/relationships/builds" % groups[0]["id"],
                body={"data": [{"type": "builds", "id": build_id}]})
    try:
        client.call("POST", "/betaAppReviewSubmissions", body={"data": {
            "type": "betaAppReviewSubmissions",
            "relationships": {"build": {"data": {"type": "builds", "id": build_id}}},
        }})
        log("submitted for Beta App Review")
    except RuntimeError as err:
        # Already submitted, or approval carried over from an earlier build of this version.
        log("beta review submission skipped: %s" % err)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--version", required=True, help="marketing version, e.g. 0.1.0")
    parser.add_argument("--build", required=True, help="build number (CFBundleVersion)")
    parser.add_argument("--notes", help="file with What to Test text")
    parser.add_argument("--external-group", help="external TestFlight group to add the build to")
    parser.add_argument("--timeout-min", type=int, default=60)
    parser.add_argument("--poll-s", type=int, default=30)
    args = parser.parse_args(argv)

    missing = [k for k in ("ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_KEY_PATH") if not os.environ.get(k)]
    if missing:
        log("missing environment: " + ", ".join(missing))
        return 1
    client = Client(os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"], os.path.expanduser(os.environ["ASC_KEY_PATH"]))
    try:
        app_id = find_app(client, args.bundle_id)
        build_id = wait_for_build(client, app_id, args.version, args.build, args.timeout_min * 60, args.poll_s)
        log("build %s is VALID (id %s)" % (args.build, build_id))
        if args.notes:
            with open(args.notes, encoding="utf-8") as fh:
                set_whats_new(client, build_id, trim_notes(fh.read()))
            log("What to Test notes set")
        if args.external_group:
            send_to_external_group(client, app_id, build_id, args.external_group)
            log("added to external group %r" % args.external_group)
        log("done: build %s is on TestFlight" % args.build)
        return 0
    except Exception as err:  # best effort: report, never raise into the ship script
        log("error: %s" % err)
        return 1


if __name__ == "__main__":
    sys.exit(main())
