# Cloudinary Skills

This repository contains agent skills for Cloudinary.

## Skills

| Skill | Description |
|-------|-------------|
| **cloudinary-docs** | Look up Cloudinary documentation using llms.txt and sanitized markdown; use when answering general Cloudinary questions or integrating Cloudinary. |
| **cloudinary-react** | React-specific patterns, best practices, import reference, and common errors for the Cloudinary SDK (Vite, Upload Widget, AdvancedImage/Video, overlays, signed uploads). |
| **cloudinary-transformations** | Create and debug Cloudinary transformation URLs from natural language instructions; use when building delivery URLs, applying image/video transformations, optimizing media, or debugging transformation syntax errors. |

## Usage

Install all skills in a project:

```bash
npx skills add cloudinary-devs/skills
```

Then use your AI agent in that project; it can use these skills when handling Cloudinary-related questions.