# Cloudinary Skills

Agent skills that help your AI coding assistant write correct Cloudinary code, answer questions using real documentation, and generate valid transformation URLs.

## Available Skills

| Skill | Description |
|---|---|
| `cloudinary-docs` | Selects the most relevant markdown pages from the current documentation using the latest llms.txt. Use when answering Cloudinary questions or integrating Cloudinary into code. |
| `cloudinary-transformations` | Turns natural language image and video transformation requirements into valid URL transformation strings that follow Cloudinary best practices. Use when building delivery URLs, applying transformations, optimizing media, or debugging transformation syntax errors. |
| `cloudinary-react` | Provides opinionated React SDK patterns for configuration, common integration scenarios, and troubleshooting for frequent errors and TypeScript pitfalls. Use when developing with the Cloudinary React SDK. |

## Install

```bash
npx skills add cloudinary-devs/skills
```

Install all skills or select the ones you need. You can install globally or per project.

**Claude and Cursor users:** The Cloudinary plugin is also available in the [Claude marketplace](https://claude.com/plugins/cloudinary) and [Cursor marketplace](https://cursor.com/marketplace/cloudinary). Note that marketplace plugins include `cloudinary-docs` and `cloudinary-transformations` only.

## Usage

Once installed, use your AI agent as normal. The skills fire automatically when you ask Cloudinary related questions or ask your agent to write Cloudinary integration code.

## Resources

- [Cloudinary Skills documentation](https://cloudinary.com/documentation/cloudinary_llm_mcp#cloudinary_skills)

## Feedback

Found a gap or have an idea for a new skill? [Open an issue](https://github.com/cloudinary-devs/skills/issues)
