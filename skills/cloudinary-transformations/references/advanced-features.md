# Advanced Features

## Variables

Use when values are reused or for template transformations.

```
$width_300/c_fill,h_$width,w_$width    # Declare and use
$date_12/l_text:Arial_40:$(date)/fl_layer_apply  # String variables use !text!
```

**Rules:**
- Variable names: alphanumeric only, must start with letter, NO underscores
- String assignment: `$var_!text value!`
- Reference: `$var` or `$(var)` in text

## Conditionals

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
