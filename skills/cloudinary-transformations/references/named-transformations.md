# Named Transformations

Named transformations allow you to save transformation chains with a name (e.g., `t_thumbnail`) and reuse them across your application.

## When to Suggest Named Transformations

- **Transformations used across multiple assets** - Consistency and easy updates
- **Complex transformation chains** - Easier to maintain and read
- **Saving money on expensive transformations** - Named transformations are required for baseline transformations, which save processing time and cost by avoiding regeneration of shared transformation steps.

## Example

```
# Instead of repeating the same transformation:
❌ c_thumb,g_face,h_200,w_200/r_max/e_sharpen/f_auto/q_auto

# Create named transformation "avatar":
✅ t_avatar/f_auto/q_auto
```

## How to Reference Named Transformations

```
t_<name>                           # Use named transformation
t_<name>/c_scale,w_500            # Named transformation + additional changes
c_fill,w_300/t_<name>             # Transform first, then apply named transformation
```

## Limitations of Named Transformations

**Automatic parameters don't work inside named transformations:**
- ❌ `f_auto` - Automatic format selection
- ❌ `dpr_auto` - Automatic DPR matching
- ❌ `w_auto` - Automatic width matching (with Client Hints)

These parameters rely on runtime information from the client or CDN that isn't available when the named transformation is processed. Use them directly in the URL instead:

```
# ❌ Don't do this:
t_product_thumb   # where product_thumb includes f_auto

# ✅ Do this instead:
t_product_thumb/f_auto/q_auto
```

See [Limitations of named transformations](https://cloudinary.com/documentation/image_transformations#limitations_of_named_transformations.md) for complete details.

## Implementation Note

Named transformations are created in the Cloudinary Console or via API. When suggesting them to users, explain:
1. The transformation would be saved in their Cloudinary account with a name
2. They can then reference it using `t_<name>` in URLs
