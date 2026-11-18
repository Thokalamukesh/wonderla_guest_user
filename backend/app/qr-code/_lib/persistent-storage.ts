import { del, get, list, put } from "@vercel/blob";
import { promises as fs } from "fs";
import path from "path";

export const isVercelRuntime = process.env.VERCEL === "1";
export const hasVercelBlob = Boolean(
  process.env.BLOB_READ_WRITE_TOKEN ||
  // Vercel Functions receive OIDC per request; the token is not a runtime env var.
  (process.env.BLOB_STORE_ID && (isVercelRuntime || process.env.VERCEL_OIDC_TOKEN))
);

function requireBlobStore() {
  if (!hasVercelBlob) {
    throw new Error("Connect a private Vercel Blob store to persist admin data and uploads.");
  }
}

export async function readStoredText(key: string, localPath: string): Promise<string | null> {
  if (isVercelRuntime) {
    if (!hasVercelBlob) return null;
    const result = await get(key, { access: "private", useCache: false });
    if (!result || result.statusCode !== 200 || !result.stream) return null;
    return new Response(result.stream).text();
  }

  try {
    return await fs.readFile(localPath, "utf8");
  } catch {
    return null;
  }
}

export async function writeStoredText(key: string, localPath: string, contents: string): Promise<void> {
  if (isVercelRuntime) {
    requireBlobStore();
    await put(key, contents, {
      access: "private",
      addRandomSuffix: false,
      allowOverwrite: true,
      contentType: "application/json",
      cacheControlMaxAge: 60,
    });
    return;
  }

  await fs.mkdir(path.dirname(localPath), { recursive: true });
  const temporary = `${localPath}.${process.pid}.${Date.now()}.tmp`;
  await fs.writeFile(temporary, contents, { encoding: "utf8", flag: "wx" });
  await fs.rename(temporary, localPath);
}

export async function listStoredKeys(prefix: string, localDirectory: string): Promise<string[]> {
  if (isVercelRuntime) {
    if (!hasVercelBlob) return [];
    const result = await list({ prefix });
    return result.blobs.map((blob) => blob.pathname);
  }

  try {
    return (await fs.readdir(localDirectory))
      .filter((name) => name.endsWith(".json"))
      .map((name) => path.join(localDirectory, name));
  } catch {
    return [];
  }
}

export async function deleteStoredKey(key: string, localPath: string): Promise<boolean> {
  if (isVercelRuntime) {
    if (!hasVercelBlob) return false;
    await del(key);
    return true;
  }

  try {
    await fs.unlink(localPath);
    return true;
  } catch {
    return false;
  }
}

export async function putPrivateUpload(key: string, bytes: Uint8Array, contentType: string) {
  requireBlobStore();
  return put(key, bytes, {
    access: "private",
    addRandomSuffix: false,
    contentType,
    cacheControlMaxAge: 3600,
  });
}

export async function getPrivateUpload(key: string) {
  requireBlobStore();
  return get(key, { access: "private", useCache: false });
}
