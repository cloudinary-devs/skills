# Gotchas

Each of these cost real debugging time on a real build. They all look like
code bugs and none of them are.

## Upload presets can rewrite your assets on ingest

An account can set a **default upload preset** (Console > Settings > Upload)
that applies to every API upload that doesn't name a preset. If that preset
carries an **incoming transformation**, it permanently rewrites every uploaded
asset: resizing it, watermarking it, or both.

Symptom: uploads report success, but stored dimensions are smaller than the file
you sent, and delivered images carry a watermark.

What does **not** work:

- `upload_preset: ""`: ignored, the preset is still applied
- an explicit `transformation:` parameter: the upload *response* reports your
  dimensions while the *stored* asset keeps the preset's
- `invalidate: true`: this is not a cache problem

What does work: pass an explicit clean preset by name (check what exists on
the account), change the default upload preset, or clear the offending preset's
incoming transformation in Console > Settings > Upload.

Note the watermark also **degrades Cloudinary's own AI**: auto-tagging a
watermarked image returns far fewer tags than the clean original.

## Re-uploading to the same public ID can keep serving the old file

After you overwrite, rename, or delete an asset, delivered versions can stay
cached on the CDN for up to 30 days, so a fresh upload can keep delivering the
old file.

Deliver the versioned URL from the upload response (`/v<version>/`), or upload
with `invalidate: true`. Unsigned uploads never overwrite an existing public ID.
Verify by fetching the versioned `secure_url` and checking the actual
dimensions, not the upload response.

## Add-on quotas are small and easy to burn

Free add-on tiers are small monthly quotas. Check the add-on's page in the
Console before looping over an asset list.

Repeated re-uploads to fix something else will exhaust these. Get the upload
parameters right before running the batch.

## Async AI features can fail or come back empty

`auto_chaptering`, `auto_transcription` and the generated title/description all
return `status: "pending"` and complete later, **or return `status: "failed"`**.

They need an audio track with speech. With no audio track the request fails;
with audio but no speech the result is empty. On a 5-second silent clip:

```json
"auto_chaptering":    { "status": "failed", "data": "Failed to process request" },
"auto_video_details": { "status": "failed", "data": "Failed to process request" }
```

Always poll for `complete` and check the output. Never assume.

## HTTP 423 on first request, for async derivations

Async derivations return **423** on the first request until they are built:
`e_preview`, `g_auto` crops, DASH, `sp_auto` at 2K/4K (`maxres_1440p` or
`maxres_2160p`), and videos longer than 30 minutes (progressive) or 60 minutes
(ABR). A default `sp_auto` HLS manifest returns 200. `e_preview` on a 3-minute video took
minutes, and on a very short source (a 13-second clip) it returned 500 instead.
Poll until 200.

For anything going into a launch or a traffic spike, the real fix is **eager
transformations at upload** rather than warming by polling; see
[field-guide.md](field-guide.md).

### A 200 is not proof the derivative is complete

The first request for an ordinary video transformation returns **200** and
streams the video while Cloudinary is still generating it. The player shows the
wrong duration and cannot seek. Observed on a 14.1-second source: the page
reported `duration: 2.625`, buffering stopped at 2.24s, and playback refused to
start. Nothing in the HTTP status said anything was wrong.

Check the headers, not the status code. A still-generating response has no
`content-length` and `accept-ranges: none`; a finished one has both
`content-length` and `accept-ranges: bytes`:

```sh
curl -sI "$URL" | grep -i 'content-length\|accept-ranges'
```

If you can't generate a video in advance, add `fl_no_stream` to the delivery
URL: Cloudinary then waits until the video is fully generated before
responding.

And **re-warm whenever the delivery URLs change.** Warming `sp_auto` does
nothing for the progressive MP4s you switch to later; each distinct
transformation is its own derivative. With responsive breakpoints the player
may request several widths, and with `f_auto` each delivered format is its own
derivative, so a `curl` may warm a different format than the browser gets.

## Audio-only sources break the video-shaped defaults

An asset with no video track (a podcast, a narration track uploaded as video)
plays fine through the player as progressive `f_auto:video`, but several
defaults request things that need frames, and each returns 400:

- `sp_auto`: "sp_auto is not supported with audio only"
- the auto poster (`so_auto`, `<publicId>.jpg`): "No video stream to convert to image"
- seek thumbnails (`fl_sprite`), on by default

So for audio only: progressive, no `breakpoints` (every width is an identical
file), `seekThumbnails: false`, and an explicit poster, for example a waveform
image (`…/video/upload/fl_waveform,w_1280,h_720/<publicId>.png`). The video.js
option `audioPosterMode: true` keeps that poster visible during playback.
`ffprobe -show_streams` tells you which case you have; check it before choosing.

## Video.js rearranges your DOM, and two bugs follow

The Cloudinary player is video.js underneath, which performs DOM surgery on
init. Two failures come from this and both are silent:

**The original `id` moves to a wrapper div.** After init,
`document.getElementById('hero')` returns a `<div class="video-js">`, not the
`<video>`. Attaching media listeners to it does nothing:

