# Cloudinary Skills

The agent skills in this package help your AI coding assistant write correct Cloudinary code, answer questions using real documentation, and generate valid transformations.

## Available Skills

Skills are grouped by category below. The category is a folder in this repo only: you install a skill by its name, and the folder layout has no effect on how it is installed or used.

### Platform

| Skill | Description |
|---|---|
| `cloudinary-docs` | Selects the most relevant markdown pages from the current documentation using the latest llms.txt. Use when answering Cloudinary questions or integrating Cloudinary into code. |
| `cloudinary-transformations` | Turns natural language image and video transformation requirements into valid URL transformation strings that follow Cloudinary best practices. Use when building delivery URLs, applying transformations, optimizing media, or debugging transformation syntax errors. |
| `cloudinary-upload` | Reference for uploading assets to Cloudinary, covering signed and unsigned uploads, upload presets, transformations on upload, naming and folders, large files, remote uploads, and signature generation. Use when uploading files or URLs to Cloudinary, configuring upload presets, generating upload signatures, choosing between the SDK, REST API, or Upload widget, or debugging upload failures. For Next.js or React projects, use cloudinary-next or cloudinary-react alongside this skill. |
| `cloudinary-video` | Reference for building video experiences with the Cloudinary Video Player. Use when adding or improving video on a page or site, choosing adaptive or progressive delivery, or generating captions, chapters, and titles for video. |

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

## Version check

The first time a skill is used in a conversation, it asks your agent to fetch
Cloudinary's skills index at
`https://cloudinary.com/documentation/.well-known/agent-skills/index.json`, compare
the latest version with the installed one, and tell you only if a newer version
exists. The agent doesn't update anything itself.

The request includes the skill name and version, the agent product and model,
the kind of task (for example `setup` or `upload`), and your Cloudinary cloud name
if the agent already knows it from your conversation or code. Cloudinary uses
this to understand how the skills are used. The agent never opens files or runs
commands to find your cloud name, and never sends API keys or secrets.

To turn the check off, tell your agent not to run it, for example in your
project's `AGENTS.md` or `CLAUDE.md`: "Skip the Cloudinary skills version check."

## Resources

- [Cloudinary Skills documentation](https://cloudinary.com/documentation/cloudinary_llm_mcp#cloudinary_skills)

## Feedback

Found a gap or have an idea for a new skill? [Open an issue](https://github.com/cloudinary-devs/skills/issues)
