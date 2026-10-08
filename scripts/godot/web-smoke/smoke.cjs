// Boots the Godot web export in headless Chromium and checks that the main scene ran.
//   node smoke.cjs <build/web dir> [screenshot.png] [--autoplay]
// With --autoplay it loads index.html?autoplay=1, also waits for "AstroLex round won" (180 s),
// and writes a mid-round screenshot next to the final one (<name>-mid.png).
// Serves the folder itself (wasm needs a real HTTP server and the application/wasm type),
// waits for "AstroLex ready" on the console, fails on page errors or a timeout.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium, webkit, devices } = require('playwright');

const args = process.argv.slice(2);
const AUTOPLAY = args.includes('--autoplay');
// --browser=webkit runs Safari's engine with an iPhone profile; --url=<https://...> tests a deployed build.
const BROWSER = (args.find((a) => a.startsWith('--browser=')) || '--browser=chromium').split('=')[1];
const REMOTE = (args.find((a) => a.startsWith('--url=')) || '').slice('--url='.length);
const pos = args.filter((a) => !a.startsWith('--'));
const dir = path.resolve(pos[0] || 'build/web');
const shot = pos[1];
const WON = /AstroLex round won: score=(\d+)/;
const WON_TIMEOUT_MS = 180000;
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
  const base = REMOTE || `http://127.0.0.1:${server.address().port}/index.html`;
  const url = base + (AUTOPLAY ? (base.includes('?') ? '&' : '?') + 'autoplay=1' : '');
  const browser = BROWSER === 'webkit'
    ? await webkit.launch()
    : await chromium.launch({
      executablePath: process.env.CHROMIUM_PATH || undefined,
      args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
    });
  const page = BROWSER === 'webkit'
    ? await (await browser.newContext({ ...devices['iPhone 13'] })).newPage()
    : await browser.newPage({ viewport: { width: 432, height: 768 } });
  console.log(`browser: ${BROWSER}, url: ${url}`);
  const errors = [];
  const lines = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  // WebKit logs this for Godot's Compatibility renderer on every frame; it is a warning, not a failure.
  const BENIGN = /WebGL: INVALID_OPERATION: glBlitFramebuffer: Read and write color attachments cannot be the same image/;
  let benign = 0;
  page.on('console', (m) => { lines.push(m.text()); if (BENIGN.test(m.text())) { benign++; return; } if (m.type() === 'error') errors.push(m.text()); });

  const t0 = Date.now();
  await page.goto(url);
  const ready = await page.waitForEvent('console', { predicate: (m) => READY.test(m.text()), timeout: TIMEOUT_MS }).catch(() => null);
  const ms = Date.now() - t0;
  let won = null;
  if (AUTOPLAY && ready) {
    if (shot) { await page.waitForTimeout(4000); await page.screenshot({ path: shot.replace(/(\.png)?$/, '-mid.png') }); }
    won = await page.waitForEvent('console', { predicate: (m) => WON.test(m.text()), timeout: WON_TIMEOUT_MS }).catch(() => null);
  }
  if (shot) { await page.waitForTimeout(AUTOPLAY ? 2500 : 1000); await page.screenshot({ path: shot }); }
  await browser.close();
  server.close();

  console.log(lines.filter((l) => /Godot Engine|OpenGL API|Build configuration|AstroLex/.test(l)).join('\n'));
  if (benign) console.log(`note: ${benign} known WebKit WebGL blit warnings ignored`);
  if (!ready || (AUTOPLAY && !won) || errors.length) console.error('--- last console lines ---\n' + lines.slice(-30).join('\n'));
  if (!ready) { console.error(`FAIL: no "AstroLex ready" line within ${TIMEOUT_MS / 1000} s`); process.exit(1); }
  if (AUTOPLAY && !won) { console.error(`FAIL: no "AstroLex round won" line within ${WON_TIMEOUT_MS / 1000} s`); process.exit(1); }
  if (errors.length) { console.error('FAIL: browser errors:\n' + errors.join('\n')); process.exit(1); }
  console.log(`ok: main scene ran in ${(ms / 1000).toFixed(1)} s (${READY.exec(ready.text())[1]} tiles)`);
  if (won) console.log(`ok: autoplay round won, score ${WON.exec(won.text())[1]}`);
})().catch((e) => { console.error('FAIL', e); server.close(); process.exit(1); });
