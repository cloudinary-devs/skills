#!/usr/bin/env node
// Serve a locally saved copy of a product page with the Cloudinary Product
// Gallery widget swapped in for the page's own gallery, so a store can see the
// widget in its real layout before changing any production code.
//
//   node preview-pgw.mjs --page ./saved/product.html --selector "#gallery" \
//     --cloud your-cloud-name --version <pinned version> --tag sku-1042 \
//     [--video-tag sku-1042] [--spin-tag sku-1042-360] [--model <public id>] \
//     [--desktop-min-width 960 --columns 2 --spacing 3] \
//     [--public-id <id> ...] [--keep-order] [--secure-distribution images.example-store.com] \
//     [--aspect 3:4] [--crop fill] [--allow https://images.example-store.com] \
//     [--port 4173]
//
//   /            the page with the widget swapped in
//   /?original   the page as saved, with the same network lockdown
//
// Safety: the saved page still carries the store's own scripts (analytics,
// tag managers, session replay). This server sends a Content-Security-Policy
// header on every HTML response that allows only this server, Cloudinary
// delivery, the widget CDN and the hosts passed with --allow, so the copy
// cannot report localhost sessions to the store's production tools. Every
// blocked request is logged to the browser console as "[preview] blocked".
//
// Requires Node 18 or later. No dependencies. Binds to 127.0.0.1 only.

import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import { parseArgs } from "node:util";

function fail(message) {
  console.error(`preview-pgw: ${message}`);
  process.exit(1);
}

const { values: a } = parseArgs({
  options: {
    page: { type: "string" },
    selector: { type: "string" },
    cloud: { type: "string" },
    version: { type: "string" },
    tag: { type: "string" },
    "video-tag": { type: "string" },
    "spin-tag": { type: "string" },
    model: { type: "string" },
    "public-id": { type: "string", multiple: true, default: [] },
    "secure-distribution": { type: "string" },
    "keep-order": { type: "boolean", default: false },
    "desktop-min-width": { type: "string" },
    columns: { type: "string", default: "2" },
    spacing: { type: "string", default: "3" },
    aspect: { type: "string", default: "square" },
    crop: { type: "string", default: "fill" },
    allow: { type: "string", multiple: true, default: [] },
    port: { type: "string", default: "4173" },
  },
});

for (const k of ["page", "selector", "cloud", "version"]) {
  if (!a[k]) fail(`--${k} is required`);
}
if (!a.tag && !a["video-tag"] && !a["spin-tag"] && !a.model && !a["public-id"].length) {
  fail("give at least one of --tag, --public-id, --video-tag, --spin-tag, --model");
}
if (a.version === "latest") {
  fail("pin an exact widget version from the changelog; 'latest' can change under you");
}
if (!/^[A-Za-z0-9_-]+$/.test(a.cloud)) fail("--cloud must be a cloud name, not a URL");
if (!/^\d+\.\d+\.\d+$/.test(a.version)) fail("--version must look like 2.0.3");
if (!/^[a-z]+$/.test(a.crop) || !["fill", "pad"].includes(a.crop)) fail("--crop must be fill or pad");
for (const k of ["desktop-min-width", "columns", "spacing"]) {
  if (a[k] !== undefined && !/^\d+$/.test(a[k])) fail(`--${k} must be a whole number of pixels or columns`);
}
if (a["secure-distribution"] && !/^[a-z0-9.-]+$/i.test(a["secure-distribution"])) {
  fail("--secure-distribution must be a bare hostname like images.example-store.com");
}
for (const host of a.allow) {
  let u;
  try { u = new URL(host); } catch { fail(`--allow needs a full origin like https://images.example.com, got ${host}`); }
  if (u.protocol !== "https:") fail(`--allow only accepts https origins, got ${host}`);
}

const pagePath = path.resolve(a.page);
const root = path.dirname(pagePath);
const pageName = path.basename(pagePath);
let html;
try {
  html = await readFile(pagePath, "utf8");
} catch (e) {
  fail(`cannot read ${pagePath}: ${e.message}`);
}

// Confirm the selector can match something in the saved HTML. Only #id and
// .class selectors are checked statically; anything else is checked in the
// browser, where a miss is reported in the console.
const sel = a.selector;
const idMatch = /^#([\w-]+)$/.exec(sel);
const classMatch = /^\.([\w-]+)$/.exec(sel);
if (idMatch && !new RegExp(`id=["']${idMatch[1]}["']`).test(html)) {
  fail(`no element with id="${idMatch[1]}" in ${pageName}. Open the page's devtools, find the gallery's wrapper, and pass its selector.`);
}
if (classMatch && !new RegExp(`class=["'][^"']*\\b${classMatch[1]}\\b`).test(html)) {
  fail(`no element with class "${classMatch[1]}" in ${pageName}. Open the page's devtools, find the gallery's wrapper, and pass its selector.`);
}

const mediaAssets = [];
for (const id of a["public-id"]) mediaAssets.push({ publicId: id, transformation: { crop: a.crop } });
if (a.tag) mediaAssets.push({ tag: a.tag, transformation: { crop: a.crop } });
if (a["video-tag"]) mediaAssets.push({ tag: a["video-tag"], mediaType: "video" });
if (a["spin-tag"]) mediaAssets.push({ tag: a["spin-tag"], mediaType: "spin" });
if (a.model) mediaAssets.push({ publicId: a.model, mediaType: "3d" });

