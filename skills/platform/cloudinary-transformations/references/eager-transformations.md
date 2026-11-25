# Pre-Generated (Eager) Transformations

Read this before writing any code that pre-generates transformations with `eager`.

Pre-generate with `eager` on upload, or with the `explicit` method on existing assets, when a transformation is too slow or expensive to process on the first request. Ask whether the user wants it.

## When it's needed

- **Videos, especially long or large ones.** On-the-fly transformations of progressive videos (such as MP4) with an output over 30 minutes, and ABR (`sp_auto`) with an output over 60 minutes, are processed in the background and return a 423 until done. The limits apply to the duration of the transformed output, not the original (see [on-the-fly video limits](https://cloudinary.com/documentation/video_manipulation_and_delivery.md?install_source=skillspack&referrer=trans-skill)). Even shorter videos stream on the first request with the wrong duration and no seeking until the derived video is generated, so eager is recommended for any video that will be shared or downloaded.
- **AI effects** (background removal, generative AI) and other transformations that can't be processed on the fly.

## How to do it

- Pass `eager` (an array of transformations) to the upload call, or to `explicit` for assets already uploaded. Write each transformation in the user's SDK syntax, following [sdk-code.md](sdk-code.md).
- For the `eager` array shape, copy the block for the user's SDK from the code examples in the "Eager transformations for videos" and "Using automatic format in eager transformations" sections of the [eager docs page](https://cloudinary.com/documentation/eager_and_incoming_transformations.md?install_source=skillspack&referrer=trans-skill), instead of writing it from memory. For the `explicit` method, see the [explicit method reference](https://cloudinary.com/documentation/image_upload_api_reference.md?install_source=skillspack&referrer=trans-skill#explicit_method).
- For long videos, AI effects and bulk runs over many assets, add `eager_async: true` so the call doesn't block, and optionally an `eager_notification_url` to be told when processing finishes. Don't let users play or share the video until it's done.
- Each eager transformation counts toward usage, so only generate the ones that will be delivered (see [transformation-costs.md](transformation-costs.md)).

## Matching the delivery URL

The delivery URL must match the eager transformation exactly: same components, same order, same extension.

### `f_auto`

Don't rely on `f_auto` in an eager transformation. `f_auto` delivers a different format per browser, and each format is a separate derived asset, so an eager with `f_auto` generates only one of them. Generate one eager transformation per format that `f_auto` can deliver, and keep `f_auto` in the delivery URL. The exact set differs for images and videos, so read [Using automatic format in eager transformations](https://cloudinary.com/documentation/eager_and_incoming_transformations.md?install_source=skillspack&referrer=trans-skill#using_automatic_format_in_eager_transformations) first.

- **Images:** set `format` to an empty string when the delivery URL has no extension. If you write each eager transformation as a string instead of an object, end it with a trailing `/` (`c_scale,w_800/f_avif/q_auto/`). Without it the generated URL gets a file extension, such as `.avif`, and won't match an extensionless delivery URL.
- **AVIF:** depending on account configuration, AVIF can be delivered as `f_avif,fl_aavif` rather than `f_avif`. Generate that variant too if the Verify step shows it.
- **A 423 in some browsers only** means a format that `f_auto` selected wasn't generated.

### Video

- **With an extension** (such as `.mp4`): plain `f_auto` selects the codec and returns video. Set each eager transformation's `format` to that extension, with one eager transformation per codec (`f_webm,vc_vp9`, `f_mp4,vc_h265`, `f_mp4,vc_h264`).
- **Without an extension** (the Video Player's default, using `f_auto:video`): set each eager transformation's `format` to an empty string (`""`). Plain `f_auto` with no extension delivers H.264.
- Keep format and codec in the same component (`f_mp4,vc_h264`, not `vc_h264/f_mp4`).

### Adaptive streaming (HLS/DASH)

The docs describe eager only for a manually chosen streaming profile (such as `full_hd`), uploaded with `eager_async`, a `format` of `m3u8` or `mpd`, and `streaming_profile` as its own component. `sp_auto` is processed on first request and isn't documented as eager. If the user needs a long video ready for the first viewer, use a manual profile and follow [Manual streaming profile selection](https://cloudinary.com/documentation/adaptive_bitrate_streaming.md?install_source=skillspack&referrer=trans-skill#manual_streaming_profile_selection) for the exact syntax. Don't invent eager syntax for `sp_auto`.

## AI effects and baselines

For AI effects, generate a [baseline](named-transformations.md#baseline-transformations) once instead of repeating the effect in every variant. When backfilling many assets, run the baseline eager transformation first (`t_<name>`), let it finish, then generate the variants that use `bl_<name>`. If the variants run first or in parallel, each can repeat the AI effect. Try a handful of assets and check the cost before running the full set.

A baseline needs an explicit format. Check that the `f_auto` fallback you get is a format that all your target browsers can display.

## Worked examples

Use these shapes when you can't copy a block from the docs page. Adjust the transformation to match the user's delivery URL exactly.

### Node.js: video delivered as `.mp4` (`c_scale,w_720/f_auto/q_auto`)

```js
import { v2 as cloudinary } from 'cloudinary';

const resize = { width: 720, crop: 'scale' };
const quality = { quality: 'auto' };

// One eager transformation per codec that f_auto can deliver. `format` is the delivery extension.
const eager = [
  { transformation: [resize, { fetch_format: 'webm', video_codec: 'vp9' }, quality], format: 'mp4' },
  { transformation: [resize, { fetch_format: 'mp4', video_codec: 'h265' }, quality], format: 'mp4' },
  { transformation: [resize, { fetch_format: 'mp4', video_codec: 'h264' }, quality], format: 'mp4' },
];

// upload_large (chunked, for big files) takes a callback and doesn't return a promise, so wrap it.
// Plain uploader.upload() returns a promise.
await new Promise((resolve, reject) =>
  cloudinary.uploader.upload_large(
    filePath,
    {
      resource_type: 'video',
      public_id: publicId,
      eager,
      eager_async: true,
      eager_notification_url: 'https://example.com/hooks/cloudinary-eager',
    },
    (error, result) => (error ? reject(error) : resolve(result))
  )
);

// Delivery URL: same components, same order, same extension. f_auto stays here, not in the eager list.
const url = cloudinary.url(publicId, {
  resource_type: 'video',
  format: 'mp4',
  transformation: [resize, { fetch_format: 'auto' }, quality],
});
```

AV1 (`{ video_codec: 'av1' }`) is also a codec `f_auto` can deliver, but it's only available on some plans. Add it if the account has it. For videos that are already uploaded, pass the same `eager` and `eager_async` options to `cloudinary.uploader.explicit(publicId, { type: 'upload', resource_type: 'video', ... })`.

### Python: existing images delivered with no extension (`c_scale,w_800/f_auto/q_auto`)

```python
import cloudinary.uploader
from cloudinary import CloudinaryImage

SCALE = {"width": 800, "crop": "scale"}
QUALITY = {"quality": "auto"}

# One eager transformation per format f_auto can deliver, plus f_auto itself.
# format="" because the delivery URL has no file extension.
eager = [
    {"transformation": [SCALE, {"fetch_format": "avif"}, QUALITY], "format": ""},
    {"transformation": [SCALE, {"fetch_format": "avif", "flags": "aavif"}, QUALITY], "format": ""},  # only if your account delivers AVIF this way
    {"transformation": [SCALE, {"fetch_format": "webp", "flags": "awebp"}, QUALITY], "format": ""},
    {"transformation": [SCALE, {"fetch_format": "auto"}, QUALITY], "format": ""},
]
cloudinary.uploader.explicit(public_id, type="upload", eager=eager, eager_async=True)

# Delivery URL: same components, same order, no extension.
url = CloudinaryImage(public_id).build_url(transformation=[SCALE, {"fetch_format": "auto"}, QUALITY])
```

### Python: AI effect on many assets, with a baseline

```python
import cloudinary.api
import cloudinary.uploader

# 1. Save the AI effect once as a named transformation (a baseline needs an explicit format).
cloudinary.api.create_transformation("bg_removed", "e_background_removal/f_jxl/q_100")

# 2. Phase 1: generate the baseline for every asset, and wait for it to finish.
for public_id in public_ids:
    cloudinary.uploader.explicit(public_id, type="upload", eager=["t_bg_removed"])

# 3. Phase 2: generate the delivery variants on top of the baseline.
BASELINE = {"raw_transformation": "bl_bg_removed"}
eager = [
    {"transformation": [BASELINE, SCALE, {"fetch_format": "avif"}, QUALITY], "format": ""},
    {"transformation": [BASELINE, SCALE, {"fetch_format": "avif", "flags": "aavif"}, QUALITY], "format": ""},
    {"transformation": [BASELINE, SCALE, {"fetch_format": "webp", "flags": "awebp"}, QUALITY], "format": ""},
    {"transformation": [BASELINE, SCALE, {"fetch_format": "auto"}, QUALITY], "format": ""},
]
for public_id in public_ids:
    cloudinary.uploader.explicit(public_id, type="upload", eager=eager, eager_async=True)

# Delivery URL: bl_bg_removed/c_scale,w_800/f_auto/q_auto/<public_id>
```

Try a handful of assets first. The effect costs about 75 tx per image, once. A baseline saved with `f_jxl` delivered JXL as the `f_auto` fallback to a client that doesn't accept it, so check what your fallback returns before going live (see [named-transformations.md](named-transformations.md)).

## Verify

After the eager step finishes, request the delivery URL with a browser-like client and list the asset's derived assets (Admin API `resource`) before and after.

- Use a real `Accept` header, and a `<video>` element for video. Opening a video URL directly in a browser can return an image instead of video.
- For images, test `f_auto` with different `Accept` headers (AVIF, WebP, neither).
- A new derived asset means a miss, and its transformation string shows what to add.
- For video, a derived `f_auto` entry can still appear when the eager versions were used, so compare it with the eager ones instead of treating it as a miss.
