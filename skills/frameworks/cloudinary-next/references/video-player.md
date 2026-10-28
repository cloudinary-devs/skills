# Video player

Use this for `CldVideoPlayer` setup, required CSS, events, refs, and known limitations.


## CldVideoPlayer — the player

Wraps the Cloudinary Video Player: v4.1.2 in next-cloudinary v7, v1.11.1 in v6. **Required**: `width`, `height`, `src`. **Always** import the CSS once on the page (or in a layout).

```tsx
'use client';

import { CldVideoPlayer } from 'next-cloudinary';
import 'next-cloudinary/dist/cld-video-player.css';

<CldVideoPlayer
  width="1920"
  height="1080"
  src="samples/elephants"
/>;
```

- ✅ **`"use client"`**: required when you pass event handlers or refs. In v7, a player without them can also render from a Server Component. In v6, always required.
- ✅ CSS: `next-cloudinary/dist/cld-video-player.css` works in v6 and v7. v7 also accepts `next-cloudinary/cld-video-player.css`.
- ✅ Use `colors`, `fontFace`, `logo`, `poster`, `textTracks` for customization (see CldVideoPlayer configuration page).
- ✅ For event hooks: `onDataLoad`, `onMetadataLoad`, `onPlay`, `onPause`, `onEnded`, `onError` — each receives `{ player, video }`. The player exposes `player.duration()`, `player.currentTime()`, etc.
- ✅ For programmatic control, pass `playerRef` (Cloudinary player) or `videoRef` (HTML video element) refs, typed like this:

```tsx
import { useRef } from 'react';
import type { CloudinaryVideoPlayer } from 'next-cloudinary';

const playerRef = useRef<CloudinaryVideoPlayer | null>(null);
const videoRef = useRef<HTMLVideoElement | null>(null);
// <CldVideoPlayer … playerRef={playerRef} videoRef={videoRef} />
```
- ❌ **Don't** import the `cloudinary-video-player` package directly in a Next.js app — `next-cloudinary` wraps it.
- ❌ **Don't** pass event handlers or refs to `<CldVideoPlayer>` from a Server Component. Put that code in a file with `"use client"`.

## v7 notes (Video Player v4)

- **Studio posters**: a custom poster saved for a video in the Video Player Studio is shown automatically. Other saved Studio settings (colours, controls, etc.) are not applied; set them with props instead.
- **Custom CSS**: v7 moved the player from v1.11.1 to v4.1.2. If the project styles the player with its own CSS, check that it still applies.
- **Known limitation (7.0): `aspectRatio`**: setting `aspectRatio` makes the poster image fail to load; the video itself plays normally. A fix is planned for a follow-up release. Workaround: also set a crop mode, e.g. `cropMode="fill"`. This also crops the video to that ratio, and `cropMode` isn't in the TypeScript types yet, so it needs a cast. Don't add `aspectRatio` to a player unless the user asks for it.
