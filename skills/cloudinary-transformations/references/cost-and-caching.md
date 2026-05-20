# Cost And Caching Playbook

Use this reference when a transformation may be expensive, repeated many times, or generated in multiple variants. Verify current transformation counts and billing behavior in Cloudinary docs before quoting exact numbers.

## When To Warn

Warn or mention cost tradeoffs when using:
- Generative AI transformations.
- Background removal, extraction, restoration, enhancement, recoloring, or upscaling.
- Video transformations, especially long videos, high resolutions, or expensive codecs.
- AVIF or other formats with special counting behavior.
- Large batches, product catalogs, or many responsive variants.

Keep warnings practical. Do not block ordinary one-off image resizing with cost caveats.

## Cost-Saving Strategy

Use ordinary transformations directly when:
- The transformation is cheap.
- The URL is one-off.
- The user does not need multiple variants.

Suggest named transformations when:
- The same transformation chain appears across many assets.
- The chain is complex enough that readability and consistency matter.
- The user wants account-level reuse or easier updates.

Suggest baseline transformations when:
- An expensive operation is reused with multiple variants.
- AI/background-removal/upscale/restoration output will be resized, cropped, recolored, or overlaid in many ways.
- The user is building a catalog or pipeline and can pre-generate derivatives.

## Baseline Rules To Verify

Before suggesting or writing a baseline URL, verify the current docs. These are common rules to check:
- Baseline component comes first.
- Baseline component contains only the baseline reference.
- The referenced named transformation includes a concrete output format.
- Automatic runtime parameters such as `f_auto`, `w_auto`, and `dpr_auto` remain outside the named/baseline transformation.
- Baselines may not apply to every delivery type or transformation type.

## Quality Guidance

Avoid double lossy encoding:
- For expensive cached intermediate results, consider a high-quality or lossless intermediate format if supported and appropriate.
- Apply final delivery optimization after the baseline or named transformation.

Normalize transformation ordering:
- Use consistent parameter order to improve derived asset reuse.
- Avoid generating tiny value differences unless they matter visually.
- Prefer named transformations for repeated recipes so teams do not drift into near-duplicate URLs.
