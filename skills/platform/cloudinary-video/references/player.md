# Cloudinary Video Player configuration

Verified against `cloudinary-video-player@4.1.0`. Option names come from the
player API reference, not from memory.

## Use `cloudinary.player()`, not `cloudinary.videoPlayer()`

The 4.1.0 UMD bundle attaches five things to `window.cloudinary`:
`videoPlayer`, `videoPlayers`, `player`, `players`, `Cloudinary`. Two of those
construct a player and they are **not** the same function:

| | `cloudinary.videoPlayer()` | `cloudinary.player()` |
| --- | --- | --- |
| Status | older constructor | **current**; the bundle tags its own analytics `newPlayerMethod: true` |
| Returns | the player, synchronously in the UMD full bundle (a buffering proxy via ES import) | a **Promise** resolving to the player |
| Saved configuration | none, options only | fetches saved config before constructing |

```js
const player = await cloudinary.player('hero', {
  cloudName: 'my-cloud',
  publicId: 'my/public-id',   // also loads the source
  // …local options win over anything fetched
});
```

Because it is async, anything that touches the player (seeking from a
transcript or a timecode chip) must tolerate being called before it resolves:
queue the request and replay it on resolve.

### Saved configuration: assets and profiles

Video Player Studio saves settings **onto the video asset** by default. Passing
`publicId` makes the player retrieve them automatically (requires player
3.6.0+), so a page can inherit the styling and behaviour someone configured in
the Studio without hard-coding it.

`profile` loads a stored *profile* instead: either a built-in
(`cld-default`, `cld-looping`, `cld-adaptive-stream`, `cld-live-streaming`) or
one saved on the cloud, fetched from
`/_applet_/video_service/video_player_profiles/<name>.json`.

**Profiles are writable over HTTP, with no console needed.** When the same
presentation repeats across many assets, that is the signal to create one
rather than repeat it in page code:

```sh
# create or update; also GET /player/profiles to list, DELETE to remove
curl -X PUT https://api.cloudinary.com/v2/video/<cloud>/player/profiles/<name> \
  -u <key>:<secret> -H "Content-Type: application/json" \
  -d '{"playerOptions":{…},"sourceOptions":{…}}'
```

