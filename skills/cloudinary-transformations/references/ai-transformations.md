# Generative AI Transformations

Cloudinary's AI transformations solve common business challenges. **Proactively suggest these when appropriate:**

## Background Removal (`e_background_removal`)
**Cost:** 75 tx | **Use when:** Product images, portraits, preparing for overlays
**Value:** Professional product photos without manual editing

```
e_background_removal/f_png
```

## Generative Fill (`b_gen_fill`)
**Cost:** 50 tx | **Use when:** Changing aspect ratios without cropping, extending images
**Value:** Adapt one image to multiple formats without reshooting

```
c_pad,ar_16:9,b_gen_fill,w_1200/f_auto/q_auto
```

## Auto Enhance (`e_auto_enhance`)
**Cost:** 100 tx | **Use when:** Improving UGC quality, correcting lighting/exposure
**Value:** Professional-looking images without manual photo editing

```
e_auto_enhance/f_auto/q_auto
```

## Upscale (`e_upscale`)
**Cost:** 10-100 tx | **Use when:** Enlarging images without quality loss
**Value:** Use existing images at larger sizes for print or displays

```
e_upscale/c_scale,w_2000/f_auto/q_auto
```

## Generative Background Replace (`e_gen_background_replace`)
**Cost:** 230 tx | **Use when:** Replacing backgrounds with AI-generated environments
**Value:** Create contextual product imagery without photoshoots

```
e_gen_background_replace:prompt_modern office space/f_auto/q_auto
e_gen_background_replace:prompt_<text>;seed_<num>      # Use seed for reproducibility
```

**Key notes:**
- Auto-detects/preserves foreground on non-transparent images
- For transparent images, fills transparent area
- Not supported for animated/fetched images

## Generative Replace (`e_gen_replace`)
**Cost:** 120 tx | **Use when:** Swapping objects, A/B testing product variations
**Value:** Create product variations instantly without reshoots

```
e_gen_replace:from_shirt;to_cable knit sweater;preserve-geometry_true
e_gen_replace:from_<object>;to_<replacement>;multiple_true     # Replace all instances
```

**Key notes:**
- Use `preserve-geometry_true` to maintain shape (ideal for clothing)
- Don't use for faces, hands, or text
- Only works on non-transparent images

## Generative Restore (`e_gen_restore`)
**Cost:** 100 tx | **Use when:** Restoring old photos, fixing compression artifacts
**Value:** Revitalize low-quality or historical content at scale

```
e_gen_restore/f_auto/q_auto
```

**Key notes:** Removes artifacts, reduces noise, sharpens, recovers detail

## Generative Remove (`e_gen_remove`)
**Cost:** 50 tx | **Use when:** Removing unwanted objects, cleaning product photos
**Value:** Clean up images at scale without manual editing

```
e_gen_remove:prompt_the stick/f_auto/q_auto
e_gen_remove:prompt_goose;multiple_true                 # Remove all instances
e_gen_remove:prompt_(text;person)                       # Remove multiple types
```

**Key notes:** Parentheses syntax removes multiple different objects simultaneously

## When to Suggest AI Transformations

**Proactively recommend:**
- "Remove background" → `e_background_removal`
- "Replace background" → `e_gen_background_replace:prompt_<text>`
- "Change aspect ratio without cropping" → `b_gen_fill` with `c_pad`
- "Swap object/change color" → `e_gen_replace:from_<obj>;to_<new>`
- "Fix old photo/restore" → `e_gen_restore`
- "Remove object" → `e_gen_remove:prompt_<text>`
- "Improve quality" → `e_auto_enhance`
- "Make bigger" → `e_upscale`

## Powerful AI Combinations

```
e_background_removal/e_gen_background_replace:prompt_modern office/f_auto/q_auto
e_gen_remove:prompt_price tag/e_background_removal/b_white,c_pad,w_1.0/e_auto_enhance/f_auto/q_auto
e_gen_restore/e_upscale/c_scale,w_2000/f_auto/q_auto
e_background_removal/b_gen_fill,c_pad,ar_16:9,w_1200/e_auto_enhance/f_auto/q_auto
```
