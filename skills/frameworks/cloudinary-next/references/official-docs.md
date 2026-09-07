# Official documentation

- **Next Cloudinary docs (start here)**: https://next.cloudinary.dev
- **Installation**: https://next.cloudinary.dev/installation
- **CldImage configuration**: https://next.cloudinary.dev/cldimage/configuration
- **CldImage examples**: https://next.cloudinary.dev/cldimage/examples
- **CldVideoPlayer configuration**: https://next.cloudinary.dev/cldvideoplayer/configuration
- **CldUploadWidget configuration**: https://next.cloudinary.dev/clduploadwidget/configuration
- **CldUploadWidget signed uploads**: https://next.cloudinary.dev/clduploadwidget/signed-uploads
- **CldOgImage / getCldOgImageUrl**: https://next.cloudinary.dev/cldogimage/basic-usage
- **Responsive images guide**: https://next.cloudinary.dev/guides/responsive-images
- **Image optimization guide**: https://next.cloudinary.dev/guides/image-optimization
- **Social media card guide**: https://next.cloudinary.dev/guides/social-media-card
- **Uploading images & videos guide**: https://next.cloudinary.dev/guides/uploading-images-and-videos
- **Cloudinary transformation reference**: https://cloudinary.com/documentation/transformation_reference
- **Cloudinary transformation rules**: https://cloudinary.com/documentation/cloudinary_transformation_rules
- **Cloudinary Node.js SDK (server-side)** — use **v2**: `import { v2 as cloudinary } from 'cloudinary'`. Do not use v1. https://cloudinary.com/documentation/node_integration
- **Upload assets in Next.js (tutorial)**: https://cloudinary.com/documentation/upload_assets_in_nextjs_tutorial
- **Upload widget reference (parameters & events)**: https://cloudinary.com/documentation/upload_widget_reference
- Always consult the official transformation reference when generating transformations; use only officially supported parameters.

**Golden rule for next-cloudinary:** Use **only** the prop names and shapes documented in the **CldImage / CldVideoPlayer / CldUploadWidget configuration** pages and in the **"CldImage prop reference"** and **"Overlay/text shape"** sections of these rules. Do not derive prop names from the URL transformation reference (e.g., the URL param is `e_background_removal` but the prop is `removeBackground`). Do not invent prop names.

---
