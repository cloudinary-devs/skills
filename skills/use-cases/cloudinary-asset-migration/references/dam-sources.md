# Getting assets out of another DAM

These traps come from Cloudinary Professional Services' migration projects, not
from each vendor's documentation. Treat them as known risks to check for, and
confirm the specifics against the source system in front of you.

The rules in SKILL.md apply to every DAM: get the originals, validate the
export before uploading, and check every source URL is reachable first.

## Adobe Experience Manager and Scene7 (Dynamic Media)

- The metadata export usually has to come through Adobe, which can be slow.
  Ask for it early.
- Scene7 delivery URLs return processed images by default. Request full-size,
  full-quality files with `scl=1&qlt=100`.
- To keep transparency, add `fmt=png-alpha`. It always returns a PNG.
- Video and GIF files come from the `/is/content` path, not `/is/image`.
- An "Illegal Image Size" error means the image is over Scene7's 4000-pixel
  delivery limit. Requesting it within the limit with `wid` and `hei` works but
  downsizes it, so prefer the original from the AEM repository for these.
- Image sets and spin sets list their members in order. Look the members up
  and keep the order, for example in a metadata field.
- Incrementally published assets can be inconsistent until a full publish.

## Canto

- The export merges an asset that sits in several folders into one row. Keep
  one row per file: pick a primary folder for its `asset_folder`, and record the
  other folders as tags or metadata.
- Many apparent duplicates are links to the same file. Migrate the file once.
- Check the date formats in the export.

## Cumulus

- Some records have no file attached. Split the export into records with a
  file and records without one, and report the second set rather than failing
  on it.
- Very large files (around 2.5 GB) have timed out on upload while still
  completing on Cloudinary. Wait before retrying them, with `overwrite: false`.

## Acquia DAM (Widen)

- Download links in an export can be dead. Check every link before the run.

## Dropbox, Box, Google Drive, and SharePoint

- Share links aren't enough for a bulk upload. Copy the files to an S3, Google
  Cloud Storage, or Azure bucket (for example with `rclone`), or download them
  and upload with the Cloudinary CLI.
- For Dropbox with `cld sync`, the files must be fully downloaded by the
  Dropbox desktop app. Online-only files aren't synced.
