/* ============================================================
   Steps (navigation) + seed-data factory.
   Seed content below is based on real Wonderla Bengaluru rides,
   restaurants and guidelines (wonderla.com). It is only the
   STARTING point for each park — everything is editable per
   park in the admin panel.
============================================================ */

import type { ParkConfig, LandingIcons } from "./types";

/* Default landing-tile icons (used as fallback + seed). */
export const DEFAULT_LANDING_ICONS: LandingIcons = {
  parkMap: "🗺️",
  ridesEvents: "🎠",
  dining: "🍴",
  waitTimes: "🕐",
  guidelines: "📏",
  wavePool: "🌊",
  safety: "🛡️",
  maintenance: "🔧",
};

/* ---------------- Steps ---------------- */

export type StepKey =
  | "LANDING"
  | "PARK_MAP"
  | "RIDE_EVENT_DETAILS"
  | "DINING_MENU"
  | "LIVE_RIDE_WAIT_TIME"
  | "RIDE_GUIDELINES"
  | "WAVE_POOL_RAIN_DANCE"
  | "SAFETY_AND_HYGIENE_INFO"
  | "MAINTENANCE_LOG";

export type StepValue =
  | "landing"
  | "park_map"
  | "ride_event_detail"
  | "dining_menu"
  | "live_ride_wait_time"
  | "ride_guidlines"
  | "wave_pool_rain_dance"
  | "safety_and_hygiene_info"
  | "maintenance_log";

export const steps: Record<StepKey, StepValue> = {
  LANDING: "landing",
  PARK_MAP: "park_map",
  RIDE_EVENT_DETAILS: "ride_event_detail",
  DINING_MENU: "dining_menu",
  LIVE_RIDE_WAIT_TIME: "live_ride_wait_time",
  RIDE_GUIDELINES: "ride_guidlines",
  WAVE_POOL_RAIN_DANCE: "wave_pool_rain_dance",
  SAFETY_AND_HYGIENE_INFO: "safety_and_hygiene_info",
  MAINTENANCE_LOG: "maintenance_log",
};

/* ---------------- Seed factory ---------------- */

const slugify = (s: string) =>
  s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");


/* Per-city hero image (used as each park's map image by default). */
const PARK_HERO: Record<string, string> = {
  bengaluru: "/wonderla/parks/bengaluru-layout.jpg",
  kochi: "/wonderla/parks/kochi-layout.jpg",
  hyderabad: "/wonderla/parks/hyderabad-layout.jpg",
  bhubaneswar: "/wonderla/parks/bhubaneswar.png",
  chennai: "/wonderla/parks/chennai-layout.jpg",
};

/* Keep the original city artwork on the landing screen. */
export const PARK_LANDING_HERO: Record<string, string> = {
  bengaluru: "/wonderla/parks/bengaluru.png",
  kochi: "/wonderla/parks/kochi.png",
  hyderabad: "/wonderla/parks/hyderabad.png",
  bhubaneswar: "/wonderla/parks/bhubaneswar.png",
  chennai: "/wonderla/parks/chennai.png",
};

