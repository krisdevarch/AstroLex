// Clicks through the menus of a web build and screenshots each screen (polish evidence).
//   node tour.cjs <build/web dir> <out dir> [steps.json]
// steps: [["shot", name] | ["tap", x, y] (game pixels, 1080x1920) | ["wait", ms] | ["url", query]]
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const [dirArg, outArg, stepsArg] = process.argv.slice(2);
const dir = path.resolve(dirArg || 'build/web');
const out = path.resolve(outArg || 'tour');
fs.mkdirSync(out, { recursive: true });
const steps = JSON.parse(fs.readFileSync(stepsArg, 'utf8'));
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png' };
const server = http.createServer((req, res) => {
  const file = path.join(dir, decodeURIComponent(req.url.split('?')[0]).replace(/^\/$/, '/index.html'));
  if (!file.startsWith(dir) || !fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});
const W = 432, H = 768, S = W / 1080;
(async () => {
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}/index.html`;
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2 });
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => { if (m.type() === 'error' || /SCRIPT ERROR|ERROR:/.test(m.text())) errors.push(m.text()); });
  let first = true;
  for (const s of steps) {
    if (s[0] === 'url') {
      await page.goto(base + (s[1] || ''));
      await page.waitForEvent('console', { predicate: (m) => /AstroLex ready/.test(m.text()), timeout: 120000 });
      await page.waitForTimeout(1500);
      first = false;
    } else if (s[0] === 'tap') { await page.mouse.click(s[1] * S, s[2] * S); await page.waitForTimeout(700); }
    else if (s[0] === 'drag') { await page.mouse.move(s[1] * S, s[2] * S); await page.mouse.down(); await page.mouse.move(s[3] * S, s[4] * S, { steps: 12 }); await page.mouse.up(); await page.waitForTimeout(500); }
    else if (s[0] === 'wait') await page.waitForTimeout(s[1]);
    else if (s[0] === 'shot') { await page.screenshot({ path: path.join(out, s[1] + '.png') }); console.log('shot', s[1]); }
  }
  await browser.close();
  server.close();
  if (errors.length) { console.error('errors:\n' + errors.slice(0, 20).join('\n')); }
})();
