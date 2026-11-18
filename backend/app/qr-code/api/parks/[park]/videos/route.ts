import { randomUUID } from "crypto";
import { mkdir, writeFile } from "fs/promises";
import path from "path";
import { NextRequest, NextResponse } from "next/server";
import { canEditPark, sessionFromRequest } from "../../../../_lib/auth";
import { isVercelRuntime, putPrivateUpload } from "../../../../_lib/persistent-storage";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const MAX_VIDEO_BYTES = 50 * 1024 * 1024;
const extensions: Record<string, string> = {
  "video/mp4": ".mp4",
  "video/webm": ".webm",
  "video/quicktime": ".mov",
};

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ park: string }> },
) {
  const { park } = await params;
  if (!/^[a-z0-9-]+$/.test(park)) {
    return NextResponse.json({ ok: false, error: "Invalid park." }, { status: 400 });
  }
  if (!canEditPark(await sessionFromRequest(request), park)) {
    return NextResponse.json({ ok: false, error: "Forbidden" }, { status: 403 });
  }

  try {
    const form = await request.formData();
    const video = form.get("video");
    if (!(video instanceof File)) {
      return NextResponse.json({ ok: false, error: "Choose a video to upload." }, { status: 400 });
    }
    const extension = extensions[video.type];
    if (!extension) {
      return NextResponse.json({ ok: false, error: "Use an MP4, WebM, or MOV video." }, { status: 415 });
    }
    if (video.size === 0 || video.size > MAX_VIDEO_BYTES) {
      return NextResponse.json({ ok: false, error: "Video must be between 1 byte and 50 MB." }, { status: 413 });
    }

    const filename = `${randomUUID()}${extension}`;
    const bytes = new Uint8Array(await video.arrayBuffer());
    if (isVercelRuntime) {
      const key = `uploads/qr-code/${park}/${filename}`;
      await putPrivateUpload(key, bytes, video.type);
      return NextResponse.json({ ok: true, url: `/qr-code/api/assets?key=${encodeURIComponent(key)}` });
    }

    const directory = path.join(process.cwd(), "public", "uploads", "qr-code", park);
    await mkdir(directory, { recursive: true });
    await writeFile(path.join(directory, filename), Buffer.from(bytes), { flag: "wx" });
    return NextResponse.json({ ok: true, url: `/uploads/qr-code/${park}/${filename}` });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not save video. Try again.";
    const status = message.includes("Vercel Blob store") ? 503 : 500;
    return NextResponse.json({ ok: false, error: message }, { status });
  }
}
