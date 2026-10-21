---
name: cloudinary-transformations
description: Create and debug Cloudinary transformation URLs and the equivalent SDK code from natural language instructions. Use when building Cloudinary delivery URLs, writing transformation code with a Cloudinary SDK, applying image/video transformations, optimizing media, or debugging transformation syntax errors.
license: MIT
metadata:
  author: cloudinary
  version: '1.1.0'
---

# Cloudinary Transformation Rules

## When to Use

- Building Cloudinary delivery/transformation URLs
- Writing transformation code with a Cloudinary SDK (see the Generating SDK Code section)
- Converting natural language requests to transformation syntax
- Debugging transformation URLs that aren't working
- Optimizing images or videos with Cloudinary
- Applying effects, overlays, resizing, or cropping

## Quick Start

### Default Best Practice: Always Optimize

**Add `f_auto/q_auto` to the end of nearly every transformation URL** (as final components):
- Automatically delivers optimal format
- Optimizes quality for best balance of visual quality and file size
- Reduces bandwidth and improves performance

**Example:** `c_fill,g_auto,w_400,h_300/f_auto/q_auto`

**Exceptions - Don't add optimization when:**
- Account has "Optimize By Default" enabled (already applied automatically)
- Special quality requirements (use `q_auto:best`, `q_auto:low`, or manual `q_N` instead)
- Specific format required (replace `f_auto` with `f_png`, `f_jpg`, etc.)
- Delivering exact original with no modifications

**Examples of common transformations (with optimization):**
1. Resize: `c_scale,w_400/f_auto/q_auto`
2. Smart crop: `c_fill,g_auto,h_300,w_400/f_auto/q_auto`
3. Background removal: `e_background_removal/f_png/q_auto`
4. Text overlay: `co_yellow,l_text:Arial_40:Hello%20World/fl_layer_apply,g_south/f_auto/q_auto`
5. Image overlay: `l_logo/c_scale,w_100/fl_layer_apply,g_north_west,x_10,y_10/f_auto/q_auto`

**Important:** All transformation strings shown throughout this skill are illustrative examples to demonstrate syntax and concepts. When generating transformations, choose specific values (dimensions, colors, positions, etc.) based on the user's actual requirements and use case, not the example values shown.

**For debugging:** See [references/debugging.md](references/debugging.md) for detailed troubleshooting steps.


## Gathering Requirements

Before generating a transformation URL, if not already specified, clarify these details based on the user's request:

### For Resize/Crop Requests
**Required:**
- At least one dimension (width OR height)
- Crop behavior if both dimensions specified (fill, pad, scale, limit, etc.)

**Clarify:**
- Focal point/gravity (especially for cropping): Face detection? Center? Smart auto-detection?
- Maintain aspect ratio? (if only one dimension, this is automatic)

**Example questions:**
- "What dimensions do you need? (width and/or height)"
- "Should this fill the space (may crop) or fit within it (no cropping)?"
- "Any important focal point? (faces, center, specific area)"

### For AI Transformation Requests
- **Background removal:** Output format (PNG for transparency, or JPG with a solid background) and what to do with the transparent area (keep, add color, or `b_gen_fill`)
- **Generative fill:** Target dimensions or aspect ratio, and how much extension is needed
- **Generative replace:** What to replace (from), what to replace it with (to), and whether to preserve the original shape (clothing/objects)
- **Generative remove:** What object(s) to remove, and all instances or just one
- **Generative background replace:** The desired background (or auto-generation), and whether it must be reproducible (consider the seed parameter)

### For Video Transformation Requests
- **Trimming:** Start and end time, or duration (seconds or percentage of the video)
- **Codec/format:** Output format (MP4, WebM, etc.) and quality requirements (use `vc_auto` if unsure)
- **Audio:** Keep or remove the audio track. For autoplay, suggest removing it (`ac_none`)

### Always Recommend
Unless user specifies otherwise:
- **Add `f_auto/q_auto` at the end** of transformation URLs (see Quick Start section for exceptions)
- Use `g_auto` for smart cropping when filling dimensions
- Consider cost for AI transformations (inform user of transformation credits)

## Quick Reference

### URL Structure

```
https://res.cloudinary.com/<cloud_name>/<asset_type>/<delivery_type>/<transformations>/<version>/<public_id>.<ext>
```

