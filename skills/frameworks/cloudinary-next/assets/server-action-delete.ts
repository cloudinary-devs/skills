'use server';

import { v2 as cloudinary } from 'cloudinary';

type ResourceType = 'image' | 'video' | 'raw';

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

cloudinary.config({
  cloud_name: requiredEnv('NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME'),
  api_key: requiredEnv('NEXT_PUBLIC_CLOUDINARY_API_KEY'),
  api_secret: requiredEnv('CLOUDINARY_API_SECRET'),
});

export async function deleteAsset(
  publicId: string,
  resourceType: ResourceType = 'image',
): Promise<{ result: string }> {
  if (!publicId) throw new Error('Missing publicId');

  const result = await cloudinary.uploader.destroy(publicId, {
    resource_type: resourceType,
    invalidate: true,
  });

  return { result: result.result };
}
