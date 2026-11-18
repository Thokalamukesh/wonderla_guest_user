import { NextRequest, NextResponse } from "next/server";
import { createToken, SESSION_COOKIE } from "../../../_lib/auth";
import { verifyCredentials } from "../../../_lib/users";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(req: NextRequest) {
  if (process.env.VERCEL === "1") {
    const missing = ["QR_ADMIN_USERNAME", "QR_ADMIN_PASSWORD", "QR_ADMIN_SECRET"]
      .filter((name) => !process.env[name]?.trim());
    if (missing.length) {
      return NextResponse.json({
        ok: false,
        error: `Admin login is not configured on Vercel. Add ${missing.join(", ")} in Project Settings → Environment Variables, then redeploy.`,
      }, { status: 503 });
    }
  }

  let body: { username?: string; password?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid request" }, { status: 400 });
  }
  const session = await verifyCredentials(body.username || "", body.password || "");
  if (!session) {
    return NextResponse.json({ ok: false, error: "Invalid credentials" }, { status: 401 });
  }
  const { token, maxAge } = createToken(session);
  const res = NextResponse.json({ ok: true, user: session });
  res.cookies.set(SESSION_COOKIE, token, {
    httpOnly: true,
    // Flutter is hosted on a separate Vercel origin, so its credentialed API
    // requests need a cross-site cookie in production.
    sameSite: process.env.NODE_ENV === "production" ? "none" : "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge,
  });
  return res;
}