Basic auth with the API key and secret; both `playerOptions` and
`sourceOptions` are required and take arbitrary player/source keys. Full
reference: [Video Player profiles](https://cloudinary.com/documentation/video_player_profiles_reference.md?install_source=skillspack&referrer=video-skill)

Precedence, and the trap: **specifying a `profile` overrides the asset's own
saved settings.** If you want the per-video configuration to apply, do not pass
a profile. Local options passed at construction beat both.

Profiles deliberately exclude per-embed values: the video's `publicId` and
`posterOptions` are never part of a profile, so keep passing those yourself.

`cld-looping` is worth knowing: `{fluid, controls:false, muted:true,
autoplay:true, loop:true}`, the standard hero/background-loop configuration.

**Precedence:** the docs rank it as instance code, then profile, then
asset-saved settings, then defaults (see
[Configuration precedence](https://cloudinary.com/documentation/video_player_how_to_embed.md?install_source=skillspack&referrer=video-skill#configuration_precedence)).
In practice that is two different mechanisms, and getting this wrong leads to
over-specifying the page defensively:

- **A `profile` replaces the asset's video settings.** It is a substitution:
  pass one and the per-asset saved configuration no longer supplies the base.
  So a profile cannot be combined with per-video settings: if some setting
  genuinely varies per asset, it cannot live behind a profile.
- **Construction options are additive.** They layer *on top* of whichever base
  applies and do **not** suppress it. Settings you do not pass keep coming from
  the asset (or profile), so a page that sets three options still inherits
  everything else that was saved. The merge is shallow: a local `colors` or
  `textTracks` object replaces the saved one wholesale.

Practically: save the presentation, pass only what is genuinely page-specific.
Not because inline options would otherwise clobber the saved config (they
won't), but because anything inline is a value nobody can change without a
deploy.

### What the Studio's own embed looks like

Worth calibrating against, because it is the shape Cloudinary steers users to.
The Studio's Share dialog offers two modes, and neither produces a wall of
options:

| mode | generated code |
| --- | --- |
| **Video settings** (asset-saved) | `cloudinary.player('player', { cloudName, publicId })` |
| **Profile settings** | `cloudinary.player('player', { cloudName, publicId, profile: 'cld-default' })` |

That is the whole call: `fluid` and the rest of the presentation all live in
the asset's video settings, not in the page. The profile picker lists the
cloud's own saved profiles beside the `cld-*` built-ins.

**Configuration belongs on the asset or in a profile, not inline.** This is
the practice, not a judgement call: presentation saved on the asset can be
changed by anyone in Studio, while the same values in page code need a deploy.
Repeat the same presentation across several assets and it should be a profile.

Inline options are not *broken* (they layer on top rather than suppressing
what was saved), but reach for them only for what genuinely cannot live on the
asset, and expect that to be close to nothing. The exception is a build with no
console access and no API secret: nothing can be saved, so inline options are
the only route. `cloudName` and the `publicId`
are the call; everything else has a home.

The Studio also has a raw-JS escape hatch, *Advanced config editing*, for
options not exposed in the Studio UI. Treat hand-written config the same way:
last resort, for what the supported surface does not cover.

### Saving settings without the console: the Video Config API

Video Player Studio saves settings through the console UI, but the same
configuration is readable and writable over HTTP, keyed by **`asset_id`** (not
public ID), with Basic auth:

```sh
# read
curl https://api.cloudinary.com/v2/video/<cloud>/player/config/video/<asset_id> \
  -u <key>:<secret>

# write: PUT REPLACES the whole document; GET, merge, then PUT to patch
curl -X PUT https://api.cloudinary.com/v2/video/<cloud>/player/config/video/<asset_id> \
  -u <key>:<secret> -H "Content-Type: application/json" \
  -d '{"playerOptions":{…},"sourceOptions":{…}}'
```

`playerOptions` takes constructor keys; `sourceOptions` takes `source()` keys
(`sourceTypes`, `transformation`, `posterOptions`, `textTracks`). Get the
`asset_id` from the Admin API: the resource endpoint returns it alongside the
public ID.

The player reads the same config at delivery time from
`/_applet_/video_service/video_player_config/video/<type>/<base64(publicId)>.json`
(observed, undocumented, may change), which is handy for verifying what a page
will actually receive. **An empty
`{"playerOptions":{},"sourceOptions":{}}` and HTTP 200 means nothing is saved**:
the fetch fails silently by design, so a page falls back to its local
options and looks fine while inheriting nothing.

### Confirming saved config actually applied

Two checks that avoid false alarms:

- The player's analytics beacon to `analytics-api-s.cloudinary.com/video_player_source`
  (observed, undocumented, may change) spells it out: `newPlayerMethod=true`, `videoConfig=true`, and
  `fetchedConfig=<comma-separated keys>` listing the `playerOptions` keys that
  came from the saved config (`sourceOptions` keys are not listed).
- **Do not test captions with `videoEl.textTracks`**: it reads empty because
  video.js manages them as *remote* tracks. Use
  `videojs.getPlayer(id).remoteTextTracks()`.

## Constructor and `source()` options

For every option and its shape, see the
[Video Player API reference](https://cloudinary.com/documentation/video_player_api_reference.md?install_source=skillspack&referrer=video-skill).
Options that describe the video (`sourceTypes`, `breakpoints`, `maxDpr`,
`transformation`, `chapters`, `textTracks`, `posterOptions`, and so on) work on
`source()` and also on the constructor, where they become defaults every
`source()` call inherits. Player-only options (`fluid`, `colors`, `controls`,
`showLogo`, `seekThumbnails`, `chaptersButton`, `aiHighlightsGraph`) belong on
the constructor. The traps that cost real builds:

- **`sourceTypes`: omit it for progressive delivery.** Setting `['mp4']`
  replaces the `f_auto:video` default with a pinned extension. Set it only to
  `['hls']` or `['dash']` for adaptive streaming.
- **`breakpoints` is progressive-only.** Under `sourceTypes: ['hls']` the
  streaming profile's ladder governs resolution, and setting `breakpoints` too
  yields a 400, even when both are set as player options. Constructor values
  are inherited, so a player built with `breakpoints: true` needs
  `breakpoints: false` on any ABR `source()` call. See the comparison in
  [capabilities.md](capabilities.md).
- **Don't add `streaming_profile` for `sp_auto`.** `sourceTypes: ['hls']` adds
  it for you. Pass `transformation: { streaming_profile: … }` only to pick a
  named profile, and keep it alone in its component: combined with a resize or
  an effect, delivery returns 400.
- **You do not need to set `maxDpr`.** It is a number from 1.0 to 2.0, default
  2.0, and enabling `breakpoints` already accounts for the device pixel ratio.
  Pass a lower number only to deliberately cap DPR. Never pass `true`: it is
  coerced to 1 and caps DPR at 1x.
- **`colors.text` must be a light colour.** Player chrome sits over dark video,
  so a dark text token makes the controls invisible.
- **`chapters: true` loads `<publicId>-chapters.vtt`**, which is what
  `auto_chaptering` produces.
- **Omitting `url` on `textTracks.captions` makes the player use the
  `.transcript` file** for that public ID. Setting `maxWords` also triggers that
  lookup. The player fetches it from its own service endpoint, not from
  `…/raw/upload/<publicId>.transcript`, so a page that also renders the
  transcript downloads it twice. Translated transcripts live at
  `<publicId>.<lang>.transcript` and must be passed explicitly. Pair
  `wordHighlight: true` with `maxWords` so the caption box does not fill;
  neither works on translated transcripts. `textTracks.options.theme` takes
  `default`, `videojs-default`, `yellow-outlined`, `player-colors`, or `3d`.
- **There is no native searchable-transcript panel.** See
  [build-patterns.md](build-patterns.md).
- **`interactionAreas` coordinates are percentages** of the video frame, not
  pixels. Cloudinary does not supply them (see SKILL.md B5).
- **`preload` defaults to `auto`**, so every non-autoplaying player starts
  downloading video at load. For players below the fold or behind a click, set
  `preload: 'none'` or use `lazy` (`cloudinary.player()` only), which shows a
  lightweight poster until the viewer clicks or scrolls to it. The lazy
  placeholder ignores `posterOptions` and defaults to the untransformed middle
  frame (`<publicId>.jpg`, full resolution), so pass an explicit sized `poster`
  URL such as `…/video/upload/so_auto/c_limit,w_1280/f_auto/q_auto/<publicId>.jpg`.
- **`seekThumbnails` defaults to `true`, even with `controls: false`.** A
  decorative loop (including the `cld-looping` profile) still fetches an
  `fl_sprite` thumbnail track it never shows. Set `seekThumbnails: false` on
  loops.

## React and other frameworks

Build the `<video>` element imperatively, and route callbacks through refs so
the effect can have an empty dependency list and build exactly one player for
the component's lifetime.

Be careful with `dispose()` in effect cleanup. The player finishes initialising
asynchronously: colors, adaptive streaming and interaction areas are
lazy-loaded plugins that reach for the element after the effect returns.
Disposing before they finish (for example, in the extra cleanup React
StrictMode runs in development) pulls the element out from under them, and
they throw on a null node (`Invalid target for null#one`,
`Cannot set properties of null`). Dispose when the component unmounts for good,
such as on a route change, so players don't leak; the cloudinary-react skill
shows that cleanup.

## Transformation notes for video

- **The player applies `f_auto:video` itself.** Write format/quality
  transformations only when you are hand-rolling a native `<video>`; on a
  player source they are redundant, and pairing them with
  `sourceTypes:['mp4']` re-adds by hand what forcing MP4 just removed. See
  [capabilities.md](capabilities.md).
- Prefer `f_auto/q_auto` as **separate components** over `f_auto,q_auto`.
  Both are accepted and, as of September 2026, deliver byte-identical results
  for image and video alike. This is a convention for readability and for
  matching Cloudinary's own docs, **not** a correctness rule. Do not tell a
  user the combined form is broken; it is not.
- `sp_auto` is the streaming profile. It cannot be combined with a resize.
- `e_preview[:duration_<s>][:max_seg_<n>][:min_seg_dur_<s>]`: AI summary reel,
  video only, default duration 5.0s.
- For video, `g_auto` works only with `c_fill` and `c_fill_pad`, once per
  transformation, and not for positioning overlays.
