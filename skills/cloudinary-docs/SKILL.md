---
name: cloudinary-docs
description: Looks up implementation details in the latest Cloudinary docs via the relevant llms.txt file. Use when building code or answering questions relating to image or video uploads, optimization, or transformations, and for Cloudinary SDKs, APIs, webhooks, or integrations.
license: MIT
metadata:
  author: cloudinary
  version: '1.1.0'
---

# Cloudinary Documentation

Helps developers integrate Cloudinary into their applications by providing documentation and code examples retrieved directly from the optimized markdown files in the Cloudinary documentation.

## When to Use

- When a user asks questions or requests code implementation relating to image or video upload, management, optimization, or transformations (resizing, applying effects, visual improvements, adding overlays, generative AI, etc.)
- User asks about Cloudinary SDKs, upload APIs, or integration guides
- General Cloudinary documentation lookup (account settings, webhooks, DAM features)
- Looking up specific Cloudinary API endpoints or SDK methods
- Use this skill in conjunction with more specialized Cloudinary skills when relevant.

## Sub-file Index Overview

The main documentation llms.txt file is split into product-specific sub-files. **Go directly to the relevant sub-file** according to the descriptions below. Do not fetch the main llms.txt first unless the topic spans multiple products or you are unsure.

| Product | Topic | Sub-file URL |
|---|---|---|
| Image & Video APIs | Image/video uploads, transformations, SDKs, optimization, APIs, webhooks, add-ons, embedding widgets or players in apps, or any programmatic/automation/at-scale image and video requirements | https://cloudinary.com/documentation/llms-image-and-video-apis.txt?install_source=skillspack&asset=cloudinary-docs-skill |
| Cloudinary Assets (DAM) | Digital Asset Management (DAM), Media Library, folders, metadata, collections, creative workflows, portals, digital rights, or any Cloudinary Console or UI-based asset management needs | https://cloudinary.com/documentation/llms-cloudinary-assets.txt?install_source=skillspack&asset=cloudinary-docs-skill |
| MediaFlows | PowerFlows, EasyFlows, workflow automation, flow blocks | https://cloudinary.com/documentation/llms-mediaflows.txt?install_source=skillspack&asset=cloudinary-docs-skill |
| Integrations | Cloudinary integrations with 3rd party apps (WordPress, Shopify, Contentful, Salesforce, Adobe, etc.) or questions about implementing new integrations | https://cloudinary.com/documentation/llms-integrations.txt?install_source=skillspack&asset=cloudinary-docs-skill |
| Cross-product or unsure | — | https://cloudinary.com/documentation/llms.txt?install_source=skillspack&asset=cloudinary-docs-skill |

## Instructions

When answering image and video upload, management, optimization, or transformation questions or when implementing Cloudinary code:

1. **Identify the product area** from the user's question using the Sub-file Index above
2. **Fetch the relevant sub-file directly** (skip the main llms.txt unless the topic is cross-product or unclear)
3. **Analyze the sub-file** to identify which specific documentation URLs are most relevant
4. **Navigate** to those specific documentation URLs (you can make multiple calls)
5. **Use the fetched documentation** to provide a comprehensive, accurate answer or code implementation. When relevant, use in conjunction with more specialized Cloudinary skills like cloudinary-transformations. The best practices defined in the specialized skills should guide which doc instructions to use.

## Example Workflows

**Example 1: Transformation question**
- User asks: "How do I resize and crop images?"
- Topic maps to Image & Video APIs → fetch https://cloudinary.com/documentation/llms-image-and-video-apis.txt?install_source=skillspack&asset=cloudinary-docs-skill
- Identify relevant pages like "image_transformations.md" or "transformation_reference.md"
- Fetch the specific documentation and provide transformation syntax and examples or help implement the request in the user's code.

**Example 2: SDK question**
- User asks: "What's the Node.js SDK for Cloudinary?"
- Topic maps to Image & Video APIs → fetch https://cloudinary.com/documentation/llms-image-and-video-apis.txt?install_source=skillspack&asset=cloudinary-docs-skill
- Identify SDK-related pages and provide installation instructions and usage examples or help implement the request in the user's code.

**Example 3: DAM question**
- User asks: "How do I set up approval workflows for assets in the Media Library?"
- Topic maps to Cloudinary Assets (DAM) → fetch https://cloudinary.com/documentation/llms-cloudinary-assets.txt?install_source=skillspack&asset=cloudinary-docs-skill
- Identify relevant pages like "dam_admin_creative_approval_flows.md"
- Fetch the specific documentation and provide setup steps

**Example 4: MediaFlows question**
- User asks: "How do I build a PowerFlow that auto-moderates uploaded images?"
- Topic maps to MediaFlows → fetch https://cloudinary.com/documentation/llms-mediaflows.txt?install_source=skillspack&asset=cloudinary-docs-skill
- Identify relevant pages like "mediaflows_build_flow.md" or "mediaflows_moderation_powerflow.md"
- Fetch the specific documentation and provide a flow-building walkthrough

**Example 5: Integration question**
- User asks: "How do I connect Cloudinary to my WordPress site?"
- Topic maps to Integrations → fetch https://cloudinary.com/documentation/llms-integrations.txt?install_source=skillspack&asset=cloudinary-docs-skill
- Identify relevant pages like "wordpress_integration.md"
- Fetch the specific documentation and provide setup instructions

**Example 6: Ambiguous upload question**
- User asks: "How do I upload images to Cloudinary?"
- First, determine whether the user wants to upload **programmatically** (via SDK/API) or **via the Console UI** (DAM)
- If **programmatic** → fetch https://cloudinary.com/documentation/llms-image-and-video-apis.txt?install_source=skillspack&asset=cloudinary-docs-skill
  - Identify relevant pages like "image_upload.md" or "upload_api.md"
  - Retrieve those specific pages and provide an answer with code examples
- If **via the Console UI (DAM)** → fetch https://cloudinary.com/documentation/llms-cloudinary-assets.txt?install_source=skillspack&asset=cloudinary-docs-skill
  - Identify relevant pages like "dam_upload_store_assets.md" or "dam_admin_upload_presets.md"
  - Retrieve those specific pages and provide step-by-step instructions for uploading via the Media Library.
- If **unable to determine** → fetch https://cloudinary.com/documentation/llms.txt?install_source=skillspack&asset=cloudinary-docs-skill
  - Look at documentation for both Image & Video APIs and Cloudinary Assets products
  - Provide an answer covering both programmatic and UI-based upload options