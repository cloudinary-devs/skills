# Capabilities, detection, and degradation

Every capability below is optional. A build that assumes all of them produces a
page that breaks on the first cloud without an add-on; a build that assumes none
produces a page indistinguishable from the one being replaced.

So: **detect, then flag, then degrade.** The pattern that works is a single
explicit map of what is on, resolved once at build time, with each feature
carrying a fallback rather than a blank space.

```js
const features = {
  adaptiveStreaming: true,
  aiPoster: true,
  previewLoopPoster: true,
  hoverPreviews: true,
  chapters: true,
  seekThumbnails: true,
  hotspots: true,
  machineTags: false,         // needs Google Automatic Video Tagging
  responsivePlayer: true,
  captions: true,
  translatedSubtitles: false, // needs Google Translation
  transcript: true,
  titleAndDescription: true,
};
```

Keeping it in one object rather than scattered `if`s is what makes the
degradation auditable: you can read off what this page will and will not do,
and say so honestly at the end of a run.

## The matrix

| Capability | Needs | Absent → degrade to |
| --- | --- | --- |
| Adaptive streaming (`sp_auto`) | a video track (audio-only sources return 400) | progressive (`breakpoints: true`; none for audio only) |
| Auto poster (`so_auto`) | nothing | first frame, or a chosen still |
| `e_preview` loop opening frame (long sources only) | nothing (warm it) | auto poster, then plain poster |
| Hover previews | chapter→item map | static image on hover |
| Chapters + rail | `auto_chaptering` (or migrated cue points) | no rail; plain scrub bar |
| Seek thumbnails (`fl_sprite`) | nothing | off; the player copes |
| Hotspots → links | **your** coordinates + item map | off; rail does the linking |
| Machine tags / facets | Google Automatic Video Tagging add-on (Google Auto Tagging for images) | existing hand-authored tags |
| Captions | `auto_transcription`, or migrated captions | no caption track |
| Translated subtitles | Google Translation add-on | English captions only |
| Audio description | `ai_video_analysis` (**needs API secret**) | omit the track |
| Searchable transcript | `.transcript` JSON | off |
| Title / description / JSON-LD | `auto_video_details` | hand-authored copy |

Two rows deserve their own note, because they are the ones people assume
Cloudinary supplies and it does not:

- **Hotspot coordinates** are yours. `interactionAreas` takes coordinates you
  pass. AI Video Analysis (Beta) returns timestamped natural-language segments
  (`transcript`, `start_time`, `end_time`) with no spatial coordinates or
  bounding boxes.
- **Chapter→product bindings** are yours. Auto-chaptering finds segment
  boundaries; which product a segment is about is business data. On a migration,
  check the source platform first: cue points and custom fields often already
  carry it.

## Detecting, rather than assuming

How you resolve the flags depends on the destination, and the two cases are
opposites:

**Fresh claimable cloud.** Assume no add-ons. Translated subtitles and machine
tags will be absent every time; that is correct, not a regression. Hardcoding
those two to `false` is the honest default.

**Existing customer cloud.** Do not assume either way: add-ons may well be
subscribed. Probe by attempting the operation on **one** asset and reading the
result, then set the flag. Never probe by looping the catalogue: free tiers are
small monthly quotas, and on a customer cloud the quota is their money.

There is no documented API that lists a cloud's add-ons. Attempting the
operation is the only detection available.

## Access routing: MCP vs `CLOUDINARY_URL`

Working through the Cloudinary MCP servers, the agent never holds the API
secret, so it can only do what the MCP has a tool for. This is not a
permissions problem you can escalate: unsigned requests to any other endpoint
return
`error while authenticating: api_secret not provided`.

| Step | Over MCP | With `CLOUDINARY_URL` |
| --- | --- | --- |
| Upload with `auto_transcription` / `auto_chaptering` | yes | yes |
| Upload with `auto_video_details` | **no parameter** (use an upload preset that sets it) | yes, via the REST upload endpoint or a preset (not the SDKs) |
| Poll asset for async status | yes | yes |
| Asset update / tags / context | yes | yes |
| Delivery URLs, warming derivations | yes (plain HTTP) | yes |
| Add-on categorization / auto-tagging | yes | yes |
| `ai_video_analysis` (visual transcription) | **no tool, so unreachable** | yes |
| Any v2 or beta route | **no** | yes |

Consequence worth stating to the user rather than discovering late: on an
MCP-only build the **audio description track is simply unavailable**, because
`POST /v2/video/<cloud>/ai_video_analysis` needs the API secret, and generated
titles and descriptions need an upload preset that sets `auto_video_details`.
Everything else in the matrix is reachable either way.

Before concluding a feature does not exist, check whether it is merely
unreachable by the route in use. The two are indistinguishable from inside an
MCP session.

## Optimization strategy: `sp_auto` (ABR) vs `breakpoints` (progressive)

Two mechanisms for the same goal (stop sending every viewer the same bytes),
working in opposite ways. Pick one **per source**.

| | `sp_auto` (adaptive bitrate) | `breakpoints` (progressive) |
| --- | --- | --- |
| `sourceTypes` | `['hls']` (or `['dash']`) | **leave unset** (the default). `['mp4']` pins the format and disables `f_auto:video` |
| What it delivers | one manifest listing a rendition ladder | one file at one chosen width |
| Who decides | the **player**, continuously, per segment | the **player**, once, at load |
| Adapts to | bandwidth *and* changes mid-playback | viewport/DPR at startup only |
| Recovers from a stall | yes, drops to a lower rung | no, it is one file |
| Startup cost | manifest + first segments | one request |
| Overhead | segmenting, manifest, more derivations to warm | none beyond the resize |

### Behaviour decides; duration is the proxy

**Check the asset's duration before choosing.** Cloudinary's own field guidance
is duration-based, and it is the opposite of "ABR is the default for anything
important". Behaviour still wins where the two disagree (a long silent loop is
progressive), except that under 30 seconds is always progressive:

| Duration | Approach |
| --- | --- |
| **Under about 1 minute** (and never ABR under 30 seconds) | **Progressive**, the player's default: the player's own `f_auto:video`, plus `breakpoints: true`. Product videos, campaign films, promos, social-style clips, anything inline or autoplaying. |
| **About 1 minute or more**, especially viewer-selected and not autoplaying | **ABR** (`sp_auto` via `sourceTypes:['hls']`). Long-form, where a network can realistically degrade mid-watch. |

`sp_auto` is the only mechanism that responds to bandwidth dropping *while
someone is watching*, but that advantage needs a watch long enough for it to
act. On a 14-second campaign film the ladder never meaningfully switches, and
you have bought manifest round-trips, slower startup, and a pile of renditions
to generate and warm in exchange for nothing. **Progressive is the default for
short web video; reach for ABR when length justifies it.**

`breakpoints` is right for short player-delivered video generally, including
silent decorative loops and background clips, where a manifest is pure
overhead.

**Do not reach for `e_preview` to make a short clip shorter.** `e_preview`
extracts a teaser from a *long* source. Generating a 6-second preview of a
14-second video produces something barely shorter than the asset itself, costs
extra derivations to warm, and is strictly worse than looping the real file.

### The player already applies `f_auto:video`, so do not restate it

Measured against `cloudinary-video-player@4.1.0`, with the same asset:

| Options | URL the player generates |
| --- | --- |
| none | `f_auto:video/v1/<id>` |
| `breakpoints` | `c_limit,w_640/f_auto:video/v1/<id>` |
| `sourceTypes:['mp4']` + `breakpoints` | `c_limit,w_640/<id>.mp4` |
| `sourceTypes:['mp4']` + `breakpoints` + `transformation:{fetch_format:'auto',quality:'auto'}` | `c_limit,f_auto,q_auto,w_640/<id>.mp4` |

The third row is the trap: asking for MP4 **removes** `f_auto:video`, pinning
one format for every viewer. The fourth row is people noticing the loss and
manually re-adding what the default gave them for free. `f_auto` still picks
the format despite the `.mp4` extension, so it works, but it is redundant noise
the player already handles.

**The rule this table is an instance of:** express delivery through player
options and let it build the URL. Anything written into `transformation:` that
an option already covers gets merged into the player's own component. Save
hand-written transformations for media no player delivers: posters, hover
previews, `e_preview` teasers, the native `<video>` fallback.

