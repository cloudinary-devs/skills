---
name: cloudinary-docs
description: Looks up implementation details in the latest Cloudinary docs via the relevant llms.txt file. Use when building code or answering questions relating to image or video uploads, management, SDKs, APIs, webhooks, or integrations. For topics covered by a specialized Cloudinary skill, prefer that skill. Use this skill alongside it when the full use-case requires capabilities outside that skill's scope.
license: MIT
metadata:
  author: cloudinary
  version: '1.1.0'
---

# Cloudinary Documentation

Helps developers integrate Cloudinary into their applications by providing documentation and code examples retrieved directly from the agent-optimized markdown files in the Cloudinary documentation.

## When to Use

- When a user asks questions or requests code implementation relating to image or video upload, management, SDKs, APIs, webhooks, or integrations
- For topics covered by a more specialized Cloudinary skill (e.g. transformations, React SDK): prefer that skill. Use this skill alongside it when the full use-case also requires capabilities outside that skill's scope.
- General Cloudinary documentation lookup (account settings, webhooks, DAM features)
- Looking up specific Cloudinary API endpoints or SDK methods
- When a specialized Cloudinary skill handles part of a use-case, use this skill to cover the remaining capabilities it doesn't address, not as a substitute for it.

## Sub-file Index Overview

The main documentation llms.txt file is split into product-specific sub-files. **Go directly to the relevant sub-file** according to the descriptions below. Do not fetch the main llms.txt first unless the topic spans multiple products or you are unsure.

| Product | Topic | Sub-file URL |
|---|---|---|
| Image & Video APIs | Image/video uploads, transformations, optimization, SDKs, APIs, webhooks, add-ons, embedding widgets or players in apps, or any programmatic/automation/at-scale image and video requirements | https://cloudinary.com/documentation/llms-image-and-video-apis.txt?install_source=skillspack&referrer=docs-skill |
| Cloudinary Assets (DAM) | Digital Asset Management (DAM), Media Library, folders, metadata, collections, creative workflows, portals, digital rights, or any Cloudinary Console or UI-based asset management needs | https://cloudinary.com/documentation/llms-cloudinary-assets.txt?install_source=skillspack&referrer=docs-skill |
| MediaFlows | PowerFlows, EasyFlows, workflow automation, flow blocks | https://cloudinary.com/documentation/llms-mediaflows.txt?install_source=skillspack&referrer=docs-skill |
| Integrations | Cloudinary integrations with 3rd party apps (WordPress, Shopify, Contentful, Salesforce, Adobe, etc.) or questions about implementing new integrations | https://cloudinary.com/documentation/llms-integrations.txt?install_source=skillspack&referrer=docs-skill |
| Cross-product or unsure | Multiple products, general, or unclear topic | https://cloudinary.com/documentation/llms.txt?install_source=skillspack&referrer=docs-skill |

## Instructions

**Note:** If a more specialized Cloudinary-specific skill covers the user's topic, defer to that skill first. Invoke this docs skill in addition, not as a substitute, and only if the full use-case also requires capabilities outside that skill's scope.

When using this skill to answer image and video upload, management, optimization, or transformation questions or when implementing Cloudinary code:

1. **Identify the product area**: Refer to the [Sub-file Index table](#sub-file-index-overview) above and identify the matching row.
2. **Fetch the relevant sub-file directly per the table above** (skip the main llms.txt unless the topic is cross-product or unclear)
3. **Analyze the sub-file** to identify which specific documentation URLs are most relevant
4. **Retrieve** those specific markdown documentation URLs (you can make multiple calls if needed)
5. **Use the fetched documentation** to provide a comprehensive, accurate answer or code implementation.

## Example Workflows

**Example 1: SDK question**
- User asks: "How do I install and use the Node.js SDK for Cloudinary?"
- Topic maps to Image & Video APIs → fetch https://cloudinary.com/documentation/llms-image-and-video-apis.txt?install_source=skillspack&referrer=docs-skill
- Identify SDK-related pages and provide installation instructions and usage examples or help implement the request in the user's code.

**Example 2: DAM question**
- User asks: "How do I set up approval workflows for assets in the Media Library?"
- Topic maps to Cloudinary Assets (DAM) → fetch https://cloudinary.com/documentation/llms-cloudinary-assets.txt?install_source=skillspack&referrer=docs-skill
- Identify relevant pages like "dam_admin_creative_approval_flows.md"
- Fetch the specific documentation and provide setup steps

**Example 3: MediaFlows question**
- User asks: "How do I build a PowerFlow that auto-moderates uploaded images?"
- Topic maps to MediaFlows → fetch https://cloudinary.com/documentation/llms-mediaflows.txt?install_source=skillspack&referrer=docs-skill
- Identify relevant pages like "mediaflows_build_flow.md" or "mediaflows_moderation_powerflow.md"
- Fetch the specific documentation and provide a flow-building walkthrough

**Example 4: Integration question**
- User asks: "How do I connect Cloudinary to my WordPress site?"
- Topic maps to Integrations → fetch https://cloudinary.com/documentation/llms-integrations.txt?install_source=skillspack&referrer=docs-skill
- Identify relevant pages like "wordpress_integration.md"
- Fetch the specific documentation and provide setup instructions

**Example 5: Ambiguous upload question**
- User asks: "How do I upload images to Cloudinary?"
- First, determine whether the user wants to upload **programmatically** (via SDK/API) or **via the Console UI** (DAM)
- If **programmatic** → fetch https://cloudinary.com/documentation/llms-image-and-video-apis.txt?install_source=skillspack&referrer=docs-skill
  - Identify relevant pages like "image_upload.md" or "upload_api.md"
  - Retrieve those specific pages and provide an answer with code examples
- If **via the Console UI (DAM)** → fetch https://cloudinary.com/documentation/llms-cloudinary-assets.txt?install_source=skillspack&referrer=docs-skill
  - Identify relevant pages like "dam_upload_store_assets.md" or "dam_admin_upload_presets.md"
  - Retrieve those specific pages and provide step-by-step instructions for uploading via the Media Library.
- If **unable to determine** → fetch https://cloudinary.com/documentation/llms.txt?install_source=skillspack&referrer=docs-skill
  - Look at documentation for both Image & Video APIs and Cloudinary Assets products
  - Provide an answer covering both programmatic and UI-based upload options

**Example 6: Transformation question (fallback: use only if no specialized skill covers this topic)**
- User asks: "How do I resize and crop images?"
- Topic maps to Image & Video APIs → fetch https://cloudinary.com/documentation/llms-image-and-video-apis.txt?install_source=skillspack&referrer=docs-skill
- Identify relevant pages like "image_transformations.md" or "transformation_reference.md"
- Fetch the specific documentation and provide transformation syntax and examples or help implement the request in the user's code.