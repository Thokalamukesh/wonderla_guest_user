/**
 * DEPRECATED SHIM.
 * Park content + step definitions now live in ../_lib.
 * This file only re-exports step helpers for backward compatibility
 * with any existing imports. New code should import from ../_lib.
 */
export { steps, slugify, createDefaultParkConfig, SEED_PARKS } from "../_lib/config.data";
export type { StepKey, StepValue } from "../_lib/config.data";
export type {
  MediaItem,
  EventItem,
  WaitTimeItem,
  WaveRainItem,
  SafetyItem,
  MaintenanceItem,
  DiningOutlet,
  MenuItem,
  GuidelineItem,
  ParkMapConfig,
  ParkConfig,
  ParkSummary,
} from "../_lib/types";
