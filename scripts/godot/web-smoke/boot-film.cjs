// Films the boot from page open to the title: the HTML loader, the hand-off to the Godot intro, the intro's
// own timer and the title. The wasm is held back for HOLD seconds so the loader is on screen first.
//   node boot-film.cjs <web build dir> <out dir> [secs=14] [every=150] [hold=2] [tapAt=0]
// tapAt > 0 taps the screen that many seconds after the overlay leaves (else the intro times out).
// Writes <out>/fNNN.jpg (390x844) and prints when the overlay left and when the title was ready.
const http = require('http'), fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const [dir, out, SECS = '14', EVERY = '150', HOLD = '2', TAP = '0'] = process.argv.slice(2);
const T = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png' };
(async () => {
	fs.mkdirSync(out, { recursive: true });
	const root = path.resolve(dir);
	const srv = http.createServer((q, r) => {
		const f = path.join(root, decodeURIComponent(q.url.split('?')[0]));
		if (!f.startsWith(root) || !fs.existsSync(f)) { r.writeHead(404); r.end(); return; }
		const send = () => { r.writeHead(200, { 'Content-Type': T[path.extname(f)] || 'application/octet-stream' }); fs.createReadStream(f).pipe(r); };
		if (f.endsWith('.wasm')) { setTimeout(send, Number(HOLD) * 1000); } else { send(); }
	});
	await new Promise((r) => srv.listen(0, '127.0.0.1', r));
	const b = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined, args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
	const p = await b.newPage({ viewport: { width: 390, height: 844 } });
	const t0 = Date.now();
	const stamp = () => ((Date.now() - t0) / 1000).toFixed(2);
	p.on('console', (m) => { if (m.text().startsWith('AstroLex')) console.log(stamp(), m.text()); });
	await p.goto(`http://127.0.0.1:${srv.address().port}/index.html`);
	let gone = 0, tapped = false;
	const n = Math.round((Number(SECS) * 1000) / Number(EVERY));
	for (let i = 0; i < n; i++) {
		await p.screenshot({ path: path.join(out, `f${String(i).padStart(3, '0')}.jpg`), type: 'jpeg', quality: 70 });
		if (!gone && !(await p.$('#status'))) { gone = Date.now(); console.log(stamp(), 'overlay gone at frame', i); }
		if (gone && !tapped && Number(TAP) > 0 && Date.now() - gone > Number(TAP) * 1000) {
			tapped = true;
			await p.mouse.click(195, 700);
			console.log(stamp(), 'tap at frame', i);
		}
		await p.waitForTimeout(Number(EVERY));
	}
	await b.close(); srv.close();
})().catch((e) => { console.error(e); process.exit(1); });
