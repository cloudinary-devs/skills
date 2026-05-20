# Transformation Agent Playbook

Use this reference when deciding how to translate user intent into a Cloudinary transformation chain. Verify exact syntax, supported values, and current limitations in Cloudinary docs before returning non-trivial URLs.

## Intent Mapping

Resize without cropping:
- Use a scale/fit/limit strategy.
- Use one dimension when maintaining aspect ratio is enough.
- Use a limit strategy when small originals should not be upscaled.

Fit an exact visual slot:
- Use fill when cropping is acceptable.
- Use pad when the entire image must remain visible.
- Use a background qualifier for padding: solid color, automatic blurred background, or generated fill if AI cost is acceptable.

Choose focal point:
- Use automatic gravity for varied content.
- Use face/person/object-specific gravity only when it matches the asset and task.
- Use compass gravity or explicit offsets for predictable layouts and overlays.
- Verify `g_auto` compatibility in the docs for the chosen crop mode.

Preserve transparency:
- Use a transparency-supporting output format.
- Avoid JPEG if transparent pixels must remain.
- If the final image needs a solid background, add the background intentionally instead of relying on format conversion.

Overlays and underlays:
- Use declare -> transform -> apply.
- Apply every layer with `fl_layer_apply`.
- Put layer placement qualifiers on the apply component.
- Use `fl_relative` when layer dimensions should be relative to the base asset, not the layer's original dimensions.
- URL-encode text overlays and prompts.

Video:
- Use video asset paths and video docs.
- Use `f_auto:video` or a specific video format when the result must be video.
- Suggest `ac_none` for autoplay or silent preview use cases.
- Prefer automatic codec selection unless the user has a compatibility requirement.

Responsive images:
- Treat `w_auto`, `dpr_auto`, and responsive breakpoints as runtime/client-hint features.
- Verify Client Hints setup and browser support before relying on them.
- For universal support, generate explicit `srcset`/`sizes` or explicit DPR variants.

Variables and conditionals:
- Use them when the URL must adapt by asset dimensions, metadata, tags, or repeated values.
- Avoid them for simple one-off transformations.
- Keep variable names alphanumeric and starting with a letter.
- Close conditionals with `if_end`.
- Prefer named transformations when the same complex chain is reused across assets.

## Footguns To Check

- Bare dimensions can imply default behavior. Make the crop mode explicit.
- `c_scale` with both width and height can distort if aspect ratios differ.
- Qualifiers belong in the same component as the action they modify.
- Action parameters generally need separate components.
- Background values usually qualify pad/fill behavior; do not place them as unrelated standalone components.
- Automatic runtime parameters such as `f_auto`, `w_auto`, and `dpr_auto` should stay visible in delivery URLs, especially with named transformations.
- Different parameter orderings or small value changes can create separate derived assets and extra transformations.
- When showing examples to users, sort parameters alphabetically within each comma-separated component to match SDK-style URLs. Treat this as presentation consistency, not a correctness requirement.

## Minimal Recipes

Use these only as skeletons:

```text
# Maintain aspect ratio
c_scale,w_<width>/f_auto/q_auto

# Exact crop with automatic focus
c_fill,g_auto,h_<height>,w_<width>/f_auto/q_auto

# Exact box without cropping
b_<background>,c_pad,h_<height>,w_<width>/f_auto/q_auto

# Logo overlay
l_<logo_public_id>/c_scale,w_<logo_width>/fl_layer_apply,g_<position>,x_<x>,y_<y>/f_auto/q_auto

# Text overlay
co_<color>,l_text:<font>_<size>:<encoded_text>/fl_layer_apply,g_<position>/f_auto/q_auto

# Background removal with transparency
e_background_removal/f_png/q_auto

# Autoplay-ready video
c_scale,w_<width>/ac_none/vc_auto/f_auto:video/q_auto
```
