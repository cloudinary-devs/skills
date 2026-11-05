# Getting the original sources off a video platform

The governing rule, before any per-platform detail:

> **Never ingest what the website delivers.** A page serves a player embed
> (an `<iframe>`, not a file) backed by transcoded adaptive renditions. Ingest
> that and Cloudinary transcodes a transcode: quality is permanently capped
> below the original, every derived variant inherits the loss, and no
> transformation can recover it. The master exists only in the source
> platform's catalogue or the customer's own storage.

Scraping a `.m3u8` or a progressive rendition off the live page is the failure
this whole file exists to prevent. It *looks* like a successful migration.

## What each platform allows

Verified September 2026. Endpoints change; treat the shape as durable and
re-check the specifics for the account in front of you.

| Platform | Original retrievable? | Route |
| --- | --- | --- |
| Wistia | Yes, cleanest | Data API `medias#show` → `assets[]` → `type: "OriginalFile"` |
| Brightcove | Yes, **not** via the obvious endpoint | Social Syndication API MRSS feed, `fetch_digital_master: true` → `asset.digital_master.url` |
| Vimeo | Yes, plan-gated | Video endpoint with the `video_files` scope; paid tier |
| YouTube | **No** | No API path. Google Takeout, or the customer's masters |

### Wistia

`GET https://api.wistia.com/v1/medias/{hashed_id}.json` returns an `assets`
array. The one you want is `type: "OriginalFile"`: Wistia documents it as the
source media that was uploaded, never used for playback, and used only as the
blueprint for the streaming encodes. Every other asset type
(`Mp4VideoFile`, `HdMp4VideoFile`, `IPhoneVideoFile`, …) is a rendition.

Append `?disposition=attachment` to download rather than stream.

Originals are much larger than the streaming assets. Expect the bandwidth.

### Brightcove: the trap

The intuitive endpoint is wrong:

```
GET https://cms.api.brightcove.com/v1/accounts/{account}/videos/{id}/sources
```

That returns **transcoded renditions**, not the master. It succeeds, it looks
right, and it is exactly the mistake the rule above warns about. (For DRM'd
content the equivalent is `/clear_sources`, still renditions.)

Masters come from a different API entirely. Create an MRSS syndication:

```
POST https://social.api.brightcove.com/v1/accounts/{account}/mrss/syndications
     { "type": "universal", "fetch_digital_master": true }
```

then read `asset.digital_master.url` from the feed. Template changes take up to
10 minutes to appear, and feeds over 100 items need the `offset` parameter.

**The master may legitimately not exist.** Brightcove documents two cases: a
custom ingest profile configured not to store masters, and customers who
deleted masters to save storage cost. Neither is recoverable by retrying; fall
back to asking the customer for their own copy, and if there is none, say so
rather than quietly ingesting a rendition.

### Vimeo

Requires a paid plan (Standard/Pro/Business/Enterprise and up) and a token
carrying the `public`, `private` and `video_files` scopes. Without the plan the
fields are simply absent, not an error you can work around.

Three fields can appear on the video response, and they are not equivalent:

| Field | Expiry | What it is |
| --- | --- | --- |
| `play` | 24h | playback-optimized; for third-party players |
| `files` | none | renditions with dimensions/size metadata |
| `download` | 24h | attachment-headed download links |

**Vimeo's own documentation does not state which field carries the untranscoded
original.** Do not guess: guessing here produces precisely the silent quality
loss this file is about. Inspect the actual candidates for the video in hand
(compare resolution, bitrate and file size against what the customer says they
uploaded, and `ffprobe` the result) before committing to a field, or ask the
customer for their master.

### YouTube: a hard stop

The YouTube Data API **cannot download source files**. There is no scope, no
endpoint, no parameter. An agent cannot resolve this by trying harder.

The only owner path is **Google Takeout**, which returns the files exactly as
uploaded with no transcoding, but builds an account-wide zip rather than
per-video downloads. For a handful of videos that is awkward but workable; it
is a human action either way.

So for YouTube: ask for the customer's masters first, and offer Takeout as the
fallback. Never substitute a scraped rendition.

## Cross-cutting

**URLs expire.** Vimeo `play`/`download` are 24h, Wistia and Brightcove CDN
locations have their own TTLs, Brightcove feed templates lag ~10 minutes. Fetch
and upload promptly; do not collect a list of URLs now to ingest tomorrow.

**Prefer download-then-upload over Cloudinary remote fetch.** Two reasons that
compound: these URLs are authenticated and/or expiring, and (per the
cloudinary-video skill's gotchas) on an unclaimed claimable cloud Cloudinary's own
fetcher is blocked by the delivery IP allow-list, so remote fetch fails there
regardless. Downloading locally first works on every destination.

**Verify what you got.** `ffprobe` the downloaded file before uploading:
resolution, bitrate, and whether an audio stream exists at all. That last one
decides whether transcription and chaptering can work; see the async failure
modes in the cloudinary-video skill's gotchas.

## Sources

- Wistia, Asset URLs: https://docs.wistia.com/docs/asset-urls
- Brightcove, Download Video Masters: https://apis.support.brightcove.com/social-syndication/getting-started/download-video-masters.html
- Brightcove, CMS API download links: https://apis.support.brightcove.com/cms/code-samples/cms-api-sample-download-links.html
- Vimeo, About video file download links from the API: https://help.vimeo.com/hc/en-us/articles/12427806914577-About-video-file-download-links-from-the-API
- Vimeo, Video File response reference: https://developer.vimeo.com/api/reference/response/video-file
- Google Takeout / YouTube original files: https://techcrunch.com/?p=660785
