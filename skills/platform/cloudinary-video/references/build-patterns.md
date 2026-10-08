# Build patterns

Wiring that turned out to matter, generalized from a working build. Player
configuration and option traps live in [player.md](player.md); this is how the
pieces fit together into a page.

## Build the player lazily, behind the opening frame

The strongest single improvement to a **long-form** video page: do not open on a
black frame, and do not fetch the real stream until someone wants it.

`cloudinary.player()` has a built-in `lazy` option that defers the full player
behind a static poster. Use it when a still poster is enough; the pattern below
is for when you want a moving opening frame instead. Pre-generate the
`e_preview` eagerly: its first request returns 423 until analysis finishes.

Open with an `e_preview` loop (an AI-chosen summary of the video, muted and
looping, playing as the poster) with a play affordance over it. The first
interaction builds the player and starts playback.

**This whole pattern assumes a long source.** For a short clip (a campaign
film, a product video, anything under about a minute), skip it entirely:
there is no stream worth deferring, and `e_preview` would only produce
something marginally shorter than the asset. Loop the real video muted and
give it a sound/expand affordance instead. Building eagerly is fine there, and
with `cloudinary.player()` resolving saved configuration it is one call.

Note that `cloudinary.player()` is **async**, so even an eager build needs the
queue below: a transcript cue or timecode chip can be clicked before the
promise resolves.

```js
let player = null;
const playerReady = [];

/** Runs `fn` once the player exists, building it on the first call. */
function withPlayer(fn) {
  if (player) return fn(player);
  playerReady.push(fn);
  if (playerReady.length === 1) buildPlayer();
}
```

Why a queue rather than building eagerly: other parts of the page (a chapter rail,
a transcript cue) can be clicked before the player exists, and each of those is
a reason to build it. The queue lets them all express "seek to 26s" without
caring whether the player is there yet.

Autoplay on the loop is only permitted while muted and can still be refused:
`void loop.play().catch(() => {})`, and let the poster stand if it fails.

## Let player options build the URL, not you

Delivery options (`sourceTypes`, `breakpoints`) shape the URL; the player
composes it. A delivery directive written into `transformation:` lands in the
player's own transformation component instead of layering on top of it:

```js
// WRONG: the hand-written profile shares a component with another directive:
// e_vignette:50,sp_auto → 400 "streaming_profile must be the only directive"
player.source(id, { sourceTypes: ['hls'],
  transformation: { streaming_profile: 'auto', effect: 'vignette:50' } });
// RIGHT: let sourceTypes add sp_auto
player.source(id, { sourceTypes: ['hls'] });
```

## Compose `source()` from the feature flags

Spread each capability in conditionally so an absent feature contributes
nothing, rather than contributing an empty value the player then tries to load:

```js
player.source(publicId, {
  ...(features.chapters ? { chapters: true } : {}),
  ...(features.titleAndDescription ? { title: true, description: true } : {}),
  ...(features.captions ? { textTracks: buildTextTracks(features) } : {}),
  ...(features.hotspots ? { interactionAreas: buildAreas(map) } : {}),
});
```

The distinction that bites: an omitted `textTracks` gives a player with no
caption button; a `textTracks` containing an entry whose URL 404s gives a
caption button that does nothing. Skip, do not stub.

Note `posterOptions` and the `e_preview` opening frame are mutually exclusive:
if the loop is the opening frame there is no poster to choose, so requesting an
AI keyframe as well is wasted work.

## Bind playback to the page, both directions

Two-way binding is what makes chapters feel like part of the site rather than
a player feature:

- **Page → player.** A rail item or transcript cue calls
  `player.currentTime(seconds); player.play()` (through `withPlayer`).
- **Player → page.** A `timeupdate` handler finds the current segment and
  highlights it. Track the last value and only act on change: `timeupdate`
  fires several times a second and re-rendering on each is visible jank.

```js
player.on('timeupdate', () => {
  const t = player.currentTime();
  const match = chapters.find((c) => t >= c.start && t < c.end);
  if (match?.id !== lastId) { lastId = match?.id; setActiveSegment(lastId); }
});
```

Render the rail **before** the player exists. Selecting a rail item is one of the
things that builds the player, so a rail that waits for the player is a rail
that can never trigger it.

## The transcript: what the player does, and what it does not

