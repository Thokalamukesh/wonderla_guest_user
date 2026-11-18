import { NextRequest, NextResponse } from "next/server";
import { sessionFromRequest, isSuperadmin } from "../../_lib/auth";
import { listUsers, createUser } from "../../_lib/users";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// Superadmin only: list users
export async function GET(req: NextRequest) {
  if (!isSuperadmin(await sessionFromRequest(req))) {
    return NextResponse.json({ ok: false, error: "Forbidden" }, { status: 403 });
  }
  return NextResponse.json({ ok: true, users: await listUsers() });
}

// Superadmin only: create a user (park user or another superadmin)
export async function POST(req: NextRequest) {
  if (!isSuperadmin(await sessionFromRequest(req))) {
    return NextResponse.json({ ok: false, error: "Forbidden" }, { status: 403 });
  }
  let body: { username?: string; password?: string; role?: string; parkSlug?: string; permissions?: string[] };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid request" }, { status: 400 });
  }
  const role = body.role === "superadmin" ? "superadmin" : "park";
  try {
    const user = await createUser(
      body.username || "",
      body.password || "",
      role,
      body.parkSlug,
      body.permissions
    );
    return NextResponse.json({ ok: true, user }, { status: 201 });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "Failed" }, { status: 400 });
  }
}
