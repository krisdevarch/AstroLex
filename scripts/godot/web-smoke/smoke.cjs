// Boots the Godot web export in headless Chromium and checks that the main scene ran.
//   node smoke.cjs <build/web dir> [screenshot.png]
// Serves the folder itself (wasm needs a real HTTP server and the application/wasm type),
// waits for "AstroLex ready" on the console, fails on page errors or a timeout.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const dir = path.resolve(process.argv[2] || 'build/web');
const shot = process.argv[3];
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png' };
const READY = /AstroLex ready: (\d+) tiles/;
const TIMEOUT_MS = 120000;

const server = http.createServer((req, res) => {
  const file = path.join(dir, decodeURIComponent(req.url.split('?')[0]).replace(/^\/$/, '/index.html'));
  if (!file.startsWith(dir) || !fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});

(async () => {
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const url = `http://127.0.0.1:${server.address().port}/index.html`;
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
  });
  const page = await browser.newPage({ viewport: { width: 432, height: 768 } });
  const errors = [];
  const lines = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => { lines.push(m.text()); if (m.type() === 'error') errors.push(m.text()); });

  const t0 = Date.now();
  await page.goto(url);
  const ready = await page.waitForEvent('console', { predicate: (m) => READY.test(m.text()), timeout: TIMEOUT_MS }).catch(() => null);
  const ms = Date.now() - t0;
  if (shot) { await page.waitForTimeout(1000); await page.screenshot({ path: shot }); }
  await browser.close();
  server.close();

  console.log(lines.filter((l) => /Godot Engine|OpenGL API|Build configuration|AstroLex/.test(l)).join('\n'));
  if (!ready) { console.error(`FAIL: no "AstroLex ready" line within ${TIMEOUT_MS / 1000} s`); process.exit(1); }
  if (errors.length) { console.error('FAIL: browser errors:\n' + errors.join('\n')); process.exit(1); }
  console.log(`ok: main scene ran in ${(ms / 1000).toFixed(1)} s (${READY.exec(ready.text())[1]} tiles)`);
})().catch((e) => { console.error('FAIL', e); server.close(); process.exit(1); });
