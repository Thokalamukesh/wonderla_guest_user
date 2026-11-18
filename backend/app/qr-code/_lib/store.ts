/* ============================================================
   Server-side JSON file store for park configurations.
   - One file per park: data/qr-code/parks/<slug>.json
   - Auto-seeds the initial 5 parks on first access.
   - All functions are server-only (use node fs). Never import
     this into a client component.
============================================================ */

import path from "path";
import { PARKS_DIR } from "./paths";
import { createBlankParkConfig, createDefaultParkConfig, SEED_PARKS, slugify } from "./config.data";
import { deleteStoredKey, hasVercelBlob, isVercelRuntime, listStoredKeys, readStoredText, writeStoredText } from "./persistent-storage";
import type { ParkConfig, ParkSummary } from "./types";

async function ensureDir() {
  if (!isVercelRuntime) await (await import("fs/promises")).mkdir(PARKS_DIR, { recursive: true });
}

function fileFor(slug: string) {
  return path.join(PARKS_DIR, `${slug}.json`);
}

async function exists(p: string): Promise<boolean> {
  return Boolean(await readStoredText(`qr-code/parks/${path.basename(p)}`, p));
}

/** Seed the initial parks exactly once (only if the folder is empty). */
async function ensureSeeded() {
  await ensureDir();
  const entries = await listStoredKeys("qr-code/parks/", PARKS_DIR);
  if (entries.length > 0) return;
  if (isVercelRuntime && !hasVercelBlob) return;
  await Promise.all(
    SEED_PARKS.map((p) =>
      writeStoredText(
        `qr-code/parks/${p.slug}.json`,
        fileFor(p.slug),
        JSON.stringify(createDefaultParkConfig(p.name, p.location, p.slug), null, 2)
      )
    )
  );
}

export async function listParks(): Promise<ParkSummary[]> {
  await ensureSeeded();
  const files = await listStoredKeys("qr-code/parks/", PARKS_DIR);
  if (isVercelRuntime && !hasVercelBlob) {
    return SEED_PARKS.map((seed) => {
      const config = createDefaultParkConfig(seed.name, seed.location, seed.slug);
      return { slug: config.slug, name: config.name, location: config.location, active: config.active, updatedAt: config.updatedAt };
    }).sort((a, b) => a.name.localeCompare(b.name));
  }
  const parks = (await Promise.all(files.map(async (file): Promise<ParkSummary | null> => {
    try {
      const raw = await readStoredText(isVercelRuntime ? file : `qr-code/parks/${path.basename(file)}`, isVercelRuntime ? fileFor(path.basename(file)) : file);
      if (!raw) return null;
      const cfg = JSON.parse(raw) as ParkConfig;
      return {
        slug: cfg.slug,
        name: cfg.name,
        location: cfg.location,
        active: cfg.active,
        updatedAt: cfg.updatedAt,
      };
    } catch {
      /* skip malformed file */
      return null;
    }
  }))).filter((park): park is ParkSummary => park !== null);
  return parks.sort((a, b) => a.name.localeCompare(b.name));
}

export async function getPark(slug: string): Promise<ParkConfig | null> {
  await ensureSeeded();
  const raw = await readStoredText(`qr-code/parks/${slug}.json`, fileFor(slug));
  if (raw) return JSON.parse(raw) as ParkConfig;
  if (isVercelRuntime && !hasVercelBlob) {
    const seed = SEED_PARKS.find((park) => park.slug === slug);
    return seed ? createDefaultParkConfig(seed.name, seed.location, seed.slug) : null;
  }
  return null;
}

export async function savePark(config: ParkConfig): Promise<ParkConfig> {
  if (!config.slug) throw new Error("Park slug is required");
  const next: ParkConfig = { ...config, updatedAt: new Date().toISOString() };
  await writeStoredText(`qr-code/parks/${next.slug}.json`, fileFor(next.slug), JSON.stringify(next, null, 2));
  return next;
}

export async function createPark(
  name: string,
  location: string,
  rawSlug?: string
): Promise<ParkConfig> {
  await ensureSeeded();
  const slug = slugify(rawSlug || name);
  if (!slug) throw new Error("A valid name or slug is required");
  if (await getPark(slug) || await exists(fileFor(slug))) {
    throw new Error(`A park with slug "${slug}" already exists`);
  }
  const cfg = createBlankParkConfig(name, location, slug);
  return savePark(cfg);
}

export async function deletePark(slug: string): Promise<boolean> {
  const p = fileFor(slug);
  return deleteStoredKey(`qr-code/parks/${slug}.json`, p);
}
