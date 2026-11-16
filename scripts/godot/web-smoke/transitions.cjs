// Films the screen-to-screen transitions of a web build (WP-F.33 evidence): walks a list of steps on a
// phone-sized page, records a video, and saves a still of each named step.
//   node transitions.cjs <build/web dir> <out dir> <steps.json>
// steps: [["url", query] | ["tap", nodeName] | ["tapxy", x, y] (shares of the view) | ["wait", ms]
//         | ["type", text] | ["shot", name] | ["key", key]]
// Taps find their button through the game's ?tour=1 hook (window.__alxFind), so no coordinates are
// hard-coded. The video lands in <out>/video.webm; tools/ffmpeg cut it into frames afterwards.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const [dirArg, outArg, stepsArg] = process.argv.slice(2);
const dir = path.resolve(dirArg || 'build/web');
const out = path.resolve(outArg || 'transitions');
fs.mkdirSync(out, { recursive: true });
const steps = JSON.parse(fs.readFileSync(stepsArg, 'utf8'));
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png' };
const W = Number(process.env.VIEW_W || 390), H = Number(process.env.VIEW_H || 844);

(async () => {
  const server = http.createServer((req, res) => {
    const file = path.join(dir, decodeURIComponent(req.url.split('?')[0]).replace(/^\/$/, '/index.html'));
    if (!file.startsWith(dir) || !fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
    fs.createReadStream(file).pipe(res);
  });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}/index.html`;
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
  });
  const ctx = await browser.newContext({
    viewport: { width: W, height: H }, deviceScaleFactor: 1,
    recordVideo: { dir: out, size: { width: W, height: H } },
    reducedMotion: process.env.REDUCED === '1' ? 'reduce' : 'no-preference',
  });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => {
    const t = m.text();
    if (/SCRIPT ERROR|USER ERROR/.test(t)) errors.push(t);
    if (t.startsWith('AstroLex')) console.log(t);
  });
  const t0 = Date.now();
  const marks = [];
  for (const s of steps) {
    if (s[0] === 'url') {
      await page.goto(base + s[1]);
      await page.waitForEvent('console', { predicate: (m) => /AstroLex ready/.test(m.text()), timeout: 180000 });
      await page.waitForTimeout(1500);
    } else if (s[0] === 'tap' || s[0] === 'tapxy') {
      let at = null;
      if (s[0] === 'tap') {
        for (let i = 0; i < 40 && !at; i++) {
          at = await page.evaluate((n) => { window.__alxFound = null; window.__alxFind && window.__alxFind(n); return window.__alxFound; }, s[1]);
          if (!at) await page.waitForTimeout(150);
        }
        if (!at) { errors.push('not found: ' + s[1]); continue; }
      } else at = [s[1], s[2]];
      marks.push({ step: 'tap ' + (s[0] === 'tap' ? s[1] : at.join(',')), t: (Date.now() - t0) / 1000 });
      await page.mouse.click(at[0] * W, at[1] * H);
    } else if (s[0] === 'wait') await page.waitForTimeout(s[1]);
    else if (s[0] === 'type') await page.keyboard.type(s[1], { delay: 60 });
    else if (s[0] === 'key') await page.keyboard.press(s[1]);
    else if (s[0] === 'shot') { await page.screenshot({ path: path.join(out, s[1] + '.png') }); marks.push({ step: 'shot ' + s[1], t: (Date.now() - t0) / 1000 }); }
  }
  const video = page.video();
  await ctx.close();
  if (video) fs.renameSync(await video.path(), path.join(out, 'video.webm'));
  fs.writeFileSync(path.join(out, 'marks.json'), JSON.stringify(marks, null, 1));
  await browser.close();
  server.close();
  if (errors.length) { console.error('errors:\n' + errors.slice(0, 20).join('\n')); process.exitCode = 1; }
})();