const cdn = "https://product-gallery-v2.cloudinary.com";
const cloudinaryDelivery = "https://res.cloudinary.com";
const allowed = [cloudinaryDelivery, ...a.allow];
if (a["secure-distribution"]) allowed.push(`https://${a["secure-distribution"]}`);
const csp = [
  "default-src 'self'",
  `script-src 'self' 'unsafe-inline' 'unsafe-eval' ${cdn}`,
  `style-src 'self' 'unsafe-inline' https://fonts.googleapis.com`,
  `font-src 'self' data: https://fonts.gstatic.com`,
  `img-src 'self' data: blob: ${allowed.join(" ")}`,
  `media-src 'self' blob: ${allowed.join(" ")}`,
  `connect-src 'self' ${allowed.join(" ")}`,
  "worker-src 'self' blob:",
  "frame-src 'none'",
  "object-src 'none'",
].join("; ");

// Runs in the browser. JSON.stringify output is safe to embed in a script
// element once "<" is escaped.
const embed = (v) => JSON.stringify(v).replace(/</g, "\\u003c");
const swapScript = `<script>
window.__blocked = [];
document.addEventListener("securitypolicyviolation", (e) => {
  window.__blocked.push(e.blockedURI);
  console.info("[preview] blocked", e.effectiveDirective, e.blockedURI);
});
window.addEventListener("load", () => {
  const host = document.querySelector(${embed(sel)});
  if (!host) { console.error("[preview] selector not found: " + ${embed(sel)}); return; }
  host.replaceChildren();
  const box = document.createElement("div");
  box.id = "pgw-preview";
  host.appendChild(box);
  const s = document.createElement("script");
  s.src = ${embed(`${cdn}/${a.version}/all.js`)};
  s.onload = () => {
    // Layout by viewport width, because the widget's own viewportBreakpoints
    // follow the widget's width, not the page's.
    const minWidth = ${embed(a["desktop-min-width"] ? Number(a["desktop-min-width"]) : null)};
    const desktop = minWidth !== null && matchMedia("(min-width: " + minWidth + "px)").matches;
    const layout = minWidth === null ? {} : desktop
      ? { displayProps: { mode: "expanded", columns: ${embed(Number(a.columns))}, spacing: ${embed(Number(a.spacing))} },
          carouselStyle: "none", zoomProps: { type: "popup", trigger: "click", showTip: "never" } }
      : { displayProps: { mode: "classic" }, carouselStyle: "indicators", carouselLocation: "bottom" };
    window.__pgw = cloudinary.galleryWidget({
      ...layout,
      container: "#pgw-preview",
      cloudName: ${embed(a.cloud)},
      aspectRatio: ${embed(a.aspect)},
      ${a["keep-order"] ? 'sort: "none",' : ""}
      ${a["secure-distribution"] ? `secure: true, privateCdn: true, secureDistribution: ${embed(a["secure-distribution"])},` : ""}
      mediaAssets: ${embed(mediaAssets)},
    });
    window.__pgw.render();
    document.documentElement.setAttribute("data-pgw-preview", "rendered");
  };
  s.onerror = () => console.error("[preview] widget script failed to load");
  document.head.appendChild(s);
});
</script>`;

const types = {
  ".html": "text/html; charset=utf-8", ".css": "text/css", ".js": "text/javascript",
  ".mjs": "text/javascript", ".json": "application/json", ".svg": "image/svg+xml",
  ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp",
  ".avif": "image/avif", ".gif": "image/gif", ".woff": "font/woff", ".woff2": "font/woff2",
  ".ttf": "font/ttf", ".ico": "image/x-icon", ".mp4": "video/mp4", ".webm": "video/webm",
};

createServer(async (req, res) => {
  const url = new URL(req.url, "http://localhost");
  const headers = { "Content-Security-Policy": csp, "Cache-Control": "no-store" };

  if (url.pathname === "/") {
    const body = url.searchParams.has("original")
      ? html
      : html.includes("</body>")
        ? html.replace("</body>", `${swapScript}</body>`)
        : html + swapScript;
    res.writeHead(200, { ...headers, "Content-Type": types[".html"] });
    return res.end(body);
  }

  // Static files from the saved page's folder; refuse anything outside it.
  const file = path.resolve(root, "." + decodeURIComponent(url.pathname));
  if (file !== root && !file.startsWith(root + path.sep)) {
    res.writeHead(403, headers);
    return res.end("forbidden");
  }
  try {
    if (!(await stat(file)).isFile()) throw new Error("not a file");
    const data = await readFile(file);
    res.writeHead(200, { ...headers, "Content-Type": types[path.extname(file).toLowerCase()] ?? "application/octet-stream" });
    res.end(data);
  } catch {
    res.writeHead(404, headers);
    res.end("not found");
  }
}).listen(Number(a.port), "127.0.0.1", () => {
  console.log(`Preview:  http://127.0.0.1:${a.port}/`);
  console.log(`Original: http://127.0.0.1:${a.port}/?original`);
  console.log(`Network allowed: self, ${cdn}, ${allowed.join(", ")}`);
  console.log("Everything else is blocked; blocked requests are logged to the browser console.");
}).on("error", (e) => fail(`cannot listen on port ${a.port}: ${e.message}`));
