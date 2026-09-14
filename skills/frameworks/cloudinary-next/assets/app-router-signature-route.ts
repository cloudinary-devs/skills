import { v2 as cloudinary } from 'cloudinary';

export const runtime = 'nodejs';

type ParamsToSign = Record<string, string | number | boolean | undefined>;

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

export async function POST(request: Request) {
  const body = (await request.json()) as { paramsToSign?: ParamsToSign };

  if (!body.paramsToSign || typeof body.paramsToSign !== 'object') {
    return Response.json({ error: 'Missing paramsToSign' }, { status: 400 });
  }

  const signature = cloudinary.utils.api_sign_request(
    body.paramsToSign,
    requiredEnv('CLOUDINARY_API_SECRET'),
  );

  // The upload widget expects this exact field name.
  return Response.json({ signature });
}
