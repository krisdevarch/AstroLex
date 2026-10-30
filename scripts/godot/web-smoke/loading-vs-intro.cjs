// WP-F.29 AC 5: the loader and the Godot intro must look like one screen. Serves the web build with the
// wasm held back at HOLD (default 0.4) of its bytes, screenshots the overlay, releases it, waits for the
// Godot intro and screenshots it at the same size.
//   node loading-vs-intro.cjs <web build dir> <out dir> [width=390] [height=844] [hold=0.4] [dpr=3]
// Writes <out>/loading.png and <out>/intro.png.
const http = require('http'), fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const [dir, out, W = '390', H = '844', HOLD = '0.4', DPR = '3'] = process.argv.slice(2);
const T = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png' };
let release;
const released = new Promise((r) => { release = r; });
(async () => {
	fs.mkdirSync(out, { recursive: true });
	const root = path.resolve(dir);
	const srv = http.createServer((q, r) => {
		const f = path.join(root, decodeURIComponent(q.url.split('?')[0]));
		if (!fs.existsSync(f)) { r.writeHead(404); r.end(); return; }
		const buf = fs.readFileSync(f);
		r.writeHead(200, { 'Content-Type': T[path.extname(f)] || 'application/octet-stream', 'Content-Length': buf.length });
		if (!f.endsWith('.wasm')) { r.end(buf); return; }
		const cut = Math.floor(buf.length * Number(HOLD));
		r.write(buf.subarray(0, cut));
		released.then(() => r.end(buf.subarray(cut)));
	});
	await new Promise((r) => srv.listen(0, '127.0.0.1', r));
	const b = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined, args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
	const p = await b.newPage({ viewport: { width: +W, height: +H }, deviceScaleFactor: +DPR });
	await p.goto(`http://127.0.0.1:${srv.address().port}/index.html`);
	await p.waitForTimeout(4000);
	console.log('percent text:', await p.textContent('#status-percent'));
	await p.screenshot({ path: path.join(out, 'loading.png') });
	// A tap on the overlay must do nothing.
	await p.mouse.click(+W / 2, +H - 330 * (+W / 1080) - 75 * (+W / 1080));
	release();
	await p.waitForSelector('#status', { state: 'detached', timeout: 180000 });
	await p.waitForTimeout(1500);
	await p.screenshot({ path: path.join(out, 'intro.png') });
	await b.close(); srv.close();
})().catch((e) => { console.error(e); process.exit(1); });
