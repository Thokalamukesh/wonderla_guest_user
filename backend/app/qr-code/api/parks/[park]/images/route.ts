import { randomUUID } from "crypto";
import { mkdir, writeFile } from "fs/promises";
import path from "path";
import { NextRequest, NextResponse } from "next/server";
import { canEditPark, sessionFromRequest } from "../../../../_lib/auth";
import { isVercelRuntime, putPrivateUpload } from "../../../../_lib/persistent-storage";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const extensions: Record<string, string> = { "image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp", "image/gif": ".gif" };

export async function POST(request: NextRequest, { params }: { params: Promise<{ park: string }> }) {
  const { park } = await params;
  if (!canEditPark(await sessionFromRequest(request), park)) return NextResponse.json({ ok: false, error: "Forbidden" }, { status: 403 });
  try {
    const form = await request.formData();
    const image = form.get("image");
    if (!(image instanceof File)) return NextResponse.json({ ok: false, error: "Choose an image to upload." }, { status: 400 });
    const extension = extensions[image.type];
    if (!extension) return NextResponse.json({ ok: false, error: "Use a PNG, JPG, WebP or GIF image." }, { status: 415 });
    if (image.size === 0 || image.size > 5 * 1024 * 1024) return NextResponse.json({ ok: false, error: "Image must be between 1 byte and 5 MB." }, { status: 413 });
    const filename = `${randomUUID()}${extension}`;
    if (isVercelRuntime) {
      const key = `uploads/qr-code/${park}/${filename}`;
      await putPrivateUpload(key, new Uint8Array(await image.arrayBuffer()), image.type);
      return NextResponse.json({ ok: true, url: `/qr-code/api/assets?key=${encodeURIComponent(key)}` });
    }
    const directory = path.join(process.cwd(), "public", "uploads", "qr-code", park);
    await mkdir(directory, { recursive: true });
    await writeFile(path.join(directory, filename), Buffer.from(await image.arrayBuffer()), { flag: "wx" });
    return NextResponse.json({ ok: true, url: `/uploads/qr-code/${park}/${filename}` });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not save image. Try again.";
    const status = message.includes("Vercel Blob store") ? 503 : 500;
    return NextResponse.json({ ok: false, error: message }, { status });
  }
}
