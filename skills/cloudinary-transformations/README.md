# Cloudinary Transformations Skill

This skill helps AI agents create and debug Cloudinary transformation URLs from natural language instructions.

## Purpose

Enables agents to:
- Convert natural language requests into valid Cloudinary transformation syntax
- Build delivery URLs with proper parameter structure
- Debug transformation issues and syntax errors
- Apply best practices for image and video optimization
- Understand the difference between action and qualifier parameters

## Files

- **SKILL.md** - Main skill instructions with quick reference and common patterns
- **references/** - Supporting documentation
  - **examples.md** - Comprehensive examples of transformation patterns
  - **debugging.md** - Common issues, error messages, and debugging workflow
- **README.md** - This file

## When This Skill is Used

The agent will automatically use this skill when:
- Building Cloudinary delivery/transformation URLs
- Converting natural language to Cloudinary syntax
- Debugging transformation errors
- Optimizing images or videos
- Applying effects, overlays, resizing, or cropping

## Key Concepts

### URL Structure
```
https://res.cloudinary.com/<cloud_name>/<asset_type>/<delivery_type>/<transformations>/<version>/<public_id>.<ext>
```

### Component Rules
- **Commas** (`,`) separate parameters within a component
- **Slashes** (`/`) separate components between transformations
- Each component acts on the output of the previous one

### Critical Rules
1. Format and quality must be separate: `f_auto/q_auto` NOT `f_auto,q_auto`
2. Only one action parameter per component
3. Qualifiers must be in the same component as their action
4. Width/height require a crop mode
5. `g_auto` only works with certain crop modes

## Quick Examples

### Basic Optimization
```
c_scale,w_400/f_auto/q_auto
```

### Smart Crop
```
c_fill,g_auto,h_300,w_400/f_auto/q_auto
```

### Logo Overlay
```
l_logo/c_scale,w_100/fl_layer_apply,g_north_west,x_10,y_10/f_auto/q_auto
```

### Background Removal
```
e_background_removal/b_lightblue,c_pad,w_1.0/f_png
```

## References

- [Cloudinary Transformation Rules](https://cloudinary.com/documentation/cloudinary_transformation_rules.md)
- [Transformation Reference](https://cloudinary.com/documentation/transformation_reference)
- [Image Transformations Guide](https://cloudinary.com/documentation/image_transformations)
- [Video Transformations Guide](https://cloudinary.com/documentation/video_manipulation_and_delivery)

## Skill Metadata

- **Name**: cloudinary-transformations
- **Type**: Project skill
- **Location**: `.cursor/skills/cloudinary-transformations/`
- **Version**: 1.0
- **Created**: February 2026
