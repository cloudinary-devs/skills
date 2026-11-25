# Preparing product media

Read this when the product's media is not on Cloudinary yet, or is untagged.
For general upload concerns (presets, signed uploads, large files) use
cloudinary-upload; this file covers only the conventions the gallery needs.

Uploading creates assets on the user's account. Show the plan (file count,
public IDs, tags) and wait for approval before running it. If a public ID
already exists, an upload replaces it by default: check before running.
Credentials come from the `CLOUDINARY_URL` environment variable; never ask for
them in chat or put them in files.

## Naming and tagging convention

| Media | Public ID | Tag |
| --- | --- | --- |
| Images | `products/<sku>/<sku>_<nn>` (`_01`, `_02`, …) | `<sku>` |
| Video | `products/<sku>/<sku>_video_<nn>` | `<sku>` (fetched with `mediaType: "video"`) |
| 360 frames | `products/<sku>/<sku>_360_<nn>`, zero-padded | `<sku>-360` |
| 3D model | `products/<sku>/<sku>_model` | `<sku>-3d` if you have several, else use the public ID |

Why this shape:

- The gallery orders assets alphanumerically by public ID, so the zero-padded
  suffix sets the display order, including the order of spin frames.
- A product's images and videos can share a tag because `mediaType` selects
  which of them to fetch. Spin frames are images, so they need their own tag or
  they would also appear as ordinary images.
- Tag-based lists return up to 1000 assets and are not paginated. One tag per
  product keeps lists small.
- The widget shows only assets of delivery type `upload`.

## Upload with the Node SDK

```js
// upload-product.mjs   run: node upload-product.mjs sku-1042 ./media/sku-1042
import { v2 as cloudinary } from "cloudinary"; // reads CLOUDINARY_URL
import { readdir } from "node:fs/promises";
import path from "node:path";

const [sku, dir] = process.argv.slice(2);
if (!sku || !dir) {
  console.error("usage: node upload-product.mjs <sku> <directory>");
  process.exit(1);
}

const files = (await readdir(dir)).sort();
for (const [i, file] of files.entries()) {
  const n = String(i + 1).padStart(2, "0");
  const ext = path.extname(file).toLowerCase();
  const isVideo = [".mp4", ".mov", ".webm"].includes(ext);
  const result = await cloudinary.uploader.upload(path.join(dir, file), {
    public_id: `products/${sku}/${sku}_${isVideo ? "video_" : ""}${n}`,
    resource_type: isVideo ? "video" : "image",
    tags: [sku],
    context: { alt: path.parse(file).name.replaceAll("-", " ") }, // placeholder: write real alt text
  });
  console.log(result.public_id);
}
```

Install the SDK with `npm install cloudinary`. The `context.alt` value feeds the
gallery's alt text (`accessibilityProps`, see pdp-widget.md): replace the
filename-derived placeholder with real descriptions before shipping. For
images named by a catalog, take the names from the catalog instead of the loop
index.

## 360 spin frames

Capture one image per equal rotation step of the product. The number of frames
is a quality choice; the widget accepts whatever the tag holds. Upload them as
images with the same tag and zero-padded public IDs:

```js
for (let i = 1; i <= 36; i++) {
  const n = String(i).padStart(2, "0");
  await cloudinary.uploader.upload(`./spin/frame-${n}.jpg`, {
    public_id: `products/sku-1042/sku-1042_360_${n}`,
    tags: ["sku-1042-360"],
  });
}
```

Check the order before shipping:

```bash
curl -s "https://res.cloudinary.com/your-cloud-name/image/list/sku-1042-360.json" \
  | python3 -c "import sys,json; print(*sorted(r['public_id'] for r in json.load(sys.stdin)['resources']), sep='\n')"
```

Expected: the frames in the order they should rotate. If frame 10 sits between 1
and 2, the names are not padded. Frames should all have the same dimensions and
the product centred, or the spin wobbles. A spin set made from a panoramic
image is covered in this
[blog post](https://cloudinary.com/blog/how-to-turn-360-panoramic-images-into-360-spin-sets).

## 3D models

The widget supports **GLB** only. Other formats are converted on upload, and
the conversion can fail, so convert to GLB before uploading. For a model made
of several files (textures), ZIP the folder. Upload as an **image** resource
type, not raw, or the widget cannot use it:

```js
await cloudinary.uploader.upload("./models/sku-1042.glb", {
  public_id: "products/sku-1042/sku-1042_model",
  resource_type: "image",
});
```

Then reference it with `{ publicId: "products/sku-1042/sku-1042_model", mediaType: "3d" }`.
Model delivery and conversion options are in the
[3D transformations guide](https://cloudinary.com/documentation/transformations_on_3d_models.md?install_source=skillspack&referrer=gallery-skill).

## Existing assets with no tags

Tag them in place rather than re-uploading (a re-upload replaces assets and
uses quota). With the Upload API, `cloudinary.uploader.add_tag("sku-1042", [publicIds])`
adds a tag to assets by public ID. Show the list of public IDs and the tag
first and wait for approval, since this changes the account.

## Validate

| Check | Expected | On failure |
| --- | --- | --- |
| `curl -s -o /dev/null -w '%{http_code}' https://res.cloudinary.com/your-cloud-name/image/list/<tag>.json` | `200` | `404`: no asset with that tag and type. `401` with the response header `x-cld-error: Resources of type list are restricted in this account`: the Resource list restriction is on (see SKILL.md prerequisites) |
| Same URL with `/video/list/` | `200` for tags that have videos | Tag set on an image, not the video |
| The returned `public_id`s | In display order | Rename with zero padding |
