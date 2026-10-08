---
name: asset-migration
description: "End-to-end recipe for migrating images, video, and raw files onto Cloudinary from other platforms, storage, and websites. Use when moving assets off Brightcove, Vimeo, YouTube, Wistia, another DAM, cloud storage, or an existing website."
license: MIT
metadata:
  author: cloudinary
  version: '1.0.0'
  internal: true
---

# Migrating assets onto Cloudinary

> **Draft, not ready to publish.** This content was split out of the
> `cloudinary-video` skill (cloudinary-devs/skills#23) so the video skill could
> ship without it. It is video-specific today. The plan is a general migration
> skill: general guidelines plus image-, video-, and raw-file-specific resources,
> with input from Solutions, who handle most enterprise migrations. What is
> still unverified is listed at the end.

## When to Use

- Moving an existing image or video library onto Cloudinary from another
  platform (Brightcove, Vimeo, YouTube, Wistia) or from customer storage
- Rebuilding an existing website's media on Cloudinary
- Building a page for a named real site or brand, using that site's real media

## Quick Start

### Default Best Practices: Apply These to Every Migration

1. **Upload the master, never what the website delivers.** Delivered files are
   transcoded renditions, and uploading one caps quality for every derived
   version. See [Get the originals](#get-the-originals-never-the-delivered-renditions).
2. **Use the named site's real media.** Never substitute Cloudinary's `demo`
   cloud or other stock assets for a real site or brand without asking first.
3. **Keep human-authored metadata.** Captions, chapters, titles, and tags a
   person wrote beat regenerated ones. Carry them over.
4. **Record the old-to-new mapping** (old asset or embed reference to new public
   ID) so rewiring is mechanical and verifiable.
5. **Fall back in order: fetch, then ask them to provide, then ask them to
   map.** Never silently substitute a scraped rendition.
6. **Say what had no Cloudinary equivalent** rather than approximating it.

## Start here

**Is this a migration or a build from scratch?** A migration gives you three
things at once: the media, the conventions to match (layout, naming,
structure), and human-authored metadata worth more than anything regenerated.
From scratch, the builder supplies the sources; do not go looking.

**Are the assets already on a Cloudinary cloud?** If so, there is nothing to
migrate. Do not re-upload them.

**Where are the resources?**

| Source | What it means |
| --- | --- |
| **An existing website** | Try to fetch it for them; otherwise ask them to provide or map it. The site is also your source of guidelines and mapping (see below). |
| **Another video platform** | Get the original from the platform's API or the customer's masters. See [references/source-platforms.md](references/source-platforms.md). |
| **Customer storage** | Ask for access or the files. |

**A named real site is never a cue to reach for Cloudinary's `demo` cloud or
any other stock/sample assets.** If the user names a real site or brand
("build a page for gap.com"), you must actually open that site and pull its
real images/video before writing any page code. Do not silently substitute
placeholder assets because fetching feels slower or the site has no obvious
video element. Only fall back to demo/stock assets if, after actually trying,
the real assets are genuinely unreachable (login-gated, blocked, no usable
media), and even then, say so explicitly and ask the user before
substituting anything. Silently swapping in demo-cloud assets for a named
brand is the single failure mode this rule exists to prevent.

**Where does it land: an existing cloud, or a new claimable one?** On an
existing cloud, respect existing folders, naming, and presets, and be
idempotent: re-runs cost real quota and can overwrite live assets. A fresh
claimable cloud expects no add-ons; provisioning and upload are covered by the
cloudinary-video skill.

## Get the originals, never the delivered renditions

**Find the video in the raw HTML, not in a browser's DOM.** `curl` the page
and grep the source *first*:

```sh
curl -s -A "<a real desktop UA>" "<page url>" -o page.html
grep -oE '[A-Za-z0-9_-]+\.(mp4|m3u8|webm|mov)' page.html | sort -u
```

**Do not conclude "this site has no video" from `document.querySelectorAll`.**
An automated/headless browser's DOM is systematically *less complete* than
what a real user sees, and it fails silently: you get a clean empty array,
not an error:

- On a React/Next.js site the `<video>` element is often created by
  client-side hydration. The asset URL sits in the server-rendered JSON
  payload (`__NEXT_DATA__`, RSC flight data, inline `<script>` state) while
  the raw HTML contains **zero** `<video` tags. If hydration doesn't complete,
  the element never exists to be queried.
- Bot-detection layers (Akamai, Cloudflare, PerimeterX) serve automated
  browsers a degraded page. `document.readyState === "complete"` still
  reports complete; completeness of the *document* is not completeness of
  the *content*.
- A tell-tale sign you are looking at a hydrated-only element: its class is a
  runtime-generated hash (`sitewide-ekvlu4`, `css-1a2b3c`) that appears
  nowhere in the raw HTML.

This is a real, observed failure: on gap.com the served HTML carried six
`.mp4` URLs in its JSON payload and the driven browser reported **zero**
video elements, after waiting for idle, after a shadow-DOM-piercing search,
and at desktop viewport width. The grep above found all six instantly.

Then, to catch what the source grep cannot (assets requested only at
runtime):
- Scroll the whole page and let it idle; some clips lazy-load.
- List **every** network request, not just ones pre-filtered by extension:
  a plain `<img src="...">` can return a `video/mp4` response.
- Check more than one page type: homepage, campaign/collection, and product
  detail each carry different media.

Confirm any URL you find with `curl -sIL <url>` and read the `content-type`
before trusting it. Only if all of that comes back empty may you say the site
has no video, and then ask before falling back to placeholder assets (see
Quick Start rule 2).

**Never ingest what the website delivers.** A page serves a player embed backed
by transcoded adaptive renditions. Ingest that and Cloudinary transcodes a
transcode: quality is permanently capped below the original and every derived
variant inherits the loss. Get the master from the source platform or the
customer's own storage.

This is the rule that decides whether a migration is worth anything. Full
per-platform detail, verified, in
[references/source-platforms.md](references/source-platforms.md):

| Platform | Original retrievable? |
| --- | --- |
| Wistia | Yes, via `medias#show` → `OriginalFile` asset |
| Brightcove | Yes, but **not** via `/videos/{id}/sources` (those are renditions). Needs the Social Syndication master feed, and the master may have been deleted. |
| Vimeo | Yes, but plan-gated and the field carrying the true original is undocumented, so verify, do not guess |
| YouTube | **No API path.** Google Takeout or the customer's masters |

Graduated fallback when you cannot fetch: **fetch → ask them to provide → ask
them to map.** All three are legitimate outcomes. Silently substituting a
scraped rendition is not.

Prefer download-then-upload over Cloudinary remote fetch: source URLs expire and
are authenticated, and on an unclaimed cloud Cloudinary's own fetcher is blocked
by the delivery IP allow-list anyway.

`ffprobe` what you downloaded before uploading: resolution, bitrate, and
whether an audio stream exists at all. That last one decides whether
transcription and chaptering can work.

## Mine the existing site for guidelines and mapping

When migrating from an existing website, the site is an **input to the build**,
not just a media source. Three things to take from it:

- **Structure and conventions**: layout, look, naming, how pages are
  organized. You are improving their page, not replacing it with yours.
- **Human-authored metadata**: captions, chapter lists, titles, descriptions,
  tags. **Prefer these over regenerating.** A caption a human wrote and paid for
  beats `auto_transcription` output. Source platforms often carry cue points and
  custom fields that already hold the chapter→product bindings Cloudinary cannot
  infer.
- **The old→new mapping**: old asset/embed reference to new public ID. This is
  what makes rewiring mechanical and verifiable rather than a hunt.

Say what had no Cloudinary equivalent rather than approximating it.

## Images and raw files (TBD)

Image- and raw-file-specific migration guidance is not written yet: bulk
upload options, preserving folder structure and tags, and moving metadata. Ask Solutions for
the patterns they use on enterprise migrations.

## Related Skills

- **cloudinary-video**: Uploading, preparing, and delivering the migrated video
- **cloudinary-docs**: Looking up anything this skill does not cover

## How much of this is verified

- **Source-platform APIs are documentation research, not tested calls.** The
  routes in [references/source-platforms.md](references/source-platforms.md)
  were read from each vendor's docs (September 2026) without an account to
  exercise them. Treat the *shape* as reliable and confirm the specifics for the
  account in front of you.
- **One item is explicitly unresolved:** which Vimeo response field carries the
  untranscoded original. Vimeo's own docs do not say. Verify before trusting a
  field, or ask for the customer's master.
- **Nothing here has been run end to end against a real existing-customer
  migration.**

## Claim tests removed from the video skill's test suite

These lived in the cloudinary-video claim tests (PR #23). If this skill gets a
test suite, put them in `tests/asset-migration/` (see CONTRIBUTING.md):

```sh
section "Source-platform claims (source-platforms.md)"
file_has "YouTube recorded as having no API path" \
  "$SKILL/references/source-platforms.md" "No API path"
file_has "Brightcove /sources trap is called out" \
  "$SKILL/references/source-platforms.md" "returns \*\*transcoded renditions\*\*"
file_has "Vimeo original field marked unverified" \
  "$SKILL/references/source-platforms.md" "does not state which field"
```
