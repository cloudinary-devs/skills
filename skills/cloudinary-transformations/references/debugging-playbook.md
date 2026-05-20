# Debugging Playbook

Use this reference when a Cloudinary transformation URL fails, returns an unexpected asset, or produces poor visual output.

## Fast Workflow

1. Request the URL and inspect the `X-Cld-Error` response header.
2. Confirm cloud name, asset type, delivery type, version/public ID, extension, and whether the asset exists.
3. Verify each parameter in the Cloudinary transformation reference.
4. Reduce to a known-good URL with no transformations or one simple resize.
5. Add components back one at a time until the failure returns.
6. Fix action/qualifier placement, unsupported combinations, encoding, named transformation limitations, or account-feature issues.

## How To Inspect Errors

Browser:
- Open DevTools Network tab.
- Request the URL.
- Select the response and check `X-Cld-Error`.

Fetch:

```javascript
const response = await fetch(url);
console.log(response.headers.get("x-cld-error"));
```

Common meanings:
- Invalid parameter value: check type, spelling, supported values, and separators.
- Invalid transformation syntax: check component boundaries and URL encoding.
- Resource not found: check cloud name, asset type, delivery type, public ID, extension, and version.
- Transformation quota/limit: check current account limits and transformation counts.

## High-Risk Areas

URL structure:
- Expected shape: `https://res.cloudinary.com/<cloud_name>/<asset_type>/<delivery_type>/<transformations>/<version>/<public_id>.<ext>`.
- For fetched media, confirm the fetch URL is encoded as required by the docs.

Actions vs qualifiers:
- Use commas inside one component.
- Use slashes between components.
- Keep qualifiers with the action they modify.
- Separate multiple actions into separate components.

Resize/crop:
- Specify crop mode explicitly.
- Avoid `c_scale` with both width and height unless distortion is intentional.
- Verify automatic gravity compatibility for the selected crop mode.

Layers:
- Every overlay/underlay must be applied with `fl_layer_apply`.
- Layer placement belongs on the apply component.
- Text and public IDs with special characters need correct escaping/encoding.
- Use `fl_relative` for percentages relative to the base asset.

Named and baseline transformations:
- Do not hide runtime automatic parameters inside named transformations.
- Put baseline transformations first and alone in their component.
- Verify baseline support for the delivery type and transformation type.

Responsive delivery:
- `w_auto` and `dpr_auto` need Client Hints and have browser/runtime constraints.
- Test in a browser that actually sends the required hints.
- Fall back to explicit `srcset`/`sizes` or explicit DPR variants when needed.

Video:
- Use `/video/` asset type for transformed videos.
- Use `f_auto:video` or a specific video format if the output must be video.
- Check audio settings when a preview should autoplay.
- Verify trim values are seconds or percentages as documented.

Visual quality:
- Use `q_auto` for most delivery.
- Use higher quality variants only when the user has a visual requirement.
- Avoid forcing PNG for large photographic images unless transparency or lossless output is required.
- Watch for double lossy encoding when chaining expensive cached/baseline transformations.
