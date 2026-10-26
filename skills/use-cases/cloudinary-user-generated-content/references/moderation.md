# Moderation Reference

Canonical page: [Moderate assets](https://cloudinary.com/documentation/moderate_assets.md?install_source=skillspack&referrer=ugc-skill). Verify parameter names there before generating code — don't guess.

## Moderation types

Set via the `moderation` upload parameter (string):

| Value | Asset type | Add-on required |
|---|---|---|
| `manual` | image, video | No |
| `aws_rek` | image | Amazon Rekognition AI Moderation |
| `aws_rek_video` | video | Amazon Rekognition Video Moderation |
| `google_video_moderation` | video | Google AI Video Moderation |
| `webpurify` | image | WebPurify Image Moderation |
| `duplicate:<threshold>` | image | Duplicate Image Detection (e.g. `duplicate:0`) |
| `perception_point` | any | Perception Point Malware Detection |

## Combining moderation types

Pipe-separate: `moderation=aws_rek|duplicate:0`. Moderations run in list order. If `manual` is included, it must be last — automatic checks run first and only reach manual review if they don't already reject the asset.

Apply moderation to an asset that's already uploaded with the `explicit` Admin API method and the same `moderation` parameter.

## Statuses

Single moderation:

- `pending` — in progress, no outcome yet.
- `approved` — passed.
- `rejected` — failed.

Multi-moderation chains add:

- `queued` — waiting on an earlier moderation in the chain.
- `aborted` — skipped because an earlier moderation already rejected the asset.

## Overriding a status via the Admin API

Use `update` with `moderation_status`:

```javascript
cloudinary.v2.api
  .update('hwepb67oxzh4lrigssld', { moderation_status: 'rejected' })
  .then(result => console.log(result));
```

CLI equivalent: `cld admin update "hwepb67oxzh4lrigssld" moderation_status="rejected"`.

A manual override marks the asset as manually moderated regardless of how it was originally flagged — useful for a human reviewer correcting an automatic call.

## Listing pending assets

Build the manual-review queue from the Admin API's resources-by-moderation listing (query by moderation kind and status), not from your own app's cached status field — the two can drift if a webhook is missed or a client request fails partway. Confirm the exact endpoint/method name for the SDK version in use against the [Admin API reference](https://cloudinary.com/documentation/admin_api.md?install_source=skillspack&referrer=ugc-skill) before generating a call.

## Notifications

For any moderation that runs asynchronously (every automatic type, and manual review that isn't instant), set `notification_url` on the upload so Cloudinary posts the result to your app server instead of making you poll. On receipt:

1. Verify the webhook's signature before trusting the payload — treat an unverified webhook body as untrusted input.
2. Read `moderation_status` from the payload and update your app's record.
3. Drive the delivery-access decision (see [access-control.md](access-control.md)) off this verified status, not off anything the original uploading client sent.

Exact payload shape and signature verification: [Notification messages](https://cloudinary.com/documentation/notification_messages.md?install_source=skillspack&referrer=ugc-skill).
