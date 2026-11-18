/* ============================================================
   Shared domain types for the Wonderla QR-code experience.
   Every park stores ONE ParkConfig object (see store.ts).
   New parks can be added at any time via the admin panel,
   so nothing here hardcodes the list of parks.
============================================================ */

export interface MediaItem {
  img: string; // image URL ("" => yellow placeholder in UI)
  title: string;
  description: string;
  tags?: string[]; // short category chips, e.g. ["Space Theme", "4K Clarity"]
  kioskBookingEnabled?: boolean;
}

export interface EventItem extends MediaItem {
  time: string; // e.g. "07:30 PM"
}

export interface WaitTimeItem extends MediaItem {
  time: number; // wait in minutes
}

export interface WaveRainItem {
  img: string;
  title: string;
  timeSlot: string[]; // e.g. ["12:00 PM", "01:00 PM"]
  rideDuration: number; // minutes each
}

export interface SafetyItem {
  img: string;
  title: string;
  description: string;
}

export interface MaintenanceItem {
  ride: string;
  lastService: string; // dd/mm/yyyy
  checks: string;
}

export interface MenuItem {
  name: string;
  price: string; // e.g. "₹250"
  veg: boolean;
  img?: string; // optional dish photo URL
}

export interface DiningOutlet {
  img: string;
  name: string;
  cuisine: string;
  description?: string;   // shown on the outlet detail page
  directionsUrl?: string; // optional map/directions link
  tags?: string[];        // short category chips
  items: MenuItem[];
}

export interface GuidelineItem {
  title: string;
  description: string;
  minHeight?: string; // optional, e.g. "120 cm"
}

export interface ParkMapZone {
  name: string;
  description: string;
}

/** A guest-selectable destination placed on the park's image map (percent coordinates). */
export interface ParkMapPlace {
  name: string;
  category: string;
  x: number;
  y: number;
  /** Exact park coordinate used for walking navigation when available. */
  lat?: number;
  lng?: number;
  avatarImage?: string;
}

export interface ParkMapConfig {
  img: string; // map image URL
  description: string;
  zones: ParkMapZone[];
  places?: ParkMapPlace[];
}

/* Emoji (or short text) icons for the landing tiles — editable per park. */
export interface LandingIcons {
  parkMap: string;
  ridesEvents: string;
  dining: string;
  waitTimes: string;
  guidelines: string;
  wavePool: string;
  safety: string;
  maintenance: string;
}

/* The complete, editable configuration for a single park. */
export interface ParkConfig {
  slug: string; // url id, e.g. "bengaluru"
  name: string; // "Wonderla Bengaluru"
  location: string; // "Bengaluru, Karnataka"
  active: boolean; // show in public park index
  logoUrl?: string; // header logo image; empty => text wordmark
  heroImageUrl?: string; // optional landing banner, kept separate from the interactive park map
  landingIcons?: LandingIcons;
  rides: MediaItem[];
  events: EventItem[];
  liveWaitTimes: WaitTimeItem[];
  waveRainDance: WaveRainItem[];
  safetyHygiene: SafetyItem[];
  maintenanceLog: MaintenanceItem[];
  parkMap: ParkMapConfig;
  dining: DiningOutlet[];
  rideGuidelines: GuidelineItem[];
  updatedAt: string; // ISO timestamp
}

/* Lightweight listing used by the park index + admin selector. */
export interface ParkSummary {
  slug: string;
  name: string;
  location: string;
  active: boolean;
  updatedAt: string;
}
