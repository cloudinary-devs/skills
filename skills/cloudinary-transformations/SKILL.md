---
name: cloudinary-transformations
description: Create and debug Cloudinary transformation URLs from natural language instructions. Use when building Cloudinary delivery URLs, applying image/video transformations, optimizing media, or debugging transformation syntax errors.
---

# Cloudinary Transformation Rules

This skill helps you create valid Cloudinary transformation URLs from natural language instructions and debug transformation issues.

## When to Use This Skill

- Building Cloudinary delivery/transformation URLs
- Converting natural language requests to transformation syntax
- Debugging transformation URLs that aren't working
- Optimizing images or videos with Cloudinary
- Applying effects, overlays, resizing, or cropping

## Quick Reference

### URL Structure

```
https://res.cloudinary.com/<cloud_name>/<asset_type>/<delivery_type>/<transformations>/<version>/<public_id>.<ext>
```

**Key Rules:**
- Commas (`,`) separate parameters **within** a component
- Slashes (`/`) separate components **between** transformations
- Each component acts on the output of the previous one
- Format and quality must be separate: `f_auto/q_auto` NOT `f_auto,q_auto`

### Parameter Types

**Action parameters**: Perform transformations (one per component)
**Qualifier parameters**: Modify action behavior (same component as action)

Check the [Transformation Reference](https://cloudinary.com/documentation/transformation_reference.md) to determine if a parameter is an action or qualifier.

## Core Transformations

### Resize & Crop

```
c_scale,w_400           # Resize width, maintain aspect ratio
c_fill,g_auto,h_300,w_400  # Fill dimensions, smart crop
c_thumb,g_face,h_150,w_150 # Thumbnail with face detection
c_pad,b_white,w_800     # Pad with background color
c_limit,w_1000          # Limit size, no upscale
c_auto,g_auto,w_800     # Auto crop to interesting area
```

**Important**: Always specify a crop mode with width/height. Never use both dimensions with `c_scale` unless explicitly requested.

### Gravity (Focal Point)

```
g_auto          # Smart detection (works with c_fill, c_lfill, c_crop, c_thumb, c_auto)
g_face          # Face detection
g_center        # Center position
g_north_west    # Compass positions
x_20,y_30       # Pixel offsets
```

**Note**: `g_auto` does NOT work with `c_scale`, `c_fit`, `c_limit`, `c_pad`, or overlay positioning.

### Format & Quality

```
f_auto/q_auto           # Automatic optimization (ALWAYS separate with /)
f_webp                  # Specific format
q_80                    # Quality level
dpr_auto                # Retina displays
```

**Critical**: Format and quality parameters MUST be in separate components using `/`, never `,`.

### Effects

```
e_sepia                 # Sepia tone
e_grayscale             # Grayscale
e_blur:800              # Blur effect
e_sharpen               # Sharpen
e_cartoonify            # Cartoon effect
e_background_removal    # Remove background
co_rgb:0044ff,e_colorize:40  # Colorize (co_ is qualifier)
```

### Overlays & Underlays

```
l_logo/c_scale,w_100/fl_layer_apply,g_north_west,x_10,y_10
```

**Pattern:**
1. Declare layer: `l_<public_id>` or `u_<public_id>`
2. Transform layer: `/c_scale,w_100/` (optional)
3. Apply layer: `/fl_layer_apply,g_<position>,x_<offset>,y_<offset>`

**Text overlays:**
```
l_text:Arial_40:Hello%20World/co_yellow/fl_layer_apply,g_south
```

### Borders & Rounding

```
r_20                    # Rounded corners
r_max                   # Circle (if square dimensions)
bo_5px_solid_black      # Border
```

**Important**: For borders that follow rounded corners, use border as qualifier in same component:
```
r_20,bo_5px_solid_rgb:0066ff
```

### Background Color

```
b_lightblue,c_pad,w_1.0    # Background with pad crop
b_gen_fill                 # AI-generated background fill
```

**Critical**: Use background as a qualifier with a pad crop, NOT in its own component when chaining transformations.

### Rotation & Flips

```
a_90                    # Rotate 90 degrees
a_-20                   # Rotate -20 degrees
a_hflip                 # Horizontal flip
a_vflip                 # Vertical flip
```

## Generative AI Transformations

Cloudinary's AI transformations solve common business challenges. **Proactively suggest these when appropriate:**

### Background Removal (`e_background_removal`)
**Cost:** 75 tx | **Use when:**
- Creating product images for e-commerce (white/transparent backgrounds)
- Preparing images for overlays or compositing
- Removing distracting backgrounds from portraits
- Creating cutouts for marketing materials

```
e_background_removal/f_png
```

**Business value:** Professional product photos without manual editing or photoshoots

### Generative Fill (`b_gen_fill`)
**Cost:** 50 tx | **Use when:**
- Changing aspect ratios without cropping important content
- Extending images to fit different layouts (social media, banners)
- Filling transparent areas after background removal
- Creating images for different device sizes

```
c_pad,ar_16:9,b_gen_fill,w_1200/f_auto/q_auto
```

**Business value:** Adapt one image to multiple formats without reshooting

### Auto Enhance (`e_auto_enhance`)
**Cost:** 100 tx | **Use when:**
- Improving low-quality user-generated content
- Batch processing product photos with inconsistent lighting
- Enhancing old or poorly lit images
- Automatically correcting exposure, contrast, and color

```
e_auto_enhance/f_auto/q_auto
```

**Business value:** Professional-looking images without manual photo editing

### Upscale (`e_upscale`)
**Cost:** 10-100 tx (based on input size) | **Use when:**
- Enlarging low-resolution images for print or large displays
- Improving quality of user-uploaded images
- Scaling vintage or historical photos
- Creating high-res versions from small originals

```
e_upscale/c_scale,w_2000/f_auto/q_auto
```

**Business value:** Use existing images at larger sizes without quality loss

### When to Suggest AI Transformations

**Proactively recommend when users ask for:**
- "Remove background" → Use `e_background_removal`
- "Make image bigger/higher quality" → Use `e_upscale`
- "Improve image quality" → Use `e_auto_enhance`
- "Change aspect ratio without cropping" → Use `b_gen_fill` with `c_pad`
- "Extend image" or "fill empty space" → Use `b_gen_fill`
- "Professional product photos" → Combine `e_background_removal` + `b_gen_fill` or solid color

**Combine AI transformations for powerful results:**
```
e_background_removal/b_gen_fill,c_pad,ar_16:9,w_1200/e_auto_enhance/f_auto/q_auto
```
Removes background, extends to 16:9, and enhances quality in one URL

## Variables & Conditionals

### Variables

Use when values are reused or for template transformations.

```
$width_300/c_fill,h_$width,w_$width    # Declare and use
$date_12/l_text:Arial_40:$(date)/fl_layer_apply  # String variables use !text!
```

**Rules:**
- Variable names: alphanumeric only, must start with letter, NO underscores
- String assignment: `$var_!text value!`
- Reference: `$var` or `$(var)` in text

### Conditionals

```
if_w_gt_300/c_scale,w_300/if_end
if_!sale!_in_tags/l_sale_icon/fl_layer_apply/if_end
if_w_gt_300_and_h_gt_200/c_fill,h_200,w_300/if_else/c_pad,h_200,w_300/if_end
```

**Operators:**
- `eq`, `ne`, `lt`, `gt`, `lte`, `gte`
- `in`, `nin` (for tags)
- `and`, `or` (AND takes precedence)

**Conditions:**
- Dimensions: `if_w_gt_300`, `if_h_lte_200`
- Aspect ratio: `if_ar_gt_1.0`
- Tags: `if_!sale!_in_tags`
- Metadata: `if_md:!stock-level!_lt_50`

## Common Patterns

### Optimized Avatar
```
c_thumb,g_face,h_300,w_300/r_max/f_auto/q_auto
```

### Responsive Image
```
c_fill,g_auto,w_800/f_auto/q_auto/dpr_auto
```

### Watermarked Image
```
c_fit,w_1200/fl_relative,l_logo,o_40,w_0.25/fl_layer_apply,g_south_east,x_20,y_20/f_auto/q_auto
```

### Background Removal with Color
```
e_background_removal/b_lightblue,c_pad,w_1.0/f_png
```

### Text Overlay
```
co_yellow,l_text:Arial_60_bold:Hello/fl_layer_apply,g_north,y_50/f_auto/q_auto
```

## Debugging Checklist

When a transformation isn't working:

1. **Check the X-Cld-Error header**: Cloudinary reports errors in the `X-Cld-Error` HTTP response header
2. **Check parameter names** against [Transformation Reference](https://cloudinary.com/documentation/transformation_reference.md)
3. **Verify format/quality separation**: Must be `f_auto/q_auto` not `f_auto,q_auto`
4. **Check crop mode**: Width/height require a crop mode (e.g., `c_scale,w_400`)
5. **Verify gravity compatibility**: `g_auto` doesn't work with `c_scale`, `c_fit`, `c_limit`, `c_pad`
6. **Check action vs qualifier**: Only one action per component, qualifiers in same component
7. **Verify overlay pattern**: Must end with `fl_layer_apply` component
8. **Check variable names**: No underscores, must start with letter
9. **Verify URL encoding**: Text overlays need URL-encoded strings (spaces = `%20`)

### Checking X-Cld-Error Header

The `X-Cld-Error` header contains error details when a transformation fails. To check it:

**Using browser DevTools:**
1. Open Developer Tools (Network tab)
2. Request the transformation URL
3. Look for `X-Cld-Error` in Response Headers

**Using code (fetch the URL):**
```javascript
fetch('https://res.cloudinary.com/demo/image/upload/w_abc/sample.jpg')
  .then(response => {
    const error = response.headers.get('x-cld-error');
    if (error) {
      console.log('Cloudinary Error:', error);
    }
  });
```

**Common X-Cld-Error messages:**
- `Invalid width - abc` - Width parameter expects a number
- `Invalid transformation syntax` - Malformed transformation string
- `Resource not found` - Asset doesn't exist or public ID is incorrect
- `Transformation limit exceeded` - Account transformation quota reached

**Online tool:** Use the [X-Cld-Error Inspector](https://cloudinary.com/documentation/advanced_url_delivery_options#x_cld_error_inspector_tool) to check any Cloudinary URL

For more details, see [Error Handling](https://cloudinary.com/documentation/advanced_url_delivery_options#error_handling)

## Best Practices

1. **Always use `f_auto/q_auto`** at the end unless specific format/quality requested
2. **Prefer `g_auto`** for smart cropping unless specific focal point needed
3. **Order parameters alphabetically** within components for consistency
4. **Specify only one dimension** with `c_scale` to maintain aspect ratio
5. **Use `c_fill` or `c_auto` with `g_auto`** for smart cropping to dimensions
6. **Never guess parameter names** - always verify against documentation

## Transformation Costs

**Important**: Different transformations have different costs. Be aware of high-cost operations:

### Standard Transformations
- Basic image transformations: 1 transformation credit
- Video transformations: Counted per second (varies by resolution and codec)

### High-Cost Effects (per use)
- **Generative AI**: `e_gen_background_replace` (230 tx), `e_gen_replace` (120 tx), `e_gen_restore` (100 tx)
- **AI Enhancement**: `e_auto_enhance` (100 tx), `e_enhance` (100 tx)
- **Background Removal**: `e_background_removal` (75 tx), `e_extract` (75 tx)
- **Generative Edits**: `b_gen_fill` (50 tx), `e_gen_recolor` (50 tx), `e_gen_remove` (50 tx)
- **Upscale**: `e_upscale` (10-100 tx depending on input size)

### Cost Optimization Tips
1. **Use baseline transformations** for expensive effects: Save `e_background_removal` as a named transformation (e.g., `t_bg_removed`), then use `bl_bg_removed/c_scale,w_500` to avoid re-applying the effect
2. **Reuse derived assets**: Multiple requests to the same transformation URL don't incur additional costs
3. **Avoid unnecessary variations**: Different parameter orders create separate derived assets (e.g., `w_200,h_200` vs `h_200,w_200`)
4. **Consider format costs**: AVIF images cost 1 tx per 2MP (or part thereof)
5. **Video considerations**: HD video (1080p) costs more than SD (720p); AV1 codec costs significantly more than H.264

For complete transformation cost details, see [How are transformations counted?](https://cloudinary.com/documentation/transformation_counts.md)

## Additional Resources

### Core References
- [Transformation Reference](https://cloudinary.com/documentation/transformation_reference.md) - All parameters
- [Transformation Rules](https://cloudinary.com/documentation/cloudinary_transformation_rules.md) - Complete guide

### Image Transformations
- [Image Transformations Overview](https://cloudinary.com/documentation/image_transformations.md)
- [Resizing and Cropping](https://cloudinary.com/documentation/resizing_and_cropping.md)
- [Placing Layers on Images](https://cloudinary.com/documentation/layers.md)
- [Effects and Enhancements](https://cloudinary.com/documentation/effects_and_artistic_enhancements.md)
- [Background Removal](https://cloudinary.com/documentation/background_removal.md)
- [Generative AI Transformations](https://cloudinary.com/documentation/generative_ai_transformations.md)
- [Face-Detection Based Transformations](https://cloudinary.com/documentation/face_detection_based_transformations.md)
- [Custom Focus Areas](https://cloudinary.com/documentation/custom_focus_areas.md)
- [Transformation Refiners](https://cloudinary.com/documentation/transformation_refiners.md)
- [Animated Images](https://cloudinary.com/documentation/animated_images.md)
- [Transformations on 3D Models](https://cloudinary.com/documentation/transformations_on_3d_models.md)
- [Conditional Transformations](https://cloudinary.com/documentation/conditional_transformations.md)
- [User-Defined Variables and Arithmetic](https://cloudinary.com/documentation/user_defined_variables.md)
- [Custom Functions](https://cloudinary.com/documentation/custom_functions.md)

### Video Transformations
- [Video Transformations Overview](https://cloudinary.com/documentation/video_manipulation_and_delivery.md)
- [Resizing and Cropping](https://cloudinary.com/documentation/video_resizing_and_cropping.md)
- [Trimming and Concatenating](https://cloudinary.com/documentation/video_trimming_and_concatenating.md)
- [Placing Layers on Videos](https://cloudinary.com/documentation/video_layers.md)
- [Effects and Enhancements](https://cloudinary.com/documentation/video_effects_and_enhancements.md)
- [Audio Transformations](https://cloudinary.com/documentation/audio_transformations.md)
- [Converting Videos to Animated Images](https://cloudinary.com/documentation/videos_to_animated_images.md)
- [Conditional Transformations](https://cloudinary.com/documentation/video_conditional_expressions.md)
- [User-Defined Variables and Arithmetic](https://cloudinary.com/documentation/video_user_defined_variables.md)

## Common Mistakes to Avoid

❌ `f_auto,q_auto` → ✅ `f_auto/q_auto`
❌ `w_400,h_300` → ✅ `c_scale,w_400` (specify crop mode, prefer one dimension)
❌ `c_scale,g_auto,w_400` → ✅ `c_fill,g_auto,w_400` (g_auto doesn't work with c_scale)
❌ `l_logo/fl_layer_apply,g_north_west` → ✅ `l_logo/c_scale,w_100/fl_layer_apply,g_north_west`
❌ `b_lightblue/e_trim` → ✅ `b_lightblue,c_pad,w_1.0/e_trim` (background as qualifier)
