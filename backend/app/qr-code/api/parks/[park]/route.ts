import { NextRequest, NextResponse } from "next/server";
import { sessionFromRequest, isSuperadmin, canEditPark, canEditSection, EDIT_SECTIONS } from "../../../_lib/auth";
import { getPark, savePark, deletePark } from "../../../_lib/store";
import type { ParkConfig } from "../../../_lib/types";
import { isDeepStrictEqual } from "node:util";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type Ctx = { params: Promise<{ park: string }> };

// Public: read one park's full config
export async function GET(_req: NextRequest, { params }: Ctx) {
  const { park } = await params;
  const cfg = await getPark(park);
  if (!cfg) return NextResponse.json({ ok: false, error: "Not found" }, { status: 404 });
  return NextResponse.json({ ok: true, config: cfg }, { headers: { "Cache-Control": "no-store, max-age=0" } });
}

// Superadmin (any park) or park user (own park): update config
export async function PUT(req: NextRequest, { params }: Ctx) {
  const { park } = await params;
  const session = await sessionFromRequest(req);
  if (!canEditPark(session, park)) {
    return NextResponse.json({ ok: false, error: "Forbidden" }, { status: 403 });
  }
  const existing = await getPark(park);
  if (!existing) return NextResponse.json({ ok: false, error: "Not found" }, { status: 404 });

  let body: Partial<ParkConfig>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid request" }, { status: 400 });
  }

  // slug is always immutable. Park users may not flip the active flag;
  // only a superadmin controls whether a park is published.
  const merged: ParkConfig = { ...existing, ...body, slug: existing.slug };
  if (!isSuperadmin(session)) merged.active = existing.active;

  if (!isSuperadmin(session)) {
    const sectionFields: Record<(typeof EDIT_SECTIONS)[number], (keyof ParkConfig)[]> = {
      "Park overview": ["name", "location", "logoUrl", "heroImageUrl", "landingIcons"],
      "Rides": ["rides"], "Events": ["events"], "Dining & menus": ["dining"],
      "Live wait times": ["liveWaitTimes"], "Wave pool & rain dance": ["waveRainDance"],
      "Safety & hygiene": ["safetyHygiene"], "Maintenance log": ["maintenanceLog"],
      "Ride guidelines": ["rideGuidelines"], "Park map & places": ["parkMap"],
    };
    const allowed = new Set<keyof ParkConfig>(
      EDIT_SECTIONS.filter((section) => canEditSection(session, section)).flatMap((section) => sectionFields[section]),
    );
    const protectedKeys: (keyof ParkConfig)[] = ["name", "location", "logoUrl", "heroImageUrl", "landingIcons", "rides", "events", "dining", "liveWaitTimes", "waveRainDance", "safetyHygiene", "maintenanceLog", "rideGuidelines", "parkMap"];
    const forbidden = protectedKeys.filter((key) => !allowed.has(key) && Object.hasOwn(body, key) && !isDeepStrictEqual(body[key], existing[key]));
    if (forbidden.length) return NextResponse.json({ ok: false, error: "You do not have access to edit these sections." }, { status: 403 });
  }

  try {
    const saved = await savePark(merged);
    return NextResponse.json({ ok: true, config: saved });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not save park changes.";
    return NextResponse.json({ ok: false, error: message }, { status: 503 });
  }
}

// Superadmin only: delete a park
export async function DELETE(req: NextRequest, { params }: Ctx) {
  const { park } = await params;
  if (!isSuperadmin(await sessionFromRequest(req))) {
    return NextResponse.json({ ok: false, error: "Forbidden" }, { status: 403 });
  }
  const ok = await deletePark(park);
  if (!ok) return NextResponse.json({ ok: false, error: "Not found" }, { status: 404 });
  return NextResponse.json({ ok: true });
}
