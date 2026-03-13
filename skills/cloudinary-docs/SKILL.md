---
name: cloudinary-docs
description: Looks up Cloudinary implementation details from official documentation using llms.txt. Use when working with Cloudinary SDKs, upload APIs, account configuration, webhooks, or integration guides. For building or debugging transformation URLs, use a more specialized approach.
---

# Cloudinary Documentation

Helps developers integrate Cloudinary into their applications by providing documentation and code examples retrieved directly from the optimized markdown files in the Cloudinary documentation.

## When to Use

- User asks about Cloudinary SDKs, upload APIs, or integration guides
- General Cloudinary documentation lookup (account settings, webhooks, DAM features)
- Looking up specific API endpoints or SDK methods

## Instructions

When answering questions about Cloudinary:

1. **First, get the documentation index** using llms.txt with the llms.txt URL - https://cloudinary.com/documentation/llms.txt
2. **Analyze the llms.txt content** to understand what documentation pages are available
3. **Reflect on the user's question** and identify which specific documentation URLs would be most relevant
4. **Navigate** to the specific relevant documentation URLs from the llms.txt index (you can make multiple calls)
5. **Use the fetched documentation** to provide a comprehensive, accurate answer

Example workflows:

**Example 1: Upload question**
- User asks: "How do I upload images to Cloudinary?"
- You retrieve the llms.txt index: https://cloudinary.com/documentation/llms.txt
- You analyze the llms.txt content to understand what documentation pages are available
- You identify relevant pages like "image_upload.md" or "upload_api.md"
- You retrieve those specific pages from the llms.txt index
- You provide an answer with code examples and citations

**Example 2: Transformation question**
- User asks: "How do I resize and crop images?"
- You retrieve the llms.txt index
- You identify relevant pages like "image_transformations.md" or "transformation_reference.md"
- You fetch the specific documentation
- You provide transformation syntax and examples

**Example 3: SDK question**
- User asks: "What's the Node.js SDK for Cloudinary?"
- You retrieve the llms.txt index
- You identify SDK-related pages
- You provide installation instructions and usage examples