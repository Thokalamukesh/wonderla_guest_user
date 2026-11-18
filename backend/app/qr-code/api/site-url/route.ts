import { NextRequest, NextResponse } from "next/server";

export const dynamic = "force-dynamic";

/** Return the public project origin for park QR codes. Preview deployments
 * should still create codes that point to the production park pages. */
export async function GET(request: NextRequest) {
  const isVercel = process.env.VERCEL === "1" || request.headers.has("x-vercel-id");
  const productionHost = isVercel ? process.env.VERCEL_PROJECT_PRODUCTION_URL : undefined;
  if (isVercel && !productionHost) {
    return NextResponse.json({
      error: "Vercel's production domain is unavailable. Enable System Environment Variables in Project Settings, then redeploy.",
    }, { status: 503, headers: { "Cache-Control": "no-store" } });
  }
  const origin = productionHost
    ? new URL(`https://${productionHost}`).origin
    : request.nextUrl.origin;

  return NextResponse.json({ origin }, { headers: { "Cache-Control": "no-store" } });
}
