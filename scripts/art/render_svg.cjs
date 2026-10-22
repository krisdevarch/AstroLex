// Renders SVG files to PNG in headless Chromium, so vector art can be drawn as SVG and shipped as
// a texture. Uses the web-smoke Playwright (scripts/godot/web-smoke) or a global install.
//   node scripts/art/render_svg.cjs in.svg out.png [width height]
// Size defaults to the SVG's width/height attributes. The background stays transparent.
const fs = require("fs");
const path = require("path");

function loadPlaywright() {
  const local = path.join(__dirname, "..", "godot", "web-smoke", "node_modules", "playwright");
  try { return require(local); } catch (_) { return require("playwright"); }
}

async function main() {
  const [src, out, w, h] = process.argv.slice(2);
  if (!src || !out) { console.error("usage: render_svg.cjs in.svg out.png [width height]"); process.exit(2); }
  const svg = fs.readFileSync(src, "utf8");
  const attr = (n) => { const m = svg.match(new RegExp(`<svg[^>]*\\s${n}="([0-9.]+)`)); return m ? Math.round(+m[1]) : 0; };
  const width = +w || attr("width") || 1024, height = +h || attr("height") || 1024;
  const { chromium } = loadPlaywright();
  const exe = process.env.CHROMIUM_PATH;
  const browser = await chromium.launch(exe ? { executablePath: exe } : {});
  const page = await browser.newPage({ viewport: { width, height } });
  const b64 = Buffer.from(svg).toString("base64");
  await page.setContent(`<html><body style="margin:0;background:transparent"><img id="i" width="${width}" height="${height}" src="data:image/svg+xml;base64,${b64}"></body></html>`);
  await page.waitForFunction(() => document.getElementById("i").complete);
  await page.locator("#i").screenshot({ path: out, omitBackground: true });
  await browser.close();
  console.log(`${out} ${width}x${height}`);
}
main().catch((e) => { console.error(e); process.exit(1); });
