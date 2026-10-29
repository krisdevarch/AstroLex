// Measures how long the web build takes to load on a throttled phone-like connection.
//   node loadtime.cjs <build/web dir> [--mbps=10] [--rtt=150] [--runs=2] [--no-gzip]
// Serves the folder the way GitHub Pages does (gzip on the fly when the browser asks), throttles
// the network with the DevTools protocol, and reports bytes on the wire plus the time until
// "AstroLex ready" (main scene running) for a cold load (empty cache).
const http = require('http');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { chromium } = require('playwright');

const args = process.argv.slice(2);
const opt = (name, def) => { const a = args.find((x) => x.startsWith(`--${name}=`)); return a ? Number(a.split('=')[1]) : def; };
const MBPS = opt('mbps', 10);
const RTT = opt('rtt', 150);
const RUNS = opt('runs', 2);
const GZIP = !args.includes('--no-gzip');
const dir = path.resolve(args.filter((a) => !a.startsWith('--'))[0] || 'build/web');
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png', '.json': 'application/json' };
const READY = /AstroLex ready/;

const cache = new Map();
const server = http.createServer((req, res) => {
  const file = path.join(dir, decodeURIComponent(req.url.split('?')[0]).replace(/^\/$/, '/index.html'));
  if (!file.startsWith(dir) || !fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
  const stat = fs.statSync(file);
  const etag = `"${stat.size}-${stat.mtimeMs}"`;
  const headers = { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream', ETag: etag, 'Cache-Control': 'max-age=600' };
  if (req.headers['if-none-match'] === etag) { res.writeHead(304, headers); res.end(); return; }
  let body = fs.readFileSync(file);
  if (GZIP && /gzip/.test(req.headers['accept-encoding'] || '')) {
    if (!cache.has(file + etag)) cache.set(file + etag, zlib.gzipSync(body, { level: 6 }));
    body = cache.get(file + etag);
    headers['Content-Encoding'] = 'gzip';
  }
  headers['Content-Length'] = body.length;
  res.writeHead(200, headers);
  res.end(body);
});

async function load(page, cdp, url) {
  let bytes = 0;
  const onData = (e) => { bytes += e.encodedDataLength; };
  cdp.on('Network.loadingFinished', onData);
  const t0 = Date.now();
  await page.goto(url);
  const ok = await page.waitForEvent('console', { predicate: (m) => READY.test(m.text()), timeout: 300000 }).then(() => true, () => false);
  const ms = Date.now() - t0;
  cdp.off('Network.loadingFinished', onData);
  return { ok, ms, bytes };
}

(async () => {
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const url = `http://127.0.0.1:${server.address().port}/index.html?intro=0`;
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
  });
  const files = fs.readdirSync(dir).filter((f) => /^index\.(wasm|pck|js|html)$/.test(f));
  console.log(`build: ${dir}`);
  for (const f of files) {
    const raw = fs.readFileSync(path.join(dir, f));
    console.log(`  ${f.padEnd(11)} ${(raw.length / 1e6).toFixed(2).padStart(6)} MB raw, ${(zlib.gzipSync(raw, { level: 6 }).length / 1e6).toFixed(2).padStart(6)} MB gzip`);
  }
  console.log(`network: ${MBPS} Mbit/s down, ${RTT} ms RTT, gzip ${GZIP ? 'on' : 'off'}`);
  for (let i = 0; i < RUNS; i++) {
    const page = await browser.newPage({ viewport: { width: 432, height: 768 } });
    const cdp = await page.context().newCDPSession(page);
    await cdp.send('Network.enable');
    await cdp.send('Network.clearBrowserCache');
    await cdp.send('Network.emulateNetworkConditions', {
      offline: false, latency: RTT, downloadThroughput: (MBPS * 1e6) / 8, uploadThroughput: (MBPS * 1e6) / 8 / 4,
    });
    const cold = await load(page, cdp, url);
    console.log(`run ${i + 1}: cold load ${(cold.ms / 1000).toFixed(1)} s, ${(cold.bytes / 1e6).toFixed(2)} MB on the wire${cold.ok ? '' : '  FAIL: not ready'}`);
    if (!cold.ok) process.exitCode = 1;
    await page.close();
  }
  await browser.close();
  server.close();
})().catch((e) => { console.error('FAIL', e); server.close(); process.exit(1); });