const PARK_MAP_PLACES: Record<string, ParkConfig["parkMap"]["places"]> = {
  hyderabad: [
    { name: "Entrance / Exit", category: "Entrance", x: 83, y: 29 },
    { name: "Mission Interstellar", category: "Ride", x: 29, y: 13 },
    { name: "Maverick", category: "Ride", x: 58, y: 17 },
    { name: "Sky Wheel", category: "Ride", x: 48, y: 23 },
    { name: "Kiddies Wheel", category: "Kids ride", x: 49, y: 31 },
    { name: "Recoil", category: "Ride", x: 32, y: 37 },
    { name: "Wonderla Bamba", category: "Ride", x: 19, y: 40 },
    { name: "Wave Pool", category: "Water ride", x: 25, y: 78 },
    { name: "Lazy River", category: "Water ride", x: 45, y: 75 },
    { name: "Boomerang", category: "Water ride", x: 59, y: 59 },
    { name: "Harakiri", category: "Water ride", x: 60, y: 65 },
    { name: "First Aid", category: "Facility", x: 58, y: 94 },
  ],
  chennai: [
    { name: "Entrance / Exit", category: "Entrance", x: 83, y: 46 },
    { name: "Maverick", category: "Ride", x: 67, y: 27 },
    { name: "G-Fall", category: "Ride", x: 56, y: 33 },
    { name: "Freestyler", category: "Ride", x: 49, y: 31 },
    { name: "Drop Zone", category: "Ride", x: 36, y: 28 },
    { name: "Techno Jump", category: "Ride", x: 31, y: 10 },
    { name: "Sky Wheel", category: "Ride", x: 45, y: 33 },
    { name: "Crazy Cars", category: "Family ride", x: 27, y: 39 },
    { name: "Wave Pool", category: "Water ride", x: 45, y: 60 },
    { name: "Rain Disco", category: "Water ride", x: 28, y: 54 },
    { name: "Drop Loop", category: "Water ride", x: 14, y: 63 },
    { name: "First Aid", category: "Facility", x: 31, y: 44 },
  ],
  kochi: [
    { name: "Entrance / Exit", category: "Entrance", x: 13, y: 30 },
    { name: "Chikku", category: "Family ride", x: 26, y: 44 },
    { name: "Recoil", category: "Ride", x: 58, y: 18 },
    { name: "Techno Jump", category: "Ride", x: 64, y: 35 },
    { name: "Crazy Cars", category: "Family ride", x: 39, y: 33 },
    { name: "Carousel", category: "Kids ride", x: 51, y: 25 },
    { name: "Wave Pool", category: "Water ride", x: 47, y: 50 },
    { name: "Jungle Lagoon", category: "Water ride", x: 66, y: 53 },
    { name: "Boomerang", category: "Water ride", x: 75, y: 62 },
    { name: "Uphill Racers", category: "Water ride", x: 23, y: 71 },
    { name: "Rain Disco", category: "Water ride", x: 41, y: 61 },
    { name: "First Aid", category: "Facility", x: 60, y: 40 },
  ],
};

