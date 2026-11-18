import { NextRequest, NextResponse } from "next/server";
import path from "path";
import { isSuperadmin, sessionFromRequest } from "../../_lib/auth";
import { readStoredText, writeStoredText } from "../../_lib/persistent-storage";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const settingsFile = path.join(process.cwd(), "data", "qr-code", "map-settings.json");
const settingsKey = "qr-code/map-settings.json";

async function getMapKey() {
  const raw = await readStoredText(settingsKey, settingsFile);
  if (raw) {
    try {
      const stored = JSON.parse(raw) as { googleMapsApiKey?: string };
      if (stored.googleMapsApiKey?.trim()) return stored.googleMapsApiKey.trim();
    } catch {
      // Fall back to the deployment environment variable if saved data is invalid.
    }
  }
  return process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || "";
}

// Public map clients need the browser key to load Google Maps. Restrict the key by HTTP referrer in Google Cloud.
export async function GET() {
  return NextResponse.json({ apiKey: await getMapKey() }, { headers: { "Cache-Control": "no-store" } });
}

export async function PUT(req: NextRequest) {
  if (!isSuperadmin(await sessionFromRequest(req))) {
    return NextResponse.json({ ok: false, error: "Only a superadmin can update map settings." }, { status: 403 });
  }

  let body: { apiKey?: unknown };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid request." }, { status: 400 });
  }

  const apiKey = typeof body.apiKey === "string" ? body.apiKey.trim() : "";
  if (apiKey.length > 512) {
    return NextResponse.json({ ok: false, error: "The API key is too long." }, { status: 400 });
  }

  try {
    await writeStoredText(settingsKey, settingsFile, JSON.stringify({ googleMapsApiKey: apiKey }));
    return NextResponse.json({ ok: true, configured: Boolean(apiKey) });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not save map settings.";
    return NextResponse.json({ ok: false, error: message }, { status: 503 });
  }
}
