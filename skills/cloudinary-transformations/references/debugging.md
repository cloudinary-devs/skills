# Debugging Cloudinary Transformations

Common issues and their solutions when transformations don't work as expected.

## Syntax Errors

### Issue: Both Dimensions Without Explicit Crop Mode
⚠️ **Works but risky:**
```
w_400,h_300
```

✅ **Better:**
```
c_scale,w_400                  # Specify one dimension, maintain aspect ratio
```
or
```
c_fill,h_300,w_400            # Both dimensions needed, smart crop
```

**Why:** While `c_scale` is the default crop mode, specifying both dimensions with `c_scale` (explicit or default) will distort the image if the aspect ratio doesn't match the original. Best practice: specify the crop mode explicitly and prefer one dimension with `c_scale` to maintain aspect ratio.

### Issue: Invalid Parameter Names
❌ **Wrong:**
```
crop_scale,width_400
```

✅ **Correct:**
```
c_scale,w_400
```

**Why:** Cloudinary uses abbreviated parameter names. Always check the [Transformation Reference](https://cloudinary.com/documentation/transformation_reference).

## Gravity Issues

### Issue: g_auto Not Working
❌ **Wrong:**
```
c_scale,g_auto,w_400
```

✅ **Correct:**
```
c_fill,g_auto,w_400
```

**Why:** `g_auto` only works with: `c_fill`, `c_lfill`, `c_fill_pad`, `c_crop`, `c_thumb`, `c_auto`, `c_auto_pad`

**Does NOT work with:** `c_scale`, `c_fit`, `c_limit`, `c_mfit`, `c_pad`, `c_lpad`, `c_mpad`

### Issue: g_auto on Overlays
❌ **Wrong:**
```
l_logo/c_scale,w_100/fl_layer_apply,g_auto
```

✅ **Correct:**
```
l_logo/c_scale,w_100/fl_layer_apply,g_north_west,x_10,y_10
```

**Why:** `g_auto` doesn't work for positioning overlays. Use compass directions or `g_center`.

## Overlay Issues

### Issue: Overlay Not Appearing
❌ **Wrong:**
```
l_logo/c_scale,w_100
```

✅ **Correct:**
```
l_logo/c_scale,w_100/fl_layer_apply,g_north_west
```

**Why:** Every overlay must end with a `fl_layer_apply` component.

### Issue: Overlay Positioning in Wrong Component
❌ **Wrong:**
```
l_logo,g_north_west/c_scale,w_100/fl_layer_apply
```

✅ **Correct:**
```
l_logo/c_scale,w_100/fl_layer_apply,g_north_west
```

**Why:** Positioning parameters (`g_`, `x_`, `y_`) go in the `fl_layer_apply` component, not the layer declaration.

### Issue: Multiple Overlays Missing fl_layer_apply
❌ **Wrong:**
```
l_logo/c_scale,w_100/l_badge/c_scale,w_60/fl_layer_apply,g_north_west
```

✅ **Correct:**
```
l_logo/c_scale,w_100/fl_layer_apply,g_north_west,x_10,y_10/l_badge/c_scale,w_60/fl_layer_apply,g_north_east,x_10,y_10
```

**Why:** Each overlay needs its own `fl_layer_apply` component.

## Background Color Issues

### Issue: Background Not Applied in Chained Transformations
❌ **Wrong:**
```
e_background_removal/b_lightblue/e_trim
```

✅ **Correct:**
```
e_background_removal/b_lightblue,c_pad,w_1.0/e_trim
```

**Why:** When chaining transformations, use background as a qualifier with a pad crop that doesn't change dimensions.

### Issue: Background on Non-Transparent Image
❌ **Wrong:**
```
c_fill,h_400,w_600/b_blue
```

✅ **Correct:**
```
c_pad,b_blue,h_400,w_600
```

**Why:** Background color only shows on transparent areas or with pad crop mode.

## Border and Rounding Issues

### Issue: Border Not Following Rounded Corners
❌ **Wrong:**
```
r_20/bo_5px_solid_blue
```

✅ **Correct:**
```
bo_5px_solid_blue,r_20
```

**Why:** Border is a qualifier in this case and should be in the same component as radius to follow the rounded corners.

### Issue: Border on Transparent Images
❌ **Wrong:**
```
bo_5px_solid_blue
```

✅ **Correct:**
```
co_rgb:0066ff,e_outline:outer:15:200
```

**Why:** For images with transparency, use `e_outline` effect instead of `bo_` border.

## Variable Issues

### Issue: Variable Name with Underscore
❌ **Wrong:**
```
$my_width_300/c_scale,w_$my_width
```

✅ **Correct:**
```
$mywidth_300/c_scale,w_$mywidth
```

**Why:** Variable names cannot contain underscores. Use alphanumeric characters only, must start with a letter.

### Issue: String Variable Without Delimiters
❌ **Wrong:**
```
$color_blue/b_$color
```

✅ **Correct:**
```
$color_!blue!/b_$color
```

**Why:** String values must be wrapped in `!` delimiters when assigning to variables.

### Issue: Variable Reference in Text
❌ **Wrong:**
```
$date_25/l_text:Arial_40:Day%20$date/fl_layer_apply
```

✅ **Correct:**
```
$date_25/l_text:Arial_40:Day%20$(date)/fl_layer_apply
```

**Why:** In text overlays, wrap variable names in `$()` for proper interpolation.

## Conditional Issues

### Issue: Missing if_end
❌ **Wrong:**
```
if_w_gt_300/c_scale,w_300
```

✅ **Correct:**
```
if_w_gt_300/c_scale,w_300/if_end
```

**Why:** Every conditional must close with `if_end`.

### Issue: Tag Condition Without Delimiters
❌ **Wrong:**
```
if_sale_in_tags/l_badge/fl_layer_apply/if_end
```

✅ **Correct:**
```
if_!sale!_in_tags/l_badge/fl_layer_apply/if_end
```

**Why:** Tag values must be wrapped in `!` delimiters.

### Issue: Multiple Tags Without Colon
❌ **Wrong:**
```
if_!sale!_!featured!_in_tags
```

✅ **Correct:**
```
if_!sale:featured!_in_tags
```

**Why:** Multiple tags are separated by colons within the `!` delimiters (colon means AND).

## Text Overlay Issues

### Issue: Spaces Not Encoded
❌ **Wrong:**
```
l_text:Arial_40:Hello World/fl_layer_apply
```

✅ **Correct:**
```
l_text:Arial_40:Hello%20World/fl_layer_apply
```

**Why:** Text must be URL-encoded. Spaces become `%20`.

### Issue: Color Not Applied to Text
❌ **Wrong:**
```
l_text:Arial_40:Hello/co_yellow/fl_layer_apply
```

✅ **Correct:**
```
co_yellow,l_text:Arial_40:Hello/fl_layer_apply
```

**Why:** Color (`co_`) is a qualifier and must be in the same component as the text overlay.

### Issue: Background Not Applied to Text
❌ **Wrong:**
```
l_text:Arial_40:Hello/b_black/fl_layer_apply
```

✅ **Correct:**
```
b_black,l_text:Arial_40:Hello/fl_layer_apply
```

**Why:** Background (`b_`) is a qualifier and must be in the same component as the text overlay.

## Action vs Qualifier Issues

### Issue: Multiple Actions in One Component
❌ **Wrong:**
```
c_scale,e_sepia,w_400
```

✅ **Correct:**
```
c_scale,w_400/e_sepia
```

**Why:** Only one action parameter per component. Separate actions with `/`.

### Issue: Qualifier in Wrong Component
❌ **Wrong:**
```
e_colorize:40/co_rgb:0044ff
```

✅ **Correct:**
```
co_rgb:0044ff,e_colorize:40
```

**Why:** Qualifiers must be in the same component as the action they modify.

## Aspect Ratio Issues

### Issue: Both Dimensions with c_scale
❌ **Wrong:**
```
c_scale,h_300,w_400
```

✅ **Correct:**
```
c_scale,w_400
```
or
```
c_fill,h_300,w_400
```

**Why:** Using both dimensions with `c_scale` distorts the image. Specify one dimension, or use `c_fill` to crop.

### Issue: Aspect Ratio Syntax
❌ **Wrong:**
```
c_fill,ar_16/9,w_800
```

✅ **Correct:**
```
c_fill,ar_16:9,w_800
```

**Why:** Aspect ratio uses colon (`:`) not slash (`/`).

## Format Issues

### Issue: PNG for Large Images
❌ **Wrong:**
```
c_scale,w_2000/f_png
```

✅ **Correct:**
```
c_scale,w_2000/f_auto/q_auto
```

**Why:** PNG creates very large files. Use `f_auto` to let Cloudinary choose the best format.

### Issue: Transparency Lost
❌ **Wrong:**
```
e_background_removal/f_jpg
```

✅ **Correct:**
```
e_background_removal/f_png
```

**Why:** JPEG doesn't support transparency. Use PNG, WebP, or `f_auto`.

## Quality Issues

### Issue: Over-Compression
❌ **Wrong:**
```
q_auto:eco
```

✅ **Correct:**
```
q_auto
```
or
```
q_80
```

**Why:** `q_auto:eco` is very aggressive. Use standard `q_auto` or specify quality level.

### Issue: Large File Size
❌ **Wrong:**
```
c_scale,w_2000/f_png
```

✅ **Correct:**
```
c_scale,w_2000/f_auto/q_auto
```

**Why:** Always use `f_auto/q_auto` for optimization unless specific format required.

## URL Structure Issues

### Issue: Missing Asset Type
❌ **Wrong:**
```
https://res.cloudinary.com/demo/upload/c_scale,w_300/sample.jpg
```

✅ **Correct:**
```
https://res.cloudinary.com/demo/image/upload/c_scale,w_300/sample.jpg
```

**Why:** The asset type (`/image/`, `/video/`, or `/raw/`) is required between the cloud name and delivery type.

**URL structure must be:**
```
https://res.cloudinary.com/<cloud_name>/<asset_type>/<delivery_type>/<transformations>/<public_id>
```

### Issue: Wrong Asset Type
❌ **Wrong:**
```
https://res.cloudinary.com/demo/video/upload/sample.jpg
```

✅ **Correct:**
```
https://res.cloudinary.com/demo/image/upload/sample.jpg
```

**Why:** Asset type must match the actual asset. Images use `/image/`, videos use `/video/`, other files use `/raw/`.

## Debugging Workflow

When a transformation doesn't work:

1. **Verify URL structure**
   - Check cloud name exists: `/<cloud_name>/`
   - **Check asset type is present:** `/image/` or `/video/` or `/raw/` 
   - Check delivery type: `/upload/` or `/fetch/` etc.
   - Verify public ID exists and is spelled correctly

2. **Check component separation**
   - Commas within components: `c_scale,w_400`
   - Slashes between components: `c_scale,w_400/f_auto/q_auto`

3. **Validate parameter names**
   - Cross-reference with [Transformation Reference](https://cloudinary.com/documentation/transformation_reference)
   - Check for typos and abbreviations

4. **Check action vs qualifier**
   - Only one action per component
   - Qualifiers in same component as action

5. **Verify gravity compatibility**
   - `g_auto` only works with certain crop modes
   - Check crop mode compatibility

6. **Test incrementally**
   - Start with basic transformation
   - Add parameters one at a time
   - Identify which parameter causes the issue

7. **Check browser console**
   - Look for 404 errors (asset not found)
   - Look for 400 errors (invalid transformation)

8. **Use Cloudinary Media Inspector**
   - Install browser extension
   - Inspect transformation details
   - View transformation breakdown

## Common Error Messages

### "Invalid transformation"
- Check parameter names against documentation
- Verify component structure (commas vs slashes)
- Check for typos

### "Resource not found"
- Verify public ID is correct
- Check asset type (image/video/raw)
- Verify delivery type (upload/fetch/etc)

### "Invalid crop mode"
- Check crop mode compatibility with other parameters
- Verify `g_auto` is used with compatible crop mode

### "Invalid color"
- Use `rgb:` prefix for hex colors: `rgb:ff6600`
- Check named color spelling
- Verify color format

## Testing Tips

1. **Start simple**: Begin with `c_scale,w_400/f_auto/q_auto`
2. **Add incrementally**: Add one parameter at a time
3. **Use browser DevTools**: Check network tab for errors
4. **Test in isolation**: Remove other transformations to isolate issue
5. **Check documentation**: Always verify parameter syntax

## Quick Reference

**Always separate with `/`:**
- Different actions: `c_scale,w_400/e_sepia/f_auto/q_auto`

**Always in same component:**
- Action and its qualifiers: `co_yellow,l_text:Arial_40:Hello`
- Border and radius: `bo_5px_solid_blue,r_20`

**Always use:**
- Crop mode with dimensions: `c_scale,w_400`
- `fl_layer_apply` after overlays
- `if_end` after conditionals

**Never do:**
- `g_auto` with `c_scale`, `c_fit`, `c_limit`, `c_pad`
- Multiple actions in one component
- Underscores in variable names