export function createDefaultParkConfig(
  name: string,
  location = "",
  slug?: string
): ParkConfig {
  const _slug = slug || slugify(name);
  return {
    slug: _slug,
    name,
    location,
    active: true,
    logoUrl: "/wonderla/logo.png",
    heroImageUrl: PARK_LANDING_HERO[_slug] || "",
    landingIcons: { ...DEFAULT_LANDING_ICONS },

    rides: [
      { img: "/wonderla/rides/mission-interstellar.jpg", title: "Mission Interstellar", description: "Blast through cosmic chaos on a wild, out-of-this-world space ride!", tags: ["Space Theme", "4K Clarity"] },
      { img: "", title: "Recoil", description: "India's first reverse-looping roller coaster — brace for a backward launch!", tags: ["Roller Coaster", "High Thrill"] },
      { img: "/wonderla/rides/drop-loop.jpg", title: "Drop Loop", description: "Slide down a sky-high slope, twist through a loop and make a splashy exit!", tags: ["High Speed", "Vertical Slide"] },
      { img: "/wonderla/rides/boomerang.jpg", title: "Boomerang", description: "Shoot out of a tube and swoop back like a boomerang on this thrilling slide!", tags: ["Closed Tunnel", "Sudden Drop"] },
      { img: "/wonderla/rides/harakiri.jpg", title: "Harakiri", description: "Rush down, take a breather, then slide back to the finish for non-stop thrill!", tags: ["Dual Drop", "Speed Thrills"] },
      { img: "/wonderla/rides/jungle-lagoon.jpg", title: "Jungle Lagoon", description: "Race down water slides, climb a treehouse and wade through a shallow lagoon!", tags: ["Treehouse Fun", "Shallow Slides"] },
      { img: "/wonderla/rides/lazy-river.jpg", title: "Lazy River", description: "Drift through a calm river that snakes past an alligator and gargoyle skull.", tags: ["Relaxing Drift", "Rubber Floats"] },
      { img: "/wonderla/rides/uphill-racers.jpg", title: "Uphill Racers", description: "Hold your rubber mat tight as you race through curvy bumps on this water slide!", tags: ["Racing Thrills", "Family Fun"] },
      { img: "/wonderla/rides/fun-racers.jpg", title: "Fun Racers", description: "Slither down through thrilling tiers on this smooth and slippery adventure!", tags: ["Rubber Mats", "Gentle Thrills"] },
      { img: "/wonderla/rides/flying-jumbo.jpg", title: "Flying Jumbo", description: "Sit like a mahout on a flying elephant, spinning in a circle while rising and dropping.", tags: ["Flying Elephants", "Circular Ride"] },
      { img: "/wonderla/rides/carousel.jpg", title: "Carousel", description: "Gallop around on colourful horses like a seasoned cowboy!", tags: ["Carousel", "Galloping Horses"] },
      { img: "/wonderla/rides/mini-express.jpg", title: "Mini Express", description: "Climb onboard a mini toy-train journey around an exciting circuit!", tags: ["Toy Train", "Circuit Fun"] },
      { img: "/wonderla/rides/magic-mushroom.jpg", title: "Magic Mushroom", description: "Spin around a magic mushroom on the backs of mighty ants and busy bees!", tags: ["Garden Theme", "Carousel Fun"] },
      { img: "/wonderla/rides/kiddies-wheel.jpg", title: "Kiddies Wheel", description: "A miniature giant wheel that gives children a taste of real thrill without the scare.", tags: ["Mini Ferris", "Gentle Thrill"] },
      { img: "/wonderla/rides/funky-monkey.jpg", title: "Funky Monkey", description: "Plummet into a safe freefall with a tall and playful monkey!", tags: ["Mini Drop Zone", "5m Freefall"] },
    ],

    events: [
      { img: "", time: "12:00 PM", title: "Pirate's Show", description: "Captain Hook's Revenge — a live stunt spectacle at the central plaza.", tags: ["Live Show", "Family"] },
      { img: "", time: "04:00 PM", title: "Character Parade", description: "A vibrant character parade winds through the park.", tags: ["Parade", "Kids"] },
      { img: "", time: "07:00 PM", title: "Laser & Fountain Show", description: "A dazzling musical laser and fountain finale to end the day.", tags: ["Finale", "Night Show"] },
    ],

    liveWaitTimes: [
      { img: "/wonderla/rides/mission-interstellar.jpg", title: "Mission Interstellar", description: "Space-themed thrill ride.", time: 5 },
      { img: "", title: "Recoil", description: "Reverse-looping roller coaster.", time: 35 },
      { img: "/wonderla/rides/drop-loop.jpg", title: "Drop Loop", description: "High-speed vertical slide.", time: 30 },
      { img: "/wonderla/rides/boomerang.jpg", title: "Boomerang", description: "Closed-tunnel slide with a sudden drop.", time: 25 },
      { img: "/wonderla/rides/harakiri.jpg", title: "Harakiri", description: "Dual-drop speed slide.", time: 20 },
      { img: "/wonderla/rides/jungle-lagoon.jpg", title: "Jungle Lagoon", description: "Water slides and treehouse.", time: 15 },
      { img: "/wonderla/rides/carousel.jpg", title: "Carousel", description: "Gentle family favourite.", time: 3 },
    ],

    waveRainDance: [
      { img: "", title: "Wave Pool", timeSlot: ["12:00 PM", "01:00 PM", "02:00 PM"], rideDuration: 20 },
      { img: "", title: "Rain Disco", timeSlot: ["02:00 PM", "04:00 PM", "05:00 PM"], rideDuration: 30 },
    ],

    safetyHygiene: [
      { img: "", title: "Advanced Safety Technology", description: "Every ride is equipped with advanced safety technology and complies with global regulations." },
      { img: "", title: "Inspections & Maintenance", description: "Regular inspections and maintenance by skilled technicians, with extensive trials and continuous monitoring." },
      { img: "", title: "24x7 Emergency Response", description: "Fully operational emergency response systems round the clock, with regularly trained staff." },
      { img: "", title: "Water Quality", description: "Pool water is tested frequently, maintaining chlorine 1-3 ppm and pH 7.2-7.8." },
      { img: "", title: "Sanitization", description: "Toilets, common areas and cafeterias are sanitized at regular intervals through the day." },
    ],

    maintenanceLog: [
      { ride: "Mission Interstellar", lastService: "12/10/2026", checks: "6" },
      { ride: "Recoil", lastService: "11/10/2026", checks: "7" },
      { ride: "Drop Loop", lastService: "12/10/2026", checks: "5" },
      { ride: "Boomerang", lastService: "10/10/2026", checks: "5" },
      { ride: "Harakiri", lastService: "11/10/2026", checks: "6" },
      { ride: "Flying Jumbo", lastService: "12/10/2026", checks: "4" },
      { ride: "Carousel", lastService: "12/10/2026", checks: "4" },
    ],

    parkMap: {
      img: PARK_HERO[_slug] || "",
      description: "Choose a destination, set your starting point on the map, and follow the direction guide.",
      zones: [
        { name: "Land Zone", description: "High-thrill coasters and dry rides like Recoil and Mission Interstellar." },
        { name: "Water Zone", description: "Wave pool, rain disco and water slides including Boomerang and Harakiri." },
        { name: "Kids Zone", description: "Gentle rides for younger guests — Carousel, Mini Express and more." },
      ],
      ...(_slug === "bengaluru" ? { places: [
        { name: "Entrance / Exit", category: "Entrance", x: 24, y: 30 },
        { name: "Park View Restaurant", category: "Dining", x: 11, y: 27 },
        { name: "Food Court", category: "Dining", x: 29, y: 24 },
        { name: "Wonderla Bamba", category: "Ride", x: 33, y: 27 },
        { name: "Recoil", category: "Ride", x: 77, y: 30, lat: 12.832685, lng: 77.401272 },
        { name: "Wave Pool", category: "Water rides", x: 17, y: 46 },
        { name: "Lazy River", category: "Water rides", x: 49, y: 57 },
        { name: "Drop Loop", category: "Water rides", x: 48, y: 29 },
        { name: "Harakiri", category: "Water rides", x: 58, y: 61 },
        { name: "Boomerang", category: "Water rides", x: 58, y: 58 },
        { name: "First Aid", category: "Facility", x: 48, y: 37 },
        { name: "Dome Plaza", category: "Attraction", x: 31, y: 29 },
      ] } : PARK_MAP_PLACES[_slug] ? { places: PARK_MAP_PLACES[_slug] } : {}),
    },

    dining: [
      {
        img: "/wonderla/restaurants/galaxy-ac.jpg", name: "Galaxy AC Restaurant", cuisine: "Veg & Non-Veg Buffet",
        description: "An immersive galaxy-themed, air-conditioned buffet restaurant serving 20+ vegetarian and non-vegetarian delicacies with premium service.",
        directionsUrl: "", tags: ["Unlimited Buffet", "Air-Conditioned"],
        items: [
          { name: "Unlimited Veg Buffet", price: "₹499", veg: true, img: "" },
          { name: "Unlimited Non-Veg Buffet", price: "₹599", veg: false, img: "" },
        ],
      },
      {
        img: "/wonderla/restaurants/park-view.jpg", name: "Park View Restaurant", cuisine: "Traditional Breakfast",
        description: "Kickstart your day with fluffy idlis, crispy dosas and hearty omelettes, served with a beautiful view of the park.",
        directionsUrl: "", tags: ["Breakfast", "Authentic Flavours"],
        items: [
          { name: "Idli (2 pcs)", price: "₹90", veg: true, img: "" },
          { name: "Masala Dosa", price: "₹150", veg: true, img: "" },
          { name: "Bread Omelette", price: "₹120", veg: false, img: "" },
          { name: "Filter Coffee", price: "₹60", veg: true, img: "" },
        ],
      },
      {
        img: "/wonderla/restaurants/greens.jpg", name: "Greens Restaurant", cuisine: "Pure Vegetarian",
        description: "An exclusive veg restaurant with classic biryanis, wholesome meals, tandoori and Chinese delights. Located opposite Termite Coaster.",
        directionsUrl: "", tags: ["Vegetarian", "Indian & Chinese"],
        items: [
          { name: "Veg Biryani", price: "₹240", veg: true, img: "" },
          { name: "Paneer Butter Masala", price: "₹220", veg: true, img: "" },
          { name: "Veg Noodles", price: "₹180", veg: true, img: "" },
          { name: "Paneer Tikka", price: "₹240", veg: true, img: "" },
        ],
      },
      {
        img: "/wonderla/restaurants/chillies.jpg", name: "Chillies Restaurant", cuisine: "Indian & Oriental",
        description: "Aromatic biryanis, modern Chinese twists and tandoori delicacies at the Central Plaza — perfect to unwind over lunch or a snack.",
        directionsUrl: "", tags: ["Biryani", "Fusion"],
        items: [
          { name: "Chicken Biryani", price: "₹320", veg: false, img: "" },
          { name: "Chicken Tikka", price: "₹280", veg: false, img: "" },
          { name: "Veg Fried Rice", price: "₹180", veg: true, img: "" },
        ],
      },
      {
        img: "/wonderla/restaurants/courtyard.jpg", name: "Courtyard Restaurant", cuisine: "South Indian Buffet",
        description: "Inspired by Kerala's courtyard houses, featuring a wide buffet spread of popular dishes from the Southern states. Next to Insanity and Hurricane.",
        directionsUrl: "", tags: ["Buffet", "South Indian"],
        items: [
          { name: "South Indian Veg Buffet", price: "₹450", veg: true, img: "" },
          { name: "South Indian Non-Veg Buffet", price: "₹520", veg: false, img: "" },
        ],
      },
      {
        img: "/wonderla/restaurants/waves.jpg", name: "Waves Restaurant", cuisine: "Multi-cuisine",
        description: "Poolside dining by the wave pool with aromatic biryani, juicy tandoor and flavours from the Chinese wok.",
        directionsUrl: "", tags: ["Wave Pool View", "Worldwide Flavours"],
        items: [
          { name: "Veg Biryani", price: "₹240", veg: true, img: "" },
          { name: "Chicken from the Wok", price: "₹300", veg: false, img: "" },
          { name: "Tandoori Platter", price: "₹340", veg: false, img: "" },
        ],
      },
      {
        img: "/wonderla/restaurants/smoke-grill.jpg", name: "Smoke & Grill", cuisine: "BBQ & Arabian",
        description: "Authentic tandoori tikkas cooked in a traditional clay oven, plus Arabian shawarma wrapped in soft roomali roti.",
        directionsUrl: "", tags: ["BBQ", "Grilling"],
        items: [
          { name: "Tandoori Chicken Tikka", price: "₹260", veg: false, img: "" },
          { name: "Chicken Shawarma", price: "₹180", veg: false, img: "" },
          { name: "Veg Seekh Kebab", price: "₹200", veg: true, img: "" },
        ],
      },
      {
        img: "/wonderla/restaurants/chaat-galli.jpg", name: "Chaat Galli", cuisine: "Street Food",
        description: "A mouthwatering array of chaats — bhelpuri, paanipuri, pav bhaji and more — at the Entrance Plaza food court (after 4 PM).",
        directionsUrl: "", tags: ["Chaat", "Street Food"],
        items: [
          { name: "Pani Puri", price: "₹80", veg: true, img: "" },
          { name: "Bhel Puri", price: "₹90", veg: true, img: "" },
          { name: "Pav Bhaji", price: "₹120", veg: true, img: "" },
        ],
      },
    ],

    rideGuidelines: [
      { title: "Height & Tickets", description: "Regular ticket for guests above 140 cm; child ticket for 85-140 cm; free entry for kids under 85 cm.", minHeight: "140 cm" },
      { title: "Unlimited Access", description: "Your park ticket includes unlimited access to all land, water and kids rides for the day." },
      { title: "Lockers & Changing Rooms", description: "Lockers and changing rooms are available near the rides to store belongings and change." },
      { title: "Health Advisory", description: "High-thrill rides are not recommended for guests with heart conditions, back/neck issues or expectant mothers." },
      { title: "Follow Staff Instructions", description: "Always follow ride operator and safety-crew instructions, and secure loose articles before boarding." },
    ],

    updatedAt: new Date().toISOString(),
  };
}

