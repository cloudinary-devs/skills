# Getting assets onto Cloudinary and ready to play

Use this when the media is not yet on a Cloudinary cloud: provisioning a fresh
cloud, uploading with the AI features requested on the way in, waiting for the
async outputs, and warming derived videos before anyone watches.

## Provision a cloud (fresh-cloud destinations only)

```sh
npx @cloudinary/cloud --goal "<what you are building>" --model <your-model-id>
```

No signup, no credentials. Writes `CLOUDINARY_URL` to `./.env` and prints a
**claim URL** a human can open later to keep the account.

- `--ip <address>`: public IP allowed to view delivered media, repeatable, max
  3. **Leave it off when the user views media from the machine you run on**:
  the default locks delivery to the calling address. If you run remotely (CI, a
  cloud agent, a remote dev box), pass the user's public IP instead, because
  delivery is locked to wherever the media will be *viewed*. Getting this wrong is the main
  way an upload appears to succeed while every asset returns 401: uploads are
  never IP-restricted, only CDN delivery.
- `--json`: machine-readable, including `claim_url` and `expires_at`
- `--no-env`: print credentials instead of writing `.env`

**The cloud expires 24 hours after provisioning** unless claimed. Surface the
claim URL at the end; it is what makes the work permanent. Never commit `.env`.

**Provision a new cloud for every test run.** Reusing one skips exactly the work
most likely to break, because it only breaks the first time: assets are already
uploaded, async analysis already reports `complete` rather than `pending`, and
derivations are warm so nothing returns 423. The clouds are free and expire on
their own. Run each one in a fresh directory (or pass `--force`): the CLI exits
without provisioning if `.env` already has a `CLOUDINARY_URL`. Provisioning is
rate-limited per IP.

If provisioning fails with `delivery_ips_not_public`, the connection is behind a
VPN or secure gateway. That is the user's to resolve; see
[gotchas.md](gotchas.md).

## Upload, and trigger analysis on the way in

Ask for the AI features **on the upload call**. Re-running them afterwards costs
a second operation against a quota.

```
upload video:                    # no add-on needed
  auto_transcription: true       # transcript + captions
  auto_chaptering: true          # chapter VTT
  auto_video_details: true       # title, description, tags (counts 1 tx/second)

then, separately, and tolerate failure:
  auto_transcription: { translate: ['es','fr'] }   # needs Google Translation
  categorization: 'google_video_tagging'           # needs that add-on
```

`translate` is the add-on part, not transcription itself. Requesting
`auto_transcription` **with** `translate` on a cloud without Google Translation
fails the **whole** transcription (no transcript, no captions), where plain
`auto_transcription` would have succeeded.

`auto_video_details` is worth requesting here rather than leaving to the player.
The player's `title: true` / `description: true` read the asset's context
metadata and only trigger generation if no value is found, so an
un-pre-generated title is generated for the first time in front of a viewer.

```
upload image:                    # no add-on needed
  (no analysis parameters)

then, separately, and tolerate failure:
  categorization: 'google_tagging'
  auto_tagging: 0.65             # needs Google Auto Tagging
```

Know what image tagging returns before building on it: it describes **what is in
the frame**. A hotel room yields `bed`, `bedding`, `ceiling`, `lamp`: accurate,
and not what a guest filters by. Commercial attributes like "ocean view" are not
visible to an image model. Use it for library search and coverage, not as a
replacement for curated facets.

### Upload rules that have bitten real runs

1. **Upload with only the free features first.** Requesting a subscribed-only
   add-on rejects the whole upload (the asset is never stored), which looks
   like a broken upload rather than a missing entitlement.
2. **Then try add-ons separately**, and treat failure as expected.
3. **Add-ons cannot be enabled by an agent.** It is a console action, which on a
   claimable cloud means claiming it first. There is no documented API for
   checking or enabling add-ons.
4. **A default upload preset can rewrite every asset on ingest**, adding a
   watermark or downsizing, whenever an upload doesn't name a preset. Pass an
   explicit clean `upload_preset`. See [gotchas.md](gotchas.md).
5. **Re-uploading to the same public ID can keep serving the old file** from
   the CDN cache. Deliver the versioned URL from the upload response, or upload
   with `invalidate: true`.

**Say which features are missing and why.** A run that silently drops translated
subtitles has misled the user; one that says "translated subtitles need the
Google Translation add-on, which needs the cloud claimed first" has not.

## Wait for the async features

`auto_transcription`, `auto_chaptering` and title/description return
`status: "pending"` and finish later, **or return `status: "failed"`**. Poll
each until `complete`, or pass a `notification_url` to be told when processing
finishes; never assume success.

```sh
curl -sf -o /dev/null https://res.cloudinary.com/<cloud>/raw/upload/<public_id>.transcript
```

They need **an audio track with speech**. With no audio track the request
fails; with music only or silence the result is empty. Either way there is no
usable transcript, chapters, or generated title, so check the status and the
output.

## Generate the derived videos before anyone watches

The first request for a transformed video is the slow one, in one of two ways:

- **Async derivations return HTTP 423** until they are built: `e_preview`,
  `g_auto` crops, DASH, `sp_auto` at 2K/4K, and videos longer than 30 minutes
  (progressive) or 60 minutes (ABR). `e_preview` can take minutes.
- **Everything else returns 200 and streams while it is generated**, so the
  player shows the wrong duration and cannot seek. A 14-second source played
  as 2.6 seconds and refused to start, with nothing in the status code to say
  so.

For production, generate them in advance with **eager transformations at
upload** (or the explicit method afterwards); see
[field-guide.md](field-guide.md). Eager with `f_auto` generates nothing, so
name each format you need, with both the format and the codec (for example
`f_webm,vc_vp9` and `f_mp4,vc_h264`). If you can't pre-generate, add `fl_no_stream` to the
delivery URL so Cloudinary waits for the finished file.

For a demo or test cloud, warm each URL instead, then confirm it is complete by
its headers, not its status. A finished video has `content-length` and
`accept-ranges: bytes`:

```sh
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0 Safari/537.36'
for i in $(seq 1 60); do      # give up after about 5 minutes
  H=$(curl -sI -A "$UA" "$URL")
  if echo "$H" | grep -q '^HTTP/[0-9.]* 200'; then
    echo "$H" | grep -qi '^accept-ranges: bytes' && break   # fully generated
  elif ! echo "$H" | grep -q '^HTTP/[0-9.]* 423'; then
    echo "$H" | grep -i '^HTTP\|x-cld-error'; break       # a real error
  fi
  sleep 5
done
[ "$i" = 60 ] && echo "gave up: $URL is still generating"
```

`f_auto` picks the format from the request's `User-Agent` and `Accept`
headers, so a bare `curl` warms the MP4 while Chrome is served WebM. Send a
browser's `User-Agent`, and repeat with a Safari one if Safari matters.

Warm the **exact** URLs the player requests, including hover previews and
sprite sheets. Read them from the browser's network panel rather than building
them by hand: the player's choices differ in ways that matter, such as a
`/v1/` segment on some constructions and not others, and a breakpoint width
(640, 848, 1280, 1920, 2560, or 3840) picked from the container size.
**Re-warm whenever the delivery URLs change.** Each distinct transformation is
its own derivative, so warming `sp_auto` does nothing for the progressive MP4s
you switch to later, responsive breakpoints mean warming a set of widths, and
with `f_auto` each delivered format is a separate derivative.