**Key Rules:**
- Commas (`,`) separate parameters **within** a component
- Slashes (`/`) separate components **between** transformations
- Each component acts on the output of the previous one

### Parameter Types

**Action parameters**: Perform transformations (one action per component: each action transformation should be separated by a slash)
**Qualifier parameters**: Modify action behavior (in the same component as the action, using commas as separators)

Check the [Transformation Reference](https://cloudinary.com/documentation/transformation_reference.md?install_source=skillspack&referrer=trans-skill) to determine if a parameter is an action or qualifier.

## Generating SDK Code

If the user is working in code, give them SDK code rather than a hand-built URL string. Design and validate the transformation in URL syntax first (the URL is the canonical form), then translate it.

**Before writing any SDK code, read [references/sdk-code.md](references/sdk-code.md).** It explains how to work out the user's SDK and how to get the exact syntax and imports from the Transformation Reference. Each SDK has its own names and syntax for the same transformation, so don't guess SDK syntax from the URL parameters.

## Core Transformations

### Resize & Crop

**Dimension value formats:**
- **Whole numbers** (e.g., `w_400`, `h_300`) = pixels
- **Decimal values** (e.g., `w_0.5`, `h_1.0`) = percentage of original dimensions (0.5 = 50%, 1.0 = 100%)

**Choosing the right crop mode:**

Use **`c_scale`** when:
- Resizing while maintaining original aspect ratio
- Specify only ONE dimension (width OR height)
- No cropping needed
- The user intentionally wants to stretch or squash an image by changing the aspect ratio

Use **`c_fill`** when:
- Must fit exact dimensions (e.g., thumbnail grid, fixed layout)
- Okay to crop parts of image
- Combine with `g_auto` for smart cropping, or `g_face` for portraits

Use **`c_fit`** when:
- Image must fit within dimensions without cropping
- Okay to have empty space
- Maintaining full image content is critical

Use **`c_pad`** when:
- Must fit exact dimensions without cropping
- Need to fill empty space with background color/blur (videos only)/AI-generated pixels
- Use with `b_<color>`, `b_auto`, `b_blurred` (blurred background - videos only), or `b_gen_fill`

Use **`c_limit`** when:
- Set maximum dimensions but don't upscale small images
- Preserving original quality of small images matters

Use **`c_thumb`** when:
- Creating thumbnails (typically avatars)
- Use with `g_face` for face-centered crops

Use **`c_auto`** when:
- Cloudinary should intelligently crop to interesting content
- Combine with `g_auto` for best results
- Good for dynamic content where focal point varies

**Examples:**
```
c_scale,w_400                      # Resize width to 400px, maintain aspect ratio
c_scale,w_0.5                      # Resize to 50% of original width
c_fill,g_auto,h_300,w_400          # Fill 400x300px dimensions, smart crop
c_fit,h_300,w_400                  # Fit within dimensions, no crop
c_pad,b_white,h_300,w_400          # Pad to exact size with white background
c_pad,w_1.0                        # Pad to original width (100%)
c_limit,w_1000                     # Limit max width, no upscale
c_thumb,g_face,h_150,w_150         # Face-centered square thumbnail
c_auto,g_auto,w_800                # Auto crop to interesting area
```

**Important**: Always specify a crop mode explicitly. Avoid using both dimensions with `c_scale` (will distort if aspect ratios don't match) - prefer one dimension to maintain aspect ratio.

### Gravity (Focal Point)

Gravity determines which part of the image to focus on when cropping:

- **`g_auto`** - Smart detection (recommended for varied content; detects faces, objects, contrast)
- **`g_face`** - Face detection (portraits, avatars)
- **`g_center`** - Center position (centered subjects, logos)
- **`g_north`, `g_south_east`, etc.** - Compass positions (fixed locations, overlay positioning)
- **`x_N,y_N`** - Custom offsets (integers = pixels, floats = percentage: 0.8 = 80%)

**Examples:**
```
c_fill,g_auto,w_400,h_300                      # Smart crop
c_thumb,g_face,w_200,h_200                     # Face-centered
l_logo/fl_layer_apply,g_south_east,x_10,y_10  # Logo bottom-right
```

**Important**: 
- `g_auto` only works with `c_fill`, `c_lfill`, `c_crop`, `c_thumb`, `c_auto`
- When using x, y, h, w together, use all integers OR all floats (don't mix)

### Format & Quality

**Recommended defaults:**
- **`f_auto/q_auto`** - Use for most production images (WebP to supported browsers, optimized file size)

**Specific formats** (when requirements dictate):
- **`f_png`** - Transparency needed (e.g., after background removal)
- **`f_jpg`** - Force JPEG (remove transparency)
- **`q_N`** - Manual quality 1-100 (e.g., `q_60` for thumbnails, `q_90` for hero images)
- **`dpr_auto`** - Retina displays (Chromium-only, requires Client Hints - see limitations below)

**Examples:**
```
f_auto/q_auto           # Recommended default
f_png/q_auto            # PNG with transparency
q_80                    # Manual 80% quality
```

**Best Practice**: Use `/` to separate format and quality as distinct components.

#### Responsive Images (`dpr_auto`, `w_auto`)

**`dpr_auto`** - Automatically adapts to device pixel ratio (Retina displays)
- **Chromium-only** (Chrome, Edge, Opera, Samsung Internet)
- Requires Client Hints configuration
- Falls back to `dpr_1.0` on other browsers
- Does NOT work inside named transformations

**Alternative for universal support:** Use explicit `dpr_2.0` or `<img srcset>` with 1x/2x variants

For Client Hints configuration, browser compatibility, responsive breakpoints, and framework integration, see [references/responsive-images.md](references/responsive-images.md)

### Effects

**Common effects:**
- **`e_grayscale`** - Black and white (artistic, accessibility)
- **`e_sepia`** - Vintage/nostalgic feel
- **`e_blur:N`** - Blur (privacy, placeholders; N typically 300-2000)
- **`e_sharpen`** - Enhance clarity (useful after resizing)
- **`e_cartoonify`** - Illustrated style
- **`co_rgb:RRGGBB,e_colorize:N`** - Color tint (N = intensity 0-100, for brand theming)
- **`e_background_removal`** - See AI Transformations section

**Examples:**
```
e_blur:800                       # Blur effect
e_sharpen                        # Enhance clarity
co_rgb:0044ff,e_colorize:40      # Blue tint at 40%
```

**Note**: Color (`co_`) is a qualifier - use in same component as `e_colorize`.

### Overlays & Underlays

**Use for:**
- **`l_<public_id>`** - Image overlays (logos, watermarks, badges)
- **`u_<public_id>`** - Image underlays (custom backgrounds behind transparent subjects)
- **`l_text:font_size:text`** - Text overlays (labels, social cards, dynamic text)

**Pattern:**
1. Declare: `l_<public_id>` or `u_<public_id>` or `l_text:Arial_40:Hello%20World`
2. Transform (optional): e.g.  `/c_scale,w_100/` or `/o_50/` (opacity)
3. Apply: `/fl_layer_apply,g_<position>,x_<offset>,y_<offset>`

**Critical: Using `fl_relative` for overlay dimensions:**
- **Without `fl_relative`**: Dimensions are relative to the **overlay's original size**
  - Example: `w_1.0` = 100% of the overlay image's width (not useful for small images)
- **With `fl_relative`**: Dimensions are relative to the **base image's size**
  - Example: `w_1.0` = 100% of the base image's width (covers entire width)
  - **Always use `fl_relative`** when sizing overlays as a percentage of the base image

**Examples:**
```
l_logo/c_scale,w_100/fl_layer_apply,g_north_west,x_10,y_10                # Logo at 100px
l_logo/c_scale,fl_relative,w_0.25/fl_layer_apply,g_north_west,x_10,y_10  # Logo at 25% of image width
l_docs:one_black_pixel/c_scale,fl_relative,h_1.0,w_1.0/o_50/fl_layer_apply # Full-image semi-transparent overlay
co_yellow,l_text:Arial_40:Hello%20World/fl_layer_apply,g_south            # Text overlay
u_background/e_background_removal                                          # Custom background
c_fill,h_400,w_300/l_same_image/c_fill,e_grayscale,h_400,w_300/fl_layer_apply,g_west,x_300 # Side-by-side (600×400)
```

**Important**: 
- Color (`co_`) is a qualifier — use in the **same component** as text overlay declaration
- **Always use `fl_relative`** when you want overlay dimensions as a percentage of the base image
- **Side-by-side / canvas extension**: to place an overlay *beside* the base, offset it past the base edge — the canvas auto-expands. Use `g_west,x_<base_width>` for horizontal or `g_north,y_<base_height>` for vertical.

### Borders & Rounding

- **`r_N`** - Rounded corners (N = radius in pixels; for modern UI, cards)
- **`r_max`** - Perfect circle (use with square dimensions; avatars, icons)
- **`bo_NNpx_solid_color`** - Border (frame images, separate from background)

**Examples:**
```
r_20                           # 20px rounded corners
r_max                          # Perfect circle
bo_5px_solid_black             # 5px black border
r_20,bo_5px_solid_rgb:0066ff   # Rounded with border (same component)
```

**Important**: For borders that follow rounded corners, use border as qualifier in same component.

### Background Color

- **`b_color,c_pad`** - Fill empty space with solid color (product images, letterboxing)
- **`b_auto,c_pad`** - Aautomatically selected background color based on one or more predominant colors in the image
- **`b_gen_fill,c_pad`** - AI-extended background (change aspect ratio without cropping; see AI Transformations for cost)

**Examples:**
```
b_lightblue,c_pad,w_1.0         # Light blue background
b_auto,c_pad,ar_16:9            # Automatically selected color for background, 16:9
b_gen_fill,c_pad,ar_1:1         # AI-extended to square
b_blurred,c_pad,ar_16:9         # Blurred background (videos only), 16:9
```

**Critical**: Background (`b_`) is a qualifier - use **with** pad crop in same component: `b_color,c_pad,w_X`, NOT `/b_color/`.

### Rotation & Flips

- **`a_90`, `a_180`, `a_270`** - Rotate in 90° increments (correct orientation)
- **`a_N`** - Rotate by degrees (e.g., `a_-2` to straighten crooked photos)
- **`a_hflip`** - Horizontal flip (mirror selfies, directional images)
- **`a_vflip`** - Vertical flip (reflections)
- **`a_auto_right`/`a_auto_left`** - Auto-rotate based on EXIF orientation

**Examples:**
```
a_90                    # Rotate 90° clockwise
a_-2                    # Straighten slight tilt
a_hflip                 # Mirror horizontally
a_auto_right            # Auto-fix from EXIF
```

### Asset Type Matters (Image vs. Video)

Many flags and parameters apply to only one asset type. Applying one to the wrong base often **fails silently** — the URL still returns a valid `200` with no `X-Cld-Error`, just the wrong output. This goes both ways: video-only syntax on an image, and image-only syntax on a video. Always verify the actual output (dimensions, duration, frame count) rather than assuming it worked.

**Common video-only examples** (this is *not* an exhaustive list — ~35 parameters are video-only):
- **`fl_splice`** (flag) - Concatenate a clip/image onto the video timeline (no image equivalent — to place media side-by-side, offset the overlay to extend the canvas: `fl_layer_apply,g_west,x_<base_width>`)
- **`du_`, `so_`, `eo_`** - Trim/seek by time (duration, start offset, end offset)
- **`fps_`** - Set frame rate
- **`vc_`, `ac_`** - Video / audio codec
- **`e_boomerang`, `e_progressbar`** - Video-only effects

**When unsure whether a flag or parameter supports your asset type, check the [Transformation Reference](https://cloudinary.com/documentation/transformation_reference.md?install_source=skillspack&referrer=trans-skill) before applying it.**

## Named Transformations

Named transformations (`t_<name>`) save transformation chains for reuse. Suggest for:
- Transformations used across multiple assets
- Complex transformation chains
- Expensive operations (to enable baseline transformations and reduce costs)

**Baseline transformations** (`bl_<name>`) cache expensive named transformations so they don't need to be regenerated. Use `bl_` instead of `t_` for AI transformations (background removal, generative AI) that will have variations applied. This can reduce costs from 75-230 tx per variation down to 1 tx each after the initial baseline is generated.

**Example:** `bl_bg_removed/c_scale,w_500` - Uses cached background removal result, only pays for resize (1 tx instead of 75 tx)

**Important:** `f_auto`, `dpr_auto`, and `w_auto` don't work inside named transformations - use them directly in URLs: `t_avatar/f_auto/q_auto`

For complete details, limitations, and baseline transformation examples, see [references/named-transformations.md](references/named-transformations.md)

## Generative AI Transformations

**Proactively suggest these AI transformations when appropriate:**

**Note:** Numbers in parentheses (e.g., 75 tx) indicate additional transformation credits consumed per use. Standard transformations = 1 tx.

- **`e_background_removal`** (75 tx) - Remove backgrounds (e-commerce, profiles; combine with `f_png` or `b_color,c_pad`)
- **`b_gen_fill`** (50 tx) - Extend backgrounds (change aspect ratio without cropping; use with `c_pad`)
- **`e_gen_background_replace:prompt_<text>`** (230 tx) - AI-generated backgrounds (custom environments, seasonal variations; high cost)
- **`e_gen_replace:from_<obj>;to_<new>`** (120 tx) - Swap objects (product variations, colors; use `;preserve_geometry_true` for clothing)
- **`e_gen_remove:prompt_<text>`** (50 tx) - Remove objects (clean up distractions)
- **`e_auto_enhance`** (100 tx) - Improve quality (fix poor lighting/exposure)
- **`e_upscale`** (10-100 tx) - Enlarge without quality loss (low-res to high-res)

**Important:** AI transformations cost significantly more (50-230 tx vs 1 tx). Inform users of costs and consider baseline transformations (e.g., `bl_bg_removed/c_scale,w_500`) to avoid re-processing expensive operations - see [references/named-transformations.md](references/named-transformations.md#baseline-transformations) and [references/transformation-costs.md](references/transformation-costs.md) for details.

For complete details, syntax, and powerful combinations, see [references/ai-transformations.md](references/ai-transformations.md)

## Video-Specific Transformations

**Critical:** Use `f_auto:video` (not just `f_auto`) to ensure video output - plain `f_auto` may return an image thumbnail.

- **`vc_auto`** - Automatic codec (recommended; optimal for browser/device)
- **`so_N/eo_M`** - Trim (start/end in seconds; create clips, remove intro/outro)
- **`ac_none`** - Remove audio (essential for autoplay; reduces file size)
- **`fps_N`** - Set frame rate (lower = smaller file; standardize rates)
- **Video resizing** - Same crop modes as images (`c_fill`, `c_scale`, `c_pad`)

**Common patterns:**
```
vc_auto/ac_none/f_auto:video/q_auto                      # Autoplay-ready
so_0/du_10/vc_auto/f_auto:video/q_auto                   # First 10 seconds
c_scale,w_720/vc_auto/f_auto:video/q_auto                # Resize to 720p width
c_fill,g_auto,h_720,w_1280/vc_auto/f_auto:video/q_auto  # 720p HD, smart crop
```

For complete details including codecs, trimming strategies, and video concatenation, see [references/video-transformations.md](references/video-transformations.md)

## Variables & Conditionals

**Variables** reuse values and create templates:
```
$size_300/c_fill,h_$size,w_$size        # Reuse value
$iw/w_$iw_div_2                         # Half original width (arithmetic)
```

**Conditionals** adapt transformations dynamically:
```
if_w_gt_1000/c_scale,w_1000/if_end                          # Responsive sizing
if_ar_gt_1.0/c_fill,w_800,h_450/if_else/c_fill,w_450,h_800/if_end  # Orientation handling
```

**Key rules:**
- Variable names: alphanumeric, start with letter, no underscores
- Conditionals: Must close with `if_end`
- Arithmetic: `add`, `sub`, `mul`, `div` (left-to-right evaluation)

For complete syntax, arithmetic operations, nested conditionals, and real-world patterns, see [references/advanced-features.md](references/advanced-features.md)

## Self-Validation Checklist

**Before returning a transformation URL, verify:**

1. ✅ **URL structure is complete** (cloud_name, asset_type `/image/` or `/video/` or `/raw/`, delivery_type, public_id)
2. ✅ **Each component has only one action parameter** (e.g., one crop mode per component)
3. ✅ **Crop mode is explicit** (don't rely on defaults; avoid both dimensions with `c_scale`)
4. ✅ **Overlays end with `fl_layer_apply`** in separate component
5. ✅ **Text strings are URL-encoded** (spaces = `%20`, special chars encoded)
6. ✅ **Variable names follow rules** (alphanumeric, start with letter, no underscores)
7. ✅ **`g_auto` compatibility** (only works with `c_fill`, `c_lfill`, `c_crop`, `c_thumb`, `c_auto`)
8. ✅ **Background as qualifier** (use with pad crop: `b_color,c_pad,w_X`, not `/b_color/`)
9. ✅ **Format/quality at end** (prefer `f_auto/q_auto` as final components)
10. ✅ **Flags/parameters match the base asset type** (asset-type-specific syntax — e.g. video-only `fl_splice`, `du_`, `fps_`, `vc_` — often no-ops silently on the wrong base, in either direction; verify the output and check the Asset Type Matters section above)
11. ✅ **Transformation parameters are valid** (don't make up any parameter names - check against [Transformation Reference](https://cloudinary.com/documentation/transformation_reference.md?install_source=skillspack&referrer=trans-skill))
12. ✅ **SDK code comes from the reference** (if writing SDK code, the syntax matches the user's SDK tab on the parameter's reference page; see the Generating SDK Code section)

**Quick syntax check:**
- Commas separate parameters within a component: `c_fill,g_auto,w_400`
- Slashes separate components: `c_fill,w_400/f_auto/q_auto`
- Actions vs qualifiers: Only one action per component, qualifiers modify that action

See [references/debugging.md](references/debugging.md) for detailed examples of each check.

## Debugging Checklist

When a transformation isn't working, first run the Self-Validation Checklist above. Then check:

1. **The `X-Cld-Error` header**: Cloudinary reports errors in this HTTP response header
2. **Auto parameters in named transformations**: `f_auto`, `dpr_auto`, and `w_auto` don't work inside named transformations. Use them directly in URLs
3. **Client Hints for `dpr_auto`/`w_auto`**: These only work on Chromium browsers with Client Hints enabled, and fall back to `dpr_1.0` otherwise (see [references/responsive-images.md](references/responsive-images.md))
4. **Video returns an image**: Use `f_auto:video` (not just `f_auto`) for video transformations

For how to read the `X-Cld-Error` header and common error messages, see [references/debugging.md](references/debugging.md#checking-the-x-cld-error-header).

## Additional Resources

### Skill References (Progressive Disclosure)
- [references/debugging.md](references/debugging.md) - Use when transformations return errors or unexpected results
- [references/ai-transformations.md](references/ai-transformations.md) - Use when you need AI transformation prompt syntax, cost details, or complex AI combinations
- [references/video-transformations.md](references/video-transformations.md) - Use when working with video codecs, trimming strategies, concatenation, or creating animated images from videos
- [references/advanced-features.md](references/advanced-features.md) - Use when building complex logic with variables, conditionals, or arithmetic
- [references/responsive-images.md](references/responsive-images.md) - Use when implementing responsive images, configuring Client Hints, or using dpr_auto/w_auto
- [references/transformation-costs.md](references/transformation-costs.md) - Use when optimizing for cost or explaining cost implications to users
- [references/named-transformations.md](references/named-transformations.md) - Use when creating reusable transformations or reducing costs for repeated operations
- [references/examples.md](references/examples.md) - Use when you need real-world examples beyond the Quick Start (social cards, e-commerce, responsive images)
- [references/sdk-code.md](references/sdk-code.md) - Read before writing transformation code with any Cloudinary SDK
- [references/documentation-links.md](references/documentation-links.md) - Use when you need the full Cloudinary docs for an image or video transformation area

### Core Cloudinary Documentation
- [Transformation Reference](https://cloudinary.com/documentation/transformation_reference.md?install_source=skillspack&referrer=trans-skill) - All parameters

## Common Mistakes & Best Practices

**Avoid:**
- ❌ `w_400,h_300` → ✅ `c_scale,w_400` (both dimensions with c_scale distorts image; prefer one dimension)
- ❌ `c_scale,g_auto,w_400` → ✅ `c_fill,g_auto,w_400` (g_auto doesn't work with c_scale)
- ❌ `l_logo/fl_layer_apply,g_north_west` → ✅ `l_logo/c_scale,w_100/fl_layer_apply,g_north_west`
- ❌ `b_lightblue/e_trim` → ✅ `b_lightblue,c_pad,w_1.0/e_trim` (background as qualifier)
