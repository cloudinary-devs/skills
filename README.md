# Cloudinary Skills

The agent skills in this package help your AI coding assistant write correct Cloudinary code, answer questions using real documentation, and generate valid transformations.

## Available Skills

Skills are grouped by category below. The category is a folder in this repo only: you install a skill by its name, and the folder layout has no effect on how it is installed or used.

### Platform

| Skill | Description |
|---|---|
| `cloudinary-docs` | Selects the most relevant markdown pages from the current documentation using the latest llms.txt. Use when answering Cloudinary questions or integrating Cloudinary into code. |
| `cloudinary-transformations` | Turns natural language image and video transformation requirements into valid URL transformation strings that follow Cloudinary best practices. Use when building delivery URLs, applying transformations, optimizing media, or debugging transformation syntax errors. |
| `cloudinary-upload` | Guide uploading assets to Cloudinary — signed and unsigned uploads, upload presets, large files, remote/fetch uploads, and signature generation. Use when uploading files or URLs to Cloudinary, configuring upload presets, generating upload signatures, or debugging upload failures. For Next.js or React projects, use cloudinary-next or cloudinary-react alongside this skill. |

### Frameworks

| Skill | Description |
|---|---|
| `cloudinary-react` | Provides opinionated React SDK patterns for configuration, common integration scenarios, and troubleshooting for frequent errors and TypeScript pitfalls. Use when developing React apps with Cloudinary. |
| `cloudinary-next` | Provides opinionated Next.js SDK patterns for Server and Client Component boundaries, server-side uploads and deletes, and troubleshooting for frequent errors and TypeScript pitfalls. Use when developing Next.js apps with Cloudinary. |

## Install

Install the skills you need by name:

```bash
npx skills add cloudinary-devs/skills --skill cloudinary-docs,cloudinary-transformations
npx skills add cloudinary-devs/skills --skill cloudinary-upload
npx skills add cloudinary-devs/skills --skill cloudinary-next
```

Or install everything:

```bash
npx skills add cloudinary-devs/skills
```

You can install globally or per project.

> **💡 Tip:** [Cloudinary MCP servers](https://cloudinary.com/documentation/cloudinary_llm_mcp#mcp_servers) complement the Cloudinary Skills. Used together, skills and MCP servers improve the end-to-end workflow. For example, our skills spell out best practices such as using named transformations to apply the same transformation across many assets. Based on that, the model can decide which MCP tools to run to create named transformations that match your needs.

## Usage

Once installed, use your AI agent as normal. The skills fire automatically when you ask Cloudinary related questions or ask your agent to write Cloudinary integration code.

## Resources

- [Cloudinary Skills documentation](https://cloudinary.com/documentation/cloudinary_llm_mcp#cloudinary_skills)

## Feedback

Found a gap or have an idea for a new skill? [Open an issue](https://github.com/cloudinary-devs/skills/issues)
