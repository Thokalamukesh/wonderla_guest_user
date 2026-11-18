/* ============================================================
   User store (server-only). One JSON file: data/qr-code/users.json
   Roles:
     - superadmin : manage all parks + create/delete users
     - park       : may edit only their assigned park's content
   Passwords are salted + scrypt-hashed. The env admin account is
   always honored as a bootstrap superadmin so you can't lock
   yourself out.
============================================================ */

import path from "path";
import crypto from "crypto";
import { DATA_DIR } from "./paths";
import { hasVercelBlob, isVercelRuntime, readStoredText, writeStoredText } from "./persistent-storage";
import { EDIT_SECTIONS, type EditSection, type Role, type Session } from "./auth";

const USERS_FILE = path.join(DATA_DIR, "users.json");

interface StoredUser {
  username: string;
  salt: string;
  hash: string;
  role: Role;
  parkSlug?: string;
  permissions?: string[];
  createdAt: string;
}

export interface PublicUser {
  username: string;
  role: Role;
  parkSlug?: string;
  permissions: string[];
  createdAt: string;
}

function hashPassword(password: string, salt?: string): { salt: string; hash: string } {
  const s = salt || crypto.randomBytes(16).toString("hex");
  const hash = crypto.scryptSync(password, s, 64).toString("hex");
  return { salt: s, hash };
}

function verifyPassword(password: string, salt: string, hash: string): boolean {
  const h = crypto.scryptSync(password, salt, 64).toString("hex");
  const a = Buffer.from(h);
  const b = Buffer.from(hash);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function makeUser(
  username: string,
  password: string,
  role: Role,
  parkSlug?: string,
  permissions?: string[]
): StoredUser {
  const { salt, hash } = hashPassword(password);
  return {
    username,
    salt,
    hash,
    role,
    parkSlug,
    permissions: role === "superadmin" ? ["all"] : (permissions ?? ["all"]),
    createdAt: new Date().toISOString(),
  };
}

async function readAll(): Promise<StoredUser[]> {
  const raw = await readStoredText("qr-code/users.json", USERS_FILE);
  if (raw) {
    const arr = JSON.parse(raw);
    if (Array.isArray(arr) && arr.length) return arr as StoredUser[];
  }
  // Seed one superadmin from env on first run.
  const u = process.env.QR_ADMIN_USERNAME || "admin";
  const p = process.env.QR_ADMIN_PASSWORD || "wonderla@admin";
  const seeded = [makeUser(u, p, "superadmin")];
  if (!isVercelRuntime || hasVercelBlob) {
    await writeStoredText("qr-code/users.json", USERS_FILE, JSON.stringify(seeded, null, 2));
  }
  return seeded;
}

async function writeAll(users: StoredUser[]): Promise<void> {
  await writeStoredText("qr-code/users.json", USERS_FILE, JSON.stringify(users, null, 2));
}

function toPublic(u: StoredUser): PublicUser {
  return {
    username: u.username,
    role: u.role,
    parkSlug: u.parkSlug,
    permissions: u.permissions ?? ["all"],
    createdAt: u.createdAt,
  };
}

function normalizePermissions(role: Role, permissions?: string[]): string[] {
  if (role === "superadmin") return ["all"];
  if (permissions === undefined) return ["all"];
  if (!Array.isArray(permissions)) throw new Error("Choose at least one access section");
  if (permissions.includes("all")) return ["all"];
  const valid = [...new Set(permissions)].filter((value): value is EditSection =>
    (EDIT_SECTIONS as readonly string[]).includes(value),
  );
  if (valid.length === 0) throw new Error("Choose at least one access section");
  return valid;
}

/** Validate credentials; env admin always works as bootstrap superadmin. */
export async function verifyCredentials(
  username: string,
  password: string
): Promise<Session | null> {
  // Remove accidental spaces copied into the username or deployment secret UI.
  username = username.trim();
  const envU = (process.env.QR_ADMIN_USERNAME || "admin").trim();
  const envP = (process.env.QR_ADMIN_PASSWORD || "wonderla@admin").trim();
  if (username === envU && password === envP) {
    return { username, role: "superadmin", permissions: ["all"] };
  }
  const users = await readAll();
  const found = users.find((u) => u.username === username);
  if (!found) return null;
  if (!verifyPassword(password, found.salt, found.hash)) return null;
  const publicUser = toPublic(found);
  return {
    username: publicUser.username,
    role: publicUser.role,
    parkSlug: publicUser.parkSlug,
    permissions: publicUser.permissions,
  };
}

export async function getSessionUser(username: string): Promise<Session | null> {
  const found = (await readAll()).find((user) => user.username === username);
  if (!found) return null;
  const publicUser = toPublic(found);
  return {
    username: publicUser.username,
    role: publicUser.role,
    parkSlug: publicUser.parkSlug,
    permissions: publicUser.permissions,
  };
}

export async function listUsers(): Promise<PublicUser[]> {
  const users = await readAll();
  return users.map(toPublic).sort((a, b) => a.username.localeCompare(b.username));
}

export async function createUser(
  username: string,
  password: string,
  role: Role,
  parkSlug?: string,
  permissions?: string[]
): Promise<PublicUser> {
  username = username.trim();
  if (!username) throw new Error("Username is required");
  if (!password || password.length < 6)
    throw new Error("Password must be at least 6 characters");
  if (role === "park" && !parkSlug) throw new Error("A park must be selected for a park user");
  const normalizedPermissions = normalizePermissions(role, permissions);

  const users = await readAll();
  if (users.some((u) => u.username === username))
    throw new Error(`User "${username}" already exists`);

  const user = makeUser(
    username,
    password,
    role,
    role === "park" ? parkSlug : undefined,
    normalizedPermissions,
  );
  users.push(user);
  await writeAll(users);
  return toPublic(user);
}

export async function updateUserPermissions(
  username: string,
  permissions: string[],
): Promise<PublicUser | null> {
  const users = await readAll();
  const target = users.find((user) => user.username === username);
  if (!target) return null;
  if (target.role === "superadmin") {
    throw new Error("Superadmins always have full access");
  }
  target.permissions = normalizePermissions(target.role, permissions);
  await writeAll(users);
  return toPublic(target);
}

export async function deleteUser(username: string): Promise<boolean> {
  const users = await readAll();
  const target = users.find((u) => u.username === username);
  if (!target) return false;
  // Never remove the last superadmin.
  if (
    target.role === "superadmin" &&
    users.filter((u) => u.role === "superadmin").length <= 1
  ) {
    throw new Error("Cannot delete the only superadmin");
  }
  await writeAll(users.filter((u) => u.username !== username));
  return true;
}
