/* ============================================================
   Session tokens. A signed, httpOnly cookie carries WHO the
   caller is (username + role + parkSlug), so API routes can
   authorize per-park. Credential checking lives in users.ts.
============================================================ */

import crypto from "crypto";
import type { NextRequest } from "next/server";
import { getSessionUser } from "./users";

export const SESSION_COOKIE = "qr_admin_session";
const MAX_AGE_SECONDS = 60 * 60 * 8; // 8 hours

export type Role = "superadmin" | "park";

export const EDIT_SECTIONS = [
  "Park overview",
  "Rides",
  "Events",
  "Dining & menus",
  "Live wait times",
  "Wave pool & rain dance",
  "Safety & hygiene",
  "Maintenance log",
  "Ride guidelines",
  "Park map & places",
] as const;

export type EditSection = (typeof EDIT_SECTIONS)[number];

export interface Session {
  username: string;
  role: Role;
  parkSlug?: string; // set for role === "park"
  permissions: string[];
}

function secret(): string {
  return process.env.QR_ADMIN_SECRET || "dev-insecure-secret-change-me";
}

function sign(payload: string): string {
  return crypto.createHmac("sha256", secret()).update(payload).digest("hex");
}

function safeEq(a: string, b: string): boolean {
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  return ab.length === bb.length && crypto.timingSafeEqual(ab, bb);
}

/** Build a signed token encoding the session + its expiry. */
export function createToken(session: Session): { token: string; maxAge: number } {
  const body = Buffer.from(
    JSON.stringify({ ...session, exp: Date.now() + MAX_AGE_SECONDS * 1000 })
  ).toString("base64url");
  return { token: `${body}.${sign(body)}`, maxAge: MAX_AGE_SECONDS };
}

/** Verify signature + expiry and return the session, or null. */
export function readToken(token?: string | null): Session | null {
  if (!token) return null;
  const [body, sig] = token.split(".");
  if (!body || !sig || !safeEq(sign(body), sig)) return null;
  try {
    const data = JSON.parse(Buffer.from(body, "base64url").toString("utf8"));
    if (typeof data.exp !== "number" || data.exp < Date.now()) return null;
    if (!data.username || !data.role) return null;
    return {
      username: data.username,
      role: data.role,
      parkSlug: data.parkSlug,
      permissions: Array.isArray(data.permissions) ? data.permissions : ["all"],
    };
  } catch {
    return null;
  }
}

/** Convenience: read the session off a request's cookie. */
export async function sessionFromRequest(req: NextRequest): Promise<Session | null> {
  const tokenSession = readToken(req.cookies.get(SESSION_COOKIE)?.value);
  if (!tokenSession) return null;

  const envUsername = (process.env.QR_ADMIN_USERNAME || "admin").trim();
  if (tokenSession.role === "superadmin" && tokenSession.username === envUsername) {
    return tokenSession;
  }

  // Resolve access from the current user record on every request so permission
  // changes and deleted accounts take effect immediately, even for old cookies.
  return getSessionUser(tokenSession.username);
}

export function isSuperadmin(s: Session | null): boolean {
  return !!s && s.role === "superadmin";
}

/** True if the session may edit the given park. */
export function canEditPark(s: Session | null, slug: string): boolean {
  if (!s) return false;
  if (s.role === "superadmin") return true;
  return s.role === "park" && s.parkSlug === slug;
}

export function canEditSection(s: Session | null, section: EditSection): boolean {
  if (!s || s.role !== "park") return s?.role === "superadmin";
  return s.permissions.includes("all") || s.permissions.includes(section);
}

export function canUploadParkImage(s: Session | null): boolean {
  return !!s && (s.role === "superadmin" || s.permissions.includes("all") || s.permissions.length > 0);
}