So for progressive: set `breakpoints`, leave `sourceTypes` alone, and write no
format/quality transformation. The extensionless `f_auto:video` URL is
content-negotiated per request, so different browsers can receive WebM or MP4
from the same URL.

### If the Cloudinary player cannot be used

Deliver progressive with a native `<video>` and several `<source>` elements, so
the browser picks by viewport. That gives the same optimizations without the player:

```html
<video controls autoplay muted playsinline preload="metadata">
  <source media="(max-width: 640px)"
    src=".../video/upload/c_limit,w_640/f_auto:video/q_auto/v1/<id>">
  <source media="(max-width: 1280px)"
    src=".../video/upload/c_limit,w_1280/f_auto:video/q_auto/v1/<id>">
  <source
    src=".../video/upload/c_limit,w_1920/f_auto:video/q_auto/v1/<id>">
</video>
```

Use `f_auto:video` for the format/codec pick (it delivers video with or
without a file extension, matching the cloudinary-transformations skill),
`q_auto` for quality, and `c_limit,w_…` to cap dimensions. Leave out
`type="video/mp4"`: `f_auto:video` may return WebM, and a
wrong type hint can make a browser skip the source. For ABR without the
player, generate the manifest with `sp_auto` and hand the `.m3u8` to a
compatible third-party player.

### `breakpoints` is progressive-only

`breakpoints` exists to pick a delivery **width** for the container on the
progressive path. ABR does not need one: the streaming profile defines the
rendition ladder and the player moves between rungs as bandwidth changes. So
the two are not alternatives to weigh against each other on one source:
`breakpoints` has no meaning once `sourceTypes:['hls']` is set, exactly as
`maxDpr` has none.

Set it anyway and the player **prepends a resize** to the source URL. With
`sp_auto` in the chain that produces:

```
c_limit,w_2560/sp_auto/….m3u8   →   HTTP 400
```

Cloudinary rejects a resize combined with a streaming profile ("sp_auto
transformation is not allowed (resize is only supported for overlay)"), because
the streaming profile *already defines* the rendition ladder, and asking for one
width contradicts the whole mechanism. Verified at every width tried, 640
through 2560: always 400, and the video simply never loads.

So `breakpoints` stays off under `sourceTypes:['hls']`, not as a workaround
but because there is no progressive path here to size. Using player options
rather than hand-written URLs does not avoid it; the player composes the
invalid URL for you.

Don't hand-write the profile for `sp_auto` either: `sourceTypes:['hls']` adds
it for you. Set `transformation:{streaming_profile:…}` only to pick a named
profile, and never alongside `breakpoints` or another directive in the same
component, because a streaming profile must be alone in its component
("streaming_profile must be the only directive in the transformation
component").

Keep the two strategies on separate players. Once a player has delivered a
progressive source with `breakpoints`, it keeps that resize in its own
transformation and adds it to later sources, so a following ABR source still
returns 400, even with `breakpoints: false` on the `source()` call. To switch
one player anyway, call `player.transformation({})` and pass
`{ sourceTypes: ['hls'], breakpoints: false }` before an ABR source (verified
on player 4.1.0).

`maxDpr` (a number, default 2.0) is a child of breakpoints: Video Player Studio
reveals Max DPR only *after* breakpoints is enabled. With ABR neither exists;
the ladder governs resolution.

### The normal shape is both, on different sources

A page usually wants ABR for the main tour and progressive for the loops:

```js
// main player, LONG source: adapts while watching
cloudinary.player(el, { cloudName, publicId: 'tour', sourceTypes: ['hls'] });
```

```html
<!-- preview loop cut from that long source: one small file, no manifest -->
<video src=".../e_preview:duration_10.0/f_auto:video/q_auto/tour" autoplay muted loop playsinline></video>
```

That is the common configuration, not a compromise. What is *not* available is
both mechanisms on the same source.

If the main video is itself short, this shape does not apply: everything is
progressive, and the loop is the real file played through the player (the
`cld-looping` profile, `breakpoints: true`, `seekThumbnails: false`) rather
than an `e_preview` cut of it.

### Naming collision worth flagging

The player option `breakpoints` (a boolean, video) is unrelated to the image URL
parameter `w_auto:breakpoints` (responsive image widths). Same word, different
subsystems: do not let one's documentation answer a question about the other.
