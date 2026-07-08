# Environment variables

Use this when configuring `.env.local`, debugging missing Cloudinary variables, or adding TypeScript environment typings.


## Environment Variables

- ✅ **Required**: `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME` in `.env.local`. Access via `process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME` if you ever need to read it directly (most code doesn't — `next-cloudinary` reads it for you).
- ✅ **For signed uploads**: `NEXT_PUBLIC_CLOUDINARY_API_KEY` (public) and `CLOUDINARY_API_SECRET` (server only).
- ✅ Restart the dev server after any `.env*` change.
- ❌ Do not put `CLOUDINARY_API_SECRET` in `NEXT_PUBLIC_*` or any file that is sent to the browser.
- ❌ Do not commit `.env`, `.env.local`, `.env.development`, or `.env.production`. Verify they're in `.gitignore`.

### Environment Variable Typing (TypeScript)

Add a `next-env.d.ts` augmentation (or a separate `env.d.ts`) so `process.env` is typed:

```ts
// env.d.ts
declare namespace NodeJS {
  interface ProcessEnv {
    NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME: string;
    NEXT_PUBLIC_CLOUDINARY_API_KEY?: string;
    CLOUDINARY_API_SECRET?: string;
  }
}
export {};
```
