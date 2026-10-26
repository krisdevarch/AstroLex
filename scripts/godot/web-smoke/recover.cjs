//   node recover.cjs <build/web dir>
// WP-F.20 checks in headless Chromium, each case in a fresh context:
//  A lose the WebGL context -> page reloads by itself, the previous log keeps 'webglcontextlost'.
//  B same while the page is (emulated) hidden -> no reload until it becomes visible.
//  C requestAnimationFrame stops -> the "stopped responding" notice with the Report button.
//  D a level is remembered (own save, ?savetest=1&setresume=1-04); losing the context reloads the
//    page and the game drops straight back into 1-04 ("AstroLex resumed level=1-04").
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const dir = path.resolve(process.argv[2] || 'build/web');
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png' };
const READY = /AstroLex ready/;
const TIMEOUT_MS = 120000;

const server = http.createServer((req, res) => {
  const file = path.join(dir, decodeURIComponent(req.url.split('?')[0]).replace(/^\/$/, '/index.html'));
  if (!file.startsWith(dir) || !fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});

const LOSE = () => {
  const c = document.getElementById('canvas');
  const gl = c.getContext('webgl2') || c.getContext('webgl');
  const ext = gl && gl.getExtension('WEBGL_lose_context');
  if (!ext) { return false; }
  ext.loseContext();
  return true;
};

async function open(browser, base, query = '') {
  const context = await browser.newContext({ viewport: { width: 432, height: 768 } });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  const ready = () => page.waitForEvent('console', { predicate: (m) => READY.test(m.text()), timeout: TIMEOUT_MS });
  const first = ready();
  await page.goto(base + query);
  await first;
  await page.waitForFunction(() => window.__alxLog.some((x) => x.ev === 'engine started'), null, { timeout: 30000 });
  await page.waitForTimeout(500);
  return { context, page, errors, ready };
}

// Resolves true when the page navigates (reloads) within ms.
function reloadWithin(page, ms) {
  return page.waitForEvent('framenavigated', { timeout: ms }).then(() => true, () => false);
}

const cases = {
  async A(browser, base) {
    const { context, page, errors, ready } = await open(browser, base);
    const nav = reloadWithin(page, 5000);
    const second = ready();
    if (!(await page.evaluate(LOSE))) { throw new Error('no WEBGL_lose_context'); }
    if (!(await nav)) { throw new Error('no reload within 5 s'); }
    await second;
    const prev = await page.evaluate(() => localStorage.getItem('alx_prev_log') || '');
    await context.close();
    if (!prev.includes('webglcontextlost')) { throw new Error('alx_prev_log lacks webglcontextlost'); }
    if (errors.length) { throw new Error('page errors: ' + errors.join('; ')); }
  },
  async B(browser, base) {
    const { context, page, errors, ready } = await open(browser, base);
    const setVis = (v) => page.evaluate((state) => {
      Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => state });
      Object.defineProperty(document, 'hidden', { configurable: true, get: () => state === 'hidden' });
      document.dispatchEvent(new Event('visibilitychange'));
    }, v);
    await setVis('hidden');
    await page.evaluate(LOSE);
    if (await reloadWithin(page, 2000)) { throw new Error('reloaded while hidden'); }
    const nav = reloadWithin(page, 5000);
    const second = ready();
    await setVis('visible');
    if (!(await nav)) { throw new Error('no reload after becoming visible'); }
    await second;
    await context.close();
    if (errors.length) { throw new Error('page errors: ' + errors.join('; ')); }
  },
  async C(browser, base) {
    const { context, page, errors } = await open(browser, base);
    await page.evaluate(() => { window.requestAnimationFrame = () => 0; });
    await page.waitForFunction(() => document.getElementById('lost').classList.contains('on'), null, { timeout: 9000, polling: 200 });
    const info = await page.evaluate(() => {
      const b = document.getElementById('lost-report');
      return { text: document.getElementById('lost-msg').textContent, shown: b.offsetParent !== null };
    });
    await context.close();
    if (!/stopped responding/.test(info.text)) { throw new Error('wrong notice: ' + info.text); }
    if (!info.shown) { throw new Error('Report button not visible'); }
    if (errors.length) { throw new Error('page errors: ' + errors.join('; ')); }
  },
  async D(browser, base) {
    const { context, page, errors, ready } = await open(browser, base, '?savetest=1&setresume=1-04');
    await page.waitForTimeout(1500);  // let Godot flush user:// to IndexedDB
    const back = ready();
    await page.goto(base + '?savetest=1');
    await back;
    await page.waitForTimeout(500);
    const resumed = page.waitForEvent('console', { predicate: (m) => /AstroLex resumed level=1-04/.test(m.text()), timeout: TIMEOUT_MS }).then(() => true, () => false);
    await page.evaluate(LOSE);
    const ok = await resumed;
    await context.close();
    if (!ok) { throw new Error('no "AstroLex resumed level=1-04" after the recovery reload'); }
    if (errors.length) { throw new Error('page errors: ' + errors.join('; ')); }
  },
};

(async () => {
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}/index.html`;
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || (fs.existsSync('/opt/pw-browsers/chromium') ? '/opt/pw-browsers/chromium' : undefined),
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
  });
  let failed = false;
  for (const [name, fn] of Object.entries(cases)) {
    try { await fn(browser, base); console.log(`case ${name}: ok`); } catch (e) { failed = true; console.log(`case ${name}: FAIL ${e.message}`); }
  }
  await browser.close();
  server.close();
  process.exit(failed ? 1 : 0);
})().catch((e) => { console.error('FAIL', e); server.close(); process.exit(1); });
