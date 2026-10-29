// Like frames.cjs, but a 390x844 phone at device pixel ratio 3, saved as PNG, for checking how sharp the HUD is.
//   node hud-shot.cjs <build/web dir> <out dir> [query] [secs] [every]
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const [dir, out, query = '?autoplay=1', secs = '40', every = '500'] = process.argv.slice(2);
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png' };

(async () => {
  fs.mkdirSync(out, { recursive: true });
  const root = path.resolve(dir);
  const server = http.createServer((req, res) => {
    const file = path.join(root, decodeURIComponent(req.url.split('?')[0]));
    if (!file.startsWith(root) || !fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
    fs.createReadStream(file).pipe(res);
  });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
  });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
  page.on('console', (m) => { if (m.text().startsWith('AstroLex')) console.log(m.text()); });
  await page.goto(`http://127.0.0.1:${server.address().port}/index.html${query}`);
  await page.waitForFunction(() => document.querySelector('canvas'), null, { timeout: 60000 });
  const n = Math.round((Number(secs) * 1000) / Number(every));
  for (let i = 0; i < n; i++) {
    await page.waitForTimeout(Number(every));
    await page.screenshot({ path: path.join(out, `f${String(i).padStart(3, '0')}.png`), type: 'png' });
  }
  await browser.close();
  server.close();
})().catch((e) => { console.error(e); process.exit(1); });
