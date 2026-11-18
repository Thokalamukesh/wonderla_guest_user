import { NextRequest, NextResponse } from "next/server";
import { sessionFromRequest, isSuperadmin } from "../../../_lib/auth";
import { deleteUser, updateUserPermissions } from "../../../_lib/users";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type Ctx = { params: Promise<{ username: string }> };

// Superadmin only: delete a user
export async function DELETE(req: NextRequest, { params }: Ctx) {
  const { username } = await params;
  if (!isSuperadmin(await sessionFromRequest(req))) {
    return NextResponse.json({ ok: false, error: "Forbidden" }, { status: 403 });
  }
  try {
    const ok = await deleteUser(decodeURIComponent(username));
    if (!ok) return NextResponse.json({ ok: false, error: "Not found" }, { status: 404 });
    return NextResponse.json({ ok: true });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "Failed" }, { status: 400 });
  }
}

export async function PATCH(req: NextRequest, { params }: Ctx) {
  const { username } = await params;
  if (!isSuperadmin(await sessionFromRequest(req))) return NextResponse.json({ ok: false, error: "Forbidden" }, { status: 403 });
  try {
    const body = await req.json();
    if (!Array.isArray(body.permissions)) return NextResponse.json({ ok: false, error: "Choose at least one access section" }, { status: 400 });
    const user = await updateUserPermissions(decodeURIComponent(username), body.permissions);
    if (!user) return NextResponse.json({ ok: false, error: "Not found" }, { status: 404 });
    return NextResponse.json({ ok: true, user });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "Failed" }, { status: 400 });
  }
}
