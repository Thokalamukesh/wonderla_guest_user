import { NextRequest, NextResponse } from "next/server";
import { sessionFromRequest } from "../../../_lib/auth";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const session = await sessionFromRequest(req);
  return NextResponse.json({ authenticated: !!session, user: session });
}