```js
document.getElementById('hero').addEventListener('timeupdate', …) // never fires
player.on('timeupdate', …)                                        // correct
```

**An unclosed `<video>` tag swallows everything after it.** HTML parsing puts
subsequent siblings *inside* the video element, where they never render:

```html
<video id="hero" class="cld-video-player" playsinline>   <!-- no </video> -->
<button class="soundbtn">…</button>   <!-- becomes a child of <video> -->
<div class="overlay">…</div>          <!-- gone: 0×0, never painted -->
```

The tell is an element measuring 0×0 whose `parentElement` is `VIDEO.vjs-tech`.
Always close the tag.

## The Cloudinary player proxies only some videojs methods

`player.currentTime()`, `player.play()`, `player.controls()`, `player.mute()`,
`player.unmute()` and `player.isMuted()` are Cloudinary player methods.
`player.muted()` is **not**: calling it throws
`TypeError: player.muted is not a function`, which aborts the rest of your
click handler and looks like "the button does nothing".

Use `player.mute()` / `player.unmute()`, and reach the underlying video.js
instance, `player.videojs`, for anything else the Cloudinary player doesn't
expose:

```js
player.videojs.playbackRate(1.5);
```

Setting `muted`/`volume` directly on the underlying `<video>` element also
works and is the most robust option.

## Verifying what was actually stored

The upload response can disagree with what is stored and delivered. To check
real delivered dimensions, fetch the versioned `secure_url` from the upload
response:

```sh
curl -s "https://res.cloudinary.com/<cloud>/image/upload/v<version>/<public_id>.jpg" \
| python3 -c "
import sys,struct
d=sys.stdin.buffer.read(); i=2
while i<len(d)-9:
    if d[i]==0xFF and d[i+1] in (0xC0,0xC1,0xC2):
        h,w=struct.unpack('>HH',d[i+5:i+9]); print(f'{w}x{h} {len(d)}B'); break
    i+=1
"
```

For video, `ffprobe` on a downloaded file is the honest check, including
whether an audio stream exists at all, which decides whether transcription and
chaptering can work.

## The MCP has no API secret

The agent never holds the API secret when it works through the Cloudinary MCP
servers, so it can only do what the MCP has a tool for.
Any other endpoint that needs the secret (a v2 route, a beta API) returns:

```
{"error":{"message":"error while authenticating: api_secret not provided"}}
```

`POST /v2/video/<cloud>/ai_video_analysis` is the common case: no MCP tool, so
the visual transcription cannot be produced this way at all.

An agent that provisions its own cloud has no such limit. `npx
@cloudinary/cloud` writes `CLOUDINARY_URL=cloudinary://<key>:<secret>@<cloud>`,
and every endpoint is reachable with it.

Before concluding a feature is unavailable, check whether it is merely
unreachable: the two look identical from inside an MCP session.

## Provisioning fails behind a VPN

`npx @cloudinary/cloud` derives the media-delivery allow-list from the source
IP, and refuses to provision from a private address:

```
Error: delivery_ips must contain at least one public IP address [delivery_ips_not_public]
```

A corporate VPN or secure gateway (Cloudflare WARP and similar) triggers this.
The tool's own guidance says an agent should **report it and let the user
decide** rather than changing network settings. Pausing the VPN for that one
command is the fix.

Related, and easy to misdiagnose: **read `delivery_ips` back from the response
and heed the CLI's mismatch warning.** Behind a VPN or NAT, the API call and
media delivery can leave from different addresses, and you end up with a cloud
whose media nothing on this machine can view.

### A VPN toggling *after* provisioning silently kills a working cloud

Worse than the provisioning failure, because it fails late and quietly. The
cloud is pinned to the IP it was provisioned from, so if the network changes
(a VPN reconnecting, a gateway rotating its egress, moving to another network),
every delivery URL starts returning **401**, on a cloud that worked minutes ago.

The tell is *which* requests fail: uploads and Admin API calls keep succeeding,
because only CDN delivery is IP-restricted. So an agent reports a successful
upload while every image and video 401s.

```sh
# 401 on delivery but uploads fine? compare the current egress with the
# address the cloud was provisioned from
curl -s https://api.ipify.org
```

The 401 body says the OAuth token expired, which is misleading: it is an
allow-list rejection, not an auth problem.

For a demo, keep the VPN off for the **whole session**, not just the
provisioning command.

## The delivery IP restriction blocks Cloudinary's own fetches

On an unclaimed cloud, `POST /upload` with `file=<a delivery URL on that same
cloud>` fails with `401 Unauthorized`. Cloudinary's fetcher is not one of the
allowed delivery IPs. Upload from a local file instead.

Claiming the cloud lifts the restriction entirely.

## Claimable clouds

- Expire **24 hours** after provisioning unless claimed
- Media delivery is restricted to the IPs in `delivery_ips`; **uploads and API
  calls are not restricted**, so a wrong IP looks like a working upload with
  broken media
- The CLI's default (no `--ip`) locks delivery to the calling address, which is
  usually correct, so prefer it over guessing
- Surface the `claim_url` to the user; it is what makes the cloud permanent
