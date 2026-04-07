# Cloudinary Skills

This repository contains agent skills for Cloudinary.

## Skills

| Skill | Description |
|-------|-------------|
| **cloudinary-docs** | Selects the most relevant markdown pages from the current documentation using the latest llms.txt. Use when answering Cloudinary questions or integrating Cloudinary into code.|
| **cloudinary-react** | Provides opinionated React SDK patterns for configuration, common integration scenarios, and troubleshooting for frequent errors and TypeScript pitfalls. Use when developing with the Cloudinary React SDK.|
| **cloudinary-transformations** | Turns natural-language image and video transformation requirements into valid URL transformation strings that follow Cloudinary best practices. Use when building delivery URLs, applying image/video transformations, optimizing media, or debugging transformation syntax errors. |

## Usage

Install all skills in a project or select the skills you want during the CLI installation:

```bash
npx skills add cloudinary-devs/skills
```

Then use your AI agent in that project; it can use these skills when handling Cloudinary-related questions.