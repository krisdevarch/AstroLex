// Screenshots the web build's loading screen mid-download on a throttled network (WP-F.13c).
//   node loading.cjs <build/web dir> [out.jpg] [--kbps=3000]
// Serves the folder, throttles with CDP (default ~3 MB/s), waits until the progress bar is
// between 20% and 80%, writes a 430x932 screenshot, and checks the overlay is there and the
// percent text matches the bar. Then lets the load finish and checks the overlay fades away.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const args = process.argv.slice(2);
const pos = args.filter((a) => !a.startsWith('--'));
const dir = path.resolve(pos[0] || 'build/web');
const out = pos[1] || 'loading.jpg';
const KBPS = Number((args.find((a) => a.startsWith('--kbps=')) || '--kbps=3000').split('=')[1]);
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png' };

const server = http.createServer((req, res) => {
  const file = path.join(dir, decodeURIComponent(req.url.split('?')[0]).replace(/^\/$/, '/index.html'));
  if (!file.startsWith(dir) || !fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream', 'Content-Length': fs.statSync(file).size });
  fs.createReadStream(file).pipe(res);
});

(async () => {
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
  });
  const page = await browser.newPage({ viewport: { width: 430, height: 932 }, deviceScaleFactor: 2 });
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Network.enable');
  await cdp.send('Network.emulateNetworkConditions', { offline: false, latency: 80, downloadThroughput: KBPS * 1024, uploadThroughput: KBPS * 1024 });
  await page.goto(`http://127.0.0.1:${server.address().port}/index.html`, { waitUntil: 'commit' });
  await page.waitForSelector('#status-progress', { state: 'visible', timeout: 30000 });
  await page.waitForFunction(() => {
    const p = document.getElementById('status-progress');
    return p && p.max > 1 && p.value / p.max > 0.4;
  }, null, { timeout: 120000, polling: 100 });
  const state = await page.evaluate(() => {
    const p = document.getElementById('status-progress');
    return { pct: document.getElementById('status-percent').textContent, frac: p.value / p.max, text: document.getElementById('status').innerText.replace(/\s+/g, ' ').trim() };
  });
  await page.screenshot({ path: out, type: 'jpeg', quality: 88 });
  console.log(`mid-load: ${state.pct} (bar ${(state.frac * 100).toFixed(0)}%), overlay text: "${state.text}"`);
  await cdp.send('Network.emulateNetworkConditions', { offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1 });
  await page.waitForSelector('#status', { state: 'detached', timeout: 120000 });
  console.log('overlay removed after engine start');
  await browser.close();
  server.close();
  const bad = [];
  if (!/^\d+%$/.test(state.pct)) bad.push('percent text missing');
  if (state.text.replace(/AstroLex|\d+%|[A-Z]/g, '').trim()) bad.push('unexpected overlay text: ' + state.text);
  if (errors.length) bad.push(...errors);
  if (bad.length) { console.error('FAIL:\n' + bad.join('\n')); process.exit(1); }
  console.log('ok: loading screen');
})().catch((e) => { console.error('FAIL', e); server.close(); process.exit(1); });
