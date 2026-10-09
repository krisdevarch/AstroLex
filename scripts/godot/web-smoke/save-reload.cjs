//   node save-reload.cjs <build/web dir>
// Loads index.html?savetest=1&win=1 (records level 1-01 as won), reloads the page in the same
// browser context with ?savetest=1, and expects the console line "AstroLex save next=1-02".
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const dir = path.resolve(process.argv[2] || 'build/web');
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png' };
const NEXT = /AstroLex save next=(\S+)/;
const TIMEOUT_MS = 120000;
const GAP_MS = parseInt(process.env.GAP_MS || "1000", 10); // wait after the "save next=" line before navigating

const server = http.createServer((req, res) => {
  const file = path.join(dir, decodeURIComponent(req.url.split('?')[0]).replace(/^\/$/, '/index.html'));
  if (!file.startsWith(dir) || !fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});

(async () => {
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}/index.html`;
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || '/opt/pw-browsers/chromium',
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
  });
  const context = await browser.newContext({ viewport: { width: 432, height: 768 } });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  const nextLine = () => page.waitForEvent('console', { predicate: (m) => NEXT.test(m.text()), timeout: TIMEOUT_MS }).catch(() => null);

  let p1 = nextLine();
  await page.goto(base + '?savetest=1&win=1');
  const first = await p1;
  // Give Godot time to flush user:// to IndexedDB.
  await page.waitForTimeout(GAP_MS);
  const p2 = nextLine();
  await page.goto(base + '?savetest=1');
  const second = await p2;
  await browser.close();
  server.close();

  const a = first && NEXT.exec(first.text())[1];
  const b = second && NEXT.exec(second.text())[1];
  console.log(`first visit (1-01 recorded): next=${a}; after reload: next=${b}`);
  if (errors.length) { console.error('FAIL: browser errors:\n' + errors.join('\n')); process.exit(1); }
  if (b !== '1-02') { console.error('FAIL: expected next=1-02 after reload'); process.exit(1); }
})().catch((e) => { console.error('FAIL', e); server.close(); process.exit(1); });
