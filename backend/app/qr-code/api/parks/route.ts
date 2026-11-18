import { NextRequest, NextResponse } from "next/server";
import { sessionFromRequest, isSuperadmin } from "../../_lib/auth";
import { listParks, createPark } from "../../_lib/store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// Public: list all parks (summaries)
export async function GET() {
  return NextResponse.json({ parks: await listParks() });
}

// Superadmin only: create a new park
export async function POST(req: NextRequest) {
  if (!isSuperadmin(await sessionFromRequest(req))) {
    return NextResponse.json({ ok: false, error: "Forbidden" }, { status: 403 });
  }
  let body: { name?: string; location?: string; slug?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid request" }, { status: 400 });
  }
  const name = (body.name || "").trim();
  if (!name) return NextResponse.json({ ok: false, error: "Park name is required" }, { status: 400 });
  try {
    const park = await createPark(name, (body.location || "").trim(), body.slug);
    return NextResponse.json({ ok: true, park }, { status: 201 });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "Failed" }, { status: 409 });
  }
}
