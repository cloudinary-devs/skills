# Video-Specific Transformations

## Important: Format Parameter for Videos

**Critical:** When using `f_auto` on video URLs, you must specify `f_auto:video` to ensure a video is returned (not an image thumbnail):

```
f_auto:video                   # Returns video in optimal format (NOT an image)
f_auto                         # May return an image ⚠️
```

**Always use `f_auto:video` or a specific video format** (`f_mp4`, `f_webm`, etc.) when transforming videos.

## Video Codec (`vc_`)

```
vc_auto                        # Automatic codec selection (recommended)
vc_h264:high:4.1               # H.264 with profile and level
vc_h265, vc_vp8, vc_vp9, vc_av1  # Other codecs
vc_none                        # Remove video, keep audio only
```

**Key options:** h264 profiles (`baseline`, `main`, `high`), levels (`3.0`-`5.2`)

## Trimming Videos (`so_`, `eo_`, `du_`)

```
so_6.5                         # Start at 6.5 seconds
eo_10                          # End at 10 seconds
du_15                          # Duration of 15 seconds
so_10p, eo_90p, du_30p         # Percentage-based (0p-100p)
```

**Value formats:** Seconds (float) or percentage (`10p`)

## Audio Control (`ac_`)

```
ac_none                        # Remove audio track (for autoplay)
ac_aac, ac_mp3, ac_vorbis, ac_opus  # Audio codecs
```

## Frame Rate (`fps_`)

```
fps_30                         # Set FPS (ensures audio sync)
fps_20-25                      # FPS range
```

## Video Concatenation (`fl_splice`)

**Requires a video base.** `fl_splice` concatenates a clip onto a video timeline; the spliced-in asset can be a video or an [image](https://cloudinary.com/documentation/video_concatenation.md?install_source=skillspack&referrer=trans-skill#concatenate_videos_with_images) (set its duration with `du_<seconds>`). It is ignored on image-only transformations.

**Pattern:**
1. Declare: `fl_splice,l_video:<public_id>`
2. Transform overlay (optional)
3. Apply: `fl_layer_apply` (with `so_0` to splice at beginning)

```
c_fill,h_300,w_450/du_5/fl_splice,l_video:second_clip/c_fill,h_300,w_450/du_5/fl_layer_apply
```

**Important:** Both videos should be resized to matching dimensions before splicing

## Animated WebP from Video

To deliver an animated WebP from a video, use **one** of these valid combinations:

**Path A (simplest):** `f_auto:animated` — sufficient on its own; no extension or fl_ flags required.
```
du_5/f_auto:animated/q_auto                 # First 5 seconds as animated WebP (or GIF where unsupported)
du_5/e_loop/f_auto:animated/q_auto          # Looping animated WebP
```

Note: `f_auto:animated` delivers WebP only when the client sends a WebP Accept header. It falls back to GIF otherwise. 

**Path B:** `fl_animated,fl_awebp` together, **plus** a WebP delivery signal (`f_webp`, `f_auto`, or `.webp` extension):
```
du_5/fl_animated,fl_awebp/f_webp/q_auto    # Animated WebP via fl_ flags + f_webp
du_5/e_loop/fl_animated,fl_awebp/f_auto    # Looping, with f_auto as WebP signal
```

Note: `f_auto` is valid here because `fl_awebp` already constrains output to animated WebP.

**WRONG — these do NOT produce animated WebP:**
- `fl_animated` alone (missing `fl_awebp`)
- `fl_animated,fl_awebp` with no format parameter and no `.webp` extension
- `f_auto` alone with a `.webp` extension (returns a still frame, not animated)

**Additional controls:** `e_loop` makes it loop; `vs_N` controls frame sampling rate; `dl_N` controls frame delay (milliseconds).

## Common Video Patterns

```
du_5/vc_auto/f_auto:video/q_auto                             # 5-second video preview
ac_none/vc_h264/f_mp4/q_auto                                 # Silent video (autoplay)
c_limit,h_720/vc_auto/f_auto:video/q_auto                    # 720p cap with auto format
```
