# Transformation Costs & Optimization

**Important**: Different transformations have different costs. Be aware of high-cost operations and warn the user before generating transformations that cost more than a standard transformation.

## Standard Transformations
- Basic image transformations: 1 transformation credit
- Video transformations: Counted per second (varies by resolution and codec)

## High-Cost Effects (per use)
- **Generative AI**: `e_gen_background_replace` (230 tx), `e_gen_replace` (120 tx), `e_gen_restore` (100 tx)
- **AI Enhancement**: `e_auto_enhance` (100 tx), `e_enhance` (100 tx)
- **Background Removal**: `e_background_removal` (75 tx), `e_extract` (75 tx)
- **Generative Edits**: `b_gen_fill` (50 tx), `e_gen_recolor` (50 tx), `e_gen_remove` (50 tx)
- **Upscale**: `e_upscale` (10-100 tx depending on input size)

## Cost Optimization Tips

1. **Use baseline transformations** for expensive effects: Save `e_background_removal` as a named transformation (e.g., `t_bg_removed`), then use `bl_bg_removed/c_scale,w_500` to avoid re-applying the effect
2. **Reuse derived assets**: Multiple requests to the same transformation URL don't incur additional costs
3. **Avoid unnecessary variations**: Different parameter orders create separate derived assets (e.g., `w_200,h_200` vs `h_200,w_200`)
4. **Consider format costs**: AVIF images cost 1 tx per 2MP (or part thereof)
5. **Video considerations**: HD video (1080p) costs more than SD (720p); AV1 codec costs significantly more than H.264

For complete transformation cost details, see [How are transformations counted?](https://cloudinary.com/documentation/transformation_counts.md)
