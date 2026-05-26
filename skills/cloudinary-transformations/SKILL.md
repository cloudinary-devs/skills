---
name: cloudinary-transformations
description: Create, validate, and debug Cloudinary image and video transformation URLs from natural-language requirements. Use when building Cloudinary delivery URLs, choosing transformation strategy, optimizing media delivery, adding overlays/effects/AI transformations, working with named or baseline transformations, or troubleshooting transformation syntax and delivery errors.
license: MIT
metadata:
  author: cloudinary
  version: '1.0.1'
---

# Cloudinary Transformation Agent Playbook

This skill is an agent decision layer, not the syntax source of truth. Use Cloudinary's documentation markdown files for exact parameters, options, current limitations, and costs. Use this skill for workflow, defaults, common pitfalls, and debugging order.

## Docs First

When generating or debugging transformation syntax, consult the relevant Cloudinary docs via the docs markdown index at `https://cloudinary.com/documentation/llms.txt`.

Use these docs as the primary source:
- Transformation reference: exact parameter names, actions, qualifiers, values.
- Image transformations, resizing/cropping, layers, effects, background removal, generative AI transformations.
- Video manipulation/delivery, video resizing/cropping, trimming/concatenating, video layers, audio transformations.
- Responsive images and Client Hints docs for `w_auto`, `dpr_auto`, and breakpoints.
- Transformation counts docs for current cost behavior.

Use local references only for agent judgment:
- [references/agent-playbook.md](references/agent-playbook.md): intent mapping, defaults, and high-risk transformation patterns.
- [references/debugging-playbook.md](references/debugging-playbook.md): step-by-step failure isolation and `X-Cld-Error` workflow.
- [references/cost-and-caching.md](references/cost-and-caching.md): when to warn about cost and when to suggest named/baseline transformations.

## Workflow

1. Identify asset type: image, video, raw, animated image, or fetched media.
2. Clarify only blocking requirements: dimensions, crop behavior, focal point, transparency, output format, video duration/audio, and whether AI edits are acceptable.
3. Look up exact syntax in Cloudinary docs when using anything beyond stable, common patterns.
4. Build the shortest correct transformation chain.
5. Validate the URL with the checklist below.
6. For broken URLs, inspect `X-Cld-Error`, verify against docs, and isolate components one at a time.

## Default Decisions

- Add `f_auto/q_auto` near the end for most production image URLs.
- For video delivery, use `f_auto:video` or a specific video format. Plain `f_auto` can return an image representation.
- Use explicit crop modes. Avoid bare `h_300,w_400`.
- For exact fixed dimensions, prefer `c_fill,g_auto` unless the user gives a specific focal point.
- For no-crop resizing, use `c_fit`, `c_pad`, or `c_limit` based on whether padding or upscaling is acceptable.
- Preserve transparency with formats that support it, such as PNG or WebP. Do not force JPEG when transparency matters.
- Warn before AI transformations, video transformations, AVIF-heavy delivery, or other higher-cost operations. Verify current costs in docs.
- When presenting URLs or transformation examples, prefer SDK-style ordering: sort parameters alphabetically within each comma-separated component. This is a readability/docs consistency convention, not a semantic requirement. Do not reorder slash-separated components just to alphabetize them.

Do not add optimization when:
- The user needs an exact original or exact manual format/quality.
- The account already uses Optimize by Default and duplicate URL parameters would be undesirable.
- The user requires a specific format such as `f_png`, `f_jpg`, `f_mp4`, or `f_webm`.

## Requirement Hints

For resize/crop requests, determine:
- At least one dimension.
- Whether the result must fill a fixed box, fit inside a box, pad empty space, or only limit maximum size.
- Whether the crop should favor faces, a known subject, center, a compass position, or Cloudinary automatic gravity.

For AI requests, determine:
- Whether the user accepts higher transformation cost.
- For background removal: transparent output, solid background, underlay, or generated fill.
- For generative fill/replace/remove: target dimensions or prompt, object(s), whether to affect all instances, and whether reproducibility matters.
- Whether repeated variants justify a named/baseline transformation.

For video requests, determine:
- Trim start/end/duration.
- Output container/codec needs, or use automatic codec if unspecified.
- Whether audio should remain. For autoplay use cases, suggest removing audio.

## Validation Checklist

Before returning a transformation URL:
- URL has cloud name, asset type, delivery type, transformations, and public ID in the right order.
- Commas separate parameters in one component; slashes separate transformation components.
- Each component has at most one action parameter; qualifiers stay with the action they modify.
- Crop mode is explicit when dimensions are involved.
- Text overlays and prompts are safely URL-encoded where required.
- Layer transformations follow declare -> transform -> `fl_layer_apply`.
- Percentage overlay sizing uses `fl_relative` when it should be relative to the base asset.
- Background qualifiers such as `b_<color>`, `b_auto`, and `b_gen_fill` are used with the crop/pad action they qualify.
- `g_auto` is used only with compatible crop modes verified in docs.
- `f_auto`, `w_auto`, and `dpr_auto` are directly visible in the delivery URL when needed, not hidden inside named transformations.
- Video URLs that should return video use `f_auto:video` or a specific video format.

## Stable Patterns

Use these as starting points, then verify exact syntax in docs for non-trivial cases:

```text
c_scale,w_800/f_auto/q_auto
c_fill,g_auto,h_450,w_800/f_auto/q_auto
c_fit,h_450,w_800/f_auto/q_auto
b_white,c_pad,h_800,w_800/f_auto/q_auto
l_logo/c_scale,w_120/fl_layer_apply,g_south_east,x_20,y_20/f_auto/q_auto
co_white,l_text:Arial_48:Hello%20World/fl_layer_apply,g_south/f_auto/q_auto
e_background_removal/f_png/q_auto
c_scale,w_720/vc_auto/f_auto:video/q_auto
```

These examples are illustrative, not prescribed values. Choose dimensions, formats, colors, positions, and prompts from the user's actual requirements.

## Debugging

When a transformation fails:

1. Check the response header `X-Cld-Error`.
2. Confirm URL structure and asset existence.
3. Verify each parameter against the transformation reference.
4. Remove all but the simplest transformation; add components back one at a time.
5. Check high-risk areas: action/qualifier placement, overlays, crop/gravity compatibility, named transformation limitations, Client Hints, and video format behavior.

For the full debugging workflow, read [references/debugging-playbook.md](references/debugging-playbook.md).
