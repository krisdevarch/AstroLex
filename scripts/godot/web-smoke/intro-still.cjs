// Captures the intro's art alone (?intro=still: sky, wordmark, tagline, four bubbles at rest, no button) at
// 1080x1920 as a JPEG for the web loader (scripts/web/make_loading.py).
//   node intro-still.cjs <web build dir> <out.jpg>
const http = require('http'), fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const [dir, out] = process.argv.slice(2);
const T = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png' };
(async () => {
	const root = path.resolve(dir);
	const srv = http.createServer((q, r) => {
		const f = path.join(root, decodeURIComponent(q.url.split('?')[0]));
		if (!fs.existsSync(f)) { r.writeHead(404); r.end(); return; }
		r.writeHead(200, { 'Content-Type': T[path.extname(f)] || 'application/octet-stream' });
		fs.createReadStream(f).pipe(r);
	});
	await new Promise((r) => srv.listen(0, '127.0.0.1', r));
	const b = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined, args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
	const p = await b.newPage({ viewport: { width: 540, height: 960 }, deviceScaleFactor: 2 });
	await p.goto(`http://127.0.0.1:${srv.address().port}/index.html?intro=still&dpr=2`);
	await p.waitForSelector('#status', { state: 'detached', timeout: 120000 });
	await p.waitForTimeout(3000);
	await p.screenshot({ path: out, type: 'jpeg', quality: 86 });
	await b.close(); srv.close();
	console.log('wrote', out, (fs.statSync(out).size / 1024).toFixed(0) + ' KB');
})().catch((e) => { console.error(e); process.exit(1); });