/** Empty starting content for parks added in the admin; seeded legacy parks keep their sample data. */
export function createBlankParkConfig(name: string, location = "", slug?: string): ParkConfig {
  const parkSlug = slug || slugify(name);
  return {
    slug: parkSlug,
    name,
    location,
    active: true,
    logoUrl: "/wonderla/logo.png",
    landingIcons: { ...DEFAULT_LANDING_ICONS },
    rides: [],
    events: [],
    liveWaitTimes: [],
    waveRainDance: [],
    safetyHygiene: [],
    maintenanceLog: [],
    parkMap: { img: "", description: "", zones: [] },
    dining: [],
    rideGuidelines: [],
    updatedAt: new Date().toISOString(),
  };
}

export const SEED_PARKS: Array<{ name: string; location: string; slug: string }> = [
  { name: "Wonderla Bengaluru", location: "Bengaluru, Karnataka", slug: "bengaluru" },
  { name: "Wonderla Kochi", location: "Kochi, Kerala", slug: "kochi" },
  { name: "Wonderla Hyderabad", location: "Hyderabad, Telangana", slug: "hyderabad" },
  { name: "Wonderla Bhubaneswar", location: "Bhubaneswar, Odisha", slug: "bhubaneswar" },
  { name: "Wonderla Chennai", location: "Chennai, Tamil Nadu", slug: "chennai" },
];

export { slugify };
