'use server';

import { v2 as cloudinary, type UploadApiResponse } from 'cloudinary';

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

export async function uploadImage(formData: FormData): Promise<{ publicId: string; url: string }> {
  const file = formData.get('file');
  if (!(file instanceof File)) throw new Error('No file provided');

  const arrayBuffer = await file.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);

  const result = await new Promise<UploadApiResponse>((resolve, reject) => {
    cloudinary.uploader
      .upload_stream({ folder: 'user-uploads', resource_type: 'auto' }, (error, response) => {
        if (error) return reject(error);
        if (!response) return reject(new Error('Cloudinary upload returned no response'));
        resolve(response);
      })
      .end(buffer);
  });

  return { publicId: result.public_id, url: result.secure_url };
}