`<publicId>.transcript` is Cloudinary's own JSON (cues carrying `transcript`
text and word-level timings), not a VTT file. **The player supports it
natively**, so do not hand-roll what it already does:

```js
textTracks: {
  captions: { label: 'English', default: true, maxWords: 3, wordHighlight: true },
  options:  { theme: 'yellow-outlined', wordHighlightStyle: { color: 'royalblue' } },
}
```

- Omitting `url` makes the player resolve the `.transcript` for that public ID.
- Setting **`maxWords`** makes it look for `<publicId>.transcript` explicitly;
  this is the documented trigger, not just a display cap.
- **`wordHighlight: true`** uses the word-level timings to highlight each word
  as it is spoken. This is the payoff for the transcript being JSON rather than
  VTT, and it is a player feature: you do not build it.

What the player has **no** native support for is a **searchable transcript
panel**: a list of cues you can filter and click to seek. There is no
`transcript`/`interactiveTranscript` option. If the page wants that, fetch the
`.transcript` and render it yourself, and drive the player with
`player.currentTime(t)`. Each cue is `{ transcript, confidence, words }` with no
cue-level time, so seek to a cue's `words[0].start_time` (or a word's own
`start_time` for word-level accuracy).

So the split is: **captions, word highlighting and translated subtitles are the
player's job; an on-page searchable transcript is yours.**

Translated transcripts live at `<publicId>.<lang>.transcript` and must be
passed explicitly as `subtitles` entries.

Always give it a failure path. The transcript can be pending, failed, or absent
(no audio track), and a permanently "Loading transcript…" panel is worse than
an honest "Transcript unavailable."

## Audio description as a subtitles track

The player has no native descriptions kind, so the visual transcription from
`ai_video_analysis` (describing what is *on screen* rather than what is said)
goes in as another `subtitles` entry, labelled so it is not mistaken for a
translation. Requires an API secret; unavailable over MCP alone.

## Structured data comes free once the metadata exists

`auto_video_details` and `auto_chaptering` give you everything a
`schema.org/VideoObject` wants: `name`, `description`, `duration`, and
`hasPart` clips from the chapter boundaries. Emit it as JSON-LD. Only do this
when the flag is on; fabricating a description for SEO is worse than omitting
the block.

## Let the player do visibility, not an IntersectionObserver

For decorative loops (tiles, background clips, a feature panel), the reflex is
an `IntersectionObserver` that plays on enter and pauses on exit. The player
has this: `autoplayMode: 'on-scroll'`, alongside `muted`, `loop` and
`controls: false`. (Not `autoplay: 'on-scroll'`: that value is treated as plain
`autoplay: true`, so the clip always autoplays.) Save that on each asset and the observer disappears, along
with the lazy `src` assignment people bolt onto it.

That also keeps every clip on the player's own optimizations (`f_auto:video`,
breakpoints) rather than a hand-written URL on a bare `<video>`; a page mixing
both ends up with the players optimized and the loops not.

## Ship the site, not the demo scaffolding

Build generously and present quietly. Those are not in tension: every
capability the cloud supports should be *working* in the page, and none of them
should be *announced* by it.

When the deliverable is "a page for <brand>", it is that brand's site, not an
exhibit about Cloudinary. Capability ledgers, delivery tables listing `sp_auto`
and `f_auto`, transformation footnotes and "what this cloud can do" sections
are scaffolding: they read as a vendor demo and would never survive on a real
storefront. Build what the brand would actually ship (navigation, a hero,
merchandising, working commerce affordances, a real footer) and let the media
pipeline be invisible.

Keep the honesty about missing capabilities, but put it in your *report to the
user*, not on the page. The one exception is content that genuinely serves the
visitor: a transcript is an accessibility feature and can stay, provided it is
presented as a quiet disclosure rather than a showcase of transcription.

Also watch for **copy that duplicates the footage**. Campaign films usually
carry a burned-in end-card; if your headline repeats the line the video already
says, the page reads as a mistake. Read the frames before writing the hero.

## Framework note

Build the `<video>` element imperatively and do **not** dispose the player on
effect cleanup. Colors, adaptive streaming and interaction areas are lazy
plugins that reach for the element after the effect returns; disposing pulls it
out from under them (`Invalid target for null#one`). Route callbacks through
refs so the effect can have an empty dependency list and build exactly one
player for the page's lifetime.
