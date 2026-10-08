# Field guide: delivery best practices

This is the guidance to apply when advising on, reviewing or building a
customer's video implementation. It is about *delivering video well*, not
about the player's API surface (see [player.md](player.md)).

## Understand the use case before recommending anything

Recommendations follow from the use case, so establish it first:

- **What types of video?** In e-commerce, typically short product videos on
  PDPs, plus campaign/content videos on homepages and landing pages.
- **How long are they?** Under a minute, or longer? This drives the delivery
  method more than anything else.
- **Where are they delivered?** Web (desktop/mobile), native mobile apps, or
  other channels. Native apps change the rules; see below.
- **Do they need analytics?** Views, engagement, watch time.
- **Do they release videos into traffic spikes?** Catalogue launches, major
  campaigns. This is what makes eager transformations worth it.
- **Do they need subtitles/captions?** Already authored, or generated and
  translated?
- **Any other accessibility or navigation needs?** Audio descriptions, chapters.
- **Is anything done to the video before upload?** Cropping, logo overlays, or
  burned-in subtitles done in an editor can usually be replaced with
  transformations, upload presets, or player text tracks.

## Delivery cheat sheet

| Scenario | Approach | Notes |
| --- | --- | --- |
| Short (under about a minute), inline, autoplay, PDP, campaign or social-style web video | **Cloudinary Video Player, progressive** | Optimizes by default (the URL it builds carries `f_auto:video`; quality comes from Default video quality). Write no format/quality transformation, and do not set `sourceTypes`. Enable responsive breakpoints for per-screen dimensions |
| Short web video, player unavailable | **Native `<video>` with multiple `<source>`** | `c_limit,w_[width]` + `f_auto:video` + `q_auto` |
| Longer-form / viewer-selected video (about a minute or more; never under 30 seconds) | **ABR, preferably via the player** | Set `hls` in `sourceTypes` (HLS has the broadest support, and plays natively on Apple devices; `dash` also works); the player adds `sp_auto` for you |
| ABR, player unavailable | **HLS via a compatible third-party player** | Generate the manifest with `sp_auto`; verify browser/device support |
| Major launch, big catalogue drop, high-traffic event | **Eager transformations, on top of the chosen approach** | Pre-generate derivatives at upload; do not let first requests build them |
| Native iOS/Android app | **Mobile-specific strategy** | App picks codec/format and dimensions; URL params or `Accept` header |
| Analytics, captions, accessibility, chapters, branded UI needed | **Use the Cloudinary Video Player** | All of it works out of the box. Other HTML5 players can report the same analytics with the `cloudinary-video-analytics` library |

## Typical issues to avoid

- **Delivering the original**, untransformed. Default video quality only kicks
  in when *some* transformation is present in the URL; a bare original URL
  gets no optimization at all.
- **No maximum dimensions.** Shipping 4K/8K where 1080p is indistinguishable
  burns bandwidth and units for no visible gain. Cap with `c_limit,w_…` for
  progressive. `sp_auto` already caps at 1080p by default; set
  `sp_auto:maxres_<n>p` only to change that.
- **Partial optimization**: applying some of `f_auto` / `q_auto` / resizing but
  not the rest, and ending up with files larger than necessary.
- **Assuming `f_auto` picks a codec in native mobile apps on its own.** It only
  works there if the app sends an `Accept` header listing the formats the
  device supports. See *Mobile apps are a different problem* below.
- **Preloading everything.** Preloading improves perceived start time but
  consumes units for videos nobody watches. The player preloads metadata by
  default, so make it a deliberate decision: `preload: 'none'` or `lazy` for
  players below the fold or behind a click.

## `f_auto` causes a transformation-usage spike, so say so in advance

Introducing `f_auto`, or adding format/codec combinations, forces new derived
versions to be generated. Expect a visible **spike in transformation usage**,
especially across a large existing library. It settles once the derivatives
exist and get reused. Warn the customer *before* the rollout so the bill does
not surprise them.

