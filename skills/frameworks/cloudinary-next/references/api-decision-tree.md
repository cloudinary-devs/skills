# API decision tree

Use this first when the user is unsure which Cloudinary component, helper, or SDK API to use.


## Which Cloudinary API do I use? (decision tree)

This is the single biggest source of confusion in Next.js + Cloudinary. **Pick the right tool, then the rest is mechanical.**

| You want to… | Use this | Where it runs |
| --- | --- | --- |
| Render an `<img>` of a Cloudinary asset in JSX | **`CldImage`** (`next-cloudinary`) | v7: Server or Client Component (Client if you pass handlers like `onLoad`). v6: Client Component only |
| Get a Cloudinary image URL as a string (for `<meta>`, `<link>`, an API response, an OG image, etc.) | **`getCldImageUrl`** / **`getCldOgImageUrl`** (`next-cloudinary`) | Anywhere — server, client, route handlers, `generateMetadata` |
| Embed a video player UI | **`CldVideoPlayer`** (`next-cloudinary`) | v7: Server Component OK without event handlers or refs; Client Component otherwise. v6: Client Component only |
| Let the user upload from the browser | **`CldUploadWidget`** or **`CldUploadButton`** (`next-cloudinary`) | Client Component for `CldUploadWidget` (its render-function child) and for any `onSuccess`-style callback. v7: `CldUploadButton` with no callbacks, or with Server Actions in `*Action` props, can render from a Server Component |
| Generate an OG/social image | App Router → **`getCldOgImageUrl`** in `generateMetadata`. Pages Router → **`CldOgImage`** in the page | Server (App) / Pages Head |
| Upload a file **from your server** (e.g. a Server Action receiving a `FormData`) | **`cloudinary.uploader.upload`** / **`upload_stream`** (Node SDK v2, `cloudinary`) | Server only (`"use server"` action or route handler) |
| Delete an asset | **`cloudinary.uploader.destroy`** (Node SDK v2) | Server only |
| Sign upload widget params on the server | **`cloudinary.utils.api_sign_request`** (Node SDK v2) | Route handler (`/api/sign-cloudinary-params`) |
| List / search assets, manage tags, etc. | **Cloudinary Admin API** via Node SDK v2 (`cloudinary.api.*`) | Server only |

**Common confusion to flush out before writing code:**
- ❌ "Should I use `cloudinary.uploader.upload` or `cloudinary.image` or `cloudinary.url`?" → They do **different** things. `cloudinary.uploader.upload` (Node SDK, server) **uploads** a file. `cloudinary.url()` / `cloudinary.image()` (Node SDK, server) build a **URL/HTML tag** from a public ID — for that job, prefer **`getCldImageUrl`** or **`<CldImage>`** in Next.js. They are not interchangeable.
- ❌ Do **not** call `cloudinary.uploader.upload` from a Client Component or browser code — it requires `api_secret`, which must never reach the browser.
- ❌ Do **not** pass functions (event handlers, refs, the `CldUploadWidget` render function) from a Server Component — Next.js throws `Functions cannot be passed directly to Client Components` or `Event handlers cannot be passed to Client Component props`. Put that code in a file with `"use client"`. On v6, every `next-cloudinary` component must be in a Client Component.
- ✅ For "show an image with transformations" the answer is almost always **`<CldImage>`**. For "I just need the URL string" the answer is **`getCldImageUrl`**.
