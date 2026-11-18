import { NextRequest, NextResponse } from "next/server";
import { getPrivateUpload } from "../../_lib/persistent-storage";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const key = request.nextUrl.searchParams.get("key") || "";
  if (!/^uploads\/qr-code\/[a-z0-9-]+\/[a-f0-9-]+\.(?:jpg|png|webp|gif)$/i.test(key)) {
    return new NextResponse("Not found", { status: 404 });
  }

  try {
    const blob = await getPrivateUpload(key);
    if (!blob || blob.statusCode !== 200 || !blob.stream) {
      return new NextResponse("Not found", { status: 404 });
    }
    return new NextResponse(blob.stream, {
      headers: {
        "Content-Type": blob.blob.contentType || "application/octet-stream",
        "Cache-Control": "public, max-age=3600",
        "X-Content-Type-Options": "nosniff",
      },
    });
  } catch {
    return NextResponse.json({ error: "Image storage is not configured." }, { status: 503 });
  }
}