## Account-level optimization settings

- **Default automatic format** adds `f_auto` to every delivered video without
  touching delivery URLs. Because that counts as a transformation, Default video
  quality also applies. It is available only on plans that use the *video
  seconds* metric. It is not compatible with strict transformations or with
  eager transformations. `fl_original` bypasses it.
- **Default video quality** lets Cloudinary pick quality and codec (`vc_auto`)
  automatically. Available on all plans, but **only applies when another
  transformation is present in the URL**.

## Eager vs on-the-fly

On-the-fly is the default: derivatives build on first request, with no
preparation and no cost for versions nobody requests. The catch is the first
viewer. An ordinary video transformation streams while it is generated, so the
player shows the wrong duration and cannot seek, and async derivations
(`e_preview`, DASH, 2K/4K `sp_auto`, videos over 30 minutes progressive or
60 minutes ABR) return 423 until built.

Switch to **eager transformations at upload** (or the explicit method
afterwards) when a launch or campaign will drive a traffic surge, when videos
are long or high-resolution (2K/4K), when transformations are slow to build, or
whenever the first viewer's playback matters. Three rules:

- **`f_auto` in an eager transformation generates nothing.** There is no
  browser at upload time, so name each format you need instead, with its
  codec (for example `f_webm,vc_vp9` and `f_mp4,vc_h264`).
- If you can't pre-generate, add `fl_no_stream` to the delivery URL so
  Cloudinary waits for the finished file before responding.
- **Check Optimize by default first.** If it is on, eager derivatives aren't
  the ones delivered, so pre-generating them does nothing for viewers.

## Mobile apps are a different problem

A webview is the web: web rules apply. Native apps use a mobile SDK player (iOS,
Android, Flutter, React Native) or the app's own player. The SDK players send
analytics by default and can play `sp_auto` HLS (on by default in Flutter, off
by default on Android and iOS).

**`f_auto` does not work the same way.** The app must tell Cloudinary what the
device supports. Detect support at runtime rather than hardcoding it, then
either name it in the URL:

- Android: `f_webm,vc_vp9`, or `f_mp4,vc_av1` where supported, with
  `f_mp4,vc_h264` as the fallback
- iOS: `f_mp4,vc_h265`, or `f_mp4,vc_av1` where supported, with
  `f_mp4,vc_h264` as the fallback

…or send an `Accept` header (e.g. `video/webm; codecs="vp9"`,
`video/mp4; codecs="hvc1"`, `video/mp4; codecs="avc1"`). For AV1, use the URL
form.

**Responsive breakpoints are not supported in the mobile SDKs.** Request
explicit widths per device instead (`c_limit,w_640` / `w_1280` / `w_1920`), and
pick the smallest that suits the screen.

## What the player gives you for free

- **Analytics**: collected by default for anything delivered through the
  player; visible in Console under Video → Analytics, and available via API.
- **Accessibility**: WCAG 2.1 AA, keyboard navigation, captions/subtitles
  (existing VTT/SRT or generated transcripts), audio descriptions via text
  tracks or alternative audio tracks on ABR, and chapters (VTT, manual, or
  AI-generated).
- **Customization**: skins, colour schemes, fonts, titles/subtitles display.
- **Video Player Studio**: a visual configurator that emits the player config,
  rather than hand-writing it. Also handles transcripts and chapters.

## Validate before launch

Confirm, on representative videos and real devices:

- Delivery URLs are **not** serving originals, and have size limits.
- The intended optimization approach is actually enabled (check the URL that
  ships, not the one you wrote).
- Autoplay/preload behaviour is deliberate.
- Playback works on target browsers, devices and networks.
- Captions/subtitles and analytics work where required.
- The expected initial transformation/delivery usage has been explained.

Then review 2–4 weeks after launch: confirm delivery, check usage and
transformation patterns, and look for optimization opportunities.
