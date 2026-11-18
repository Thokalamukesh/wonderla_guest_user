// Attraction coordinates and route points below are illustrative sample data.
// Replace them with surveyed park coordinates and approved walking paths before
// presenting the layout as geographically accurate.
export const PARK_CENTER = { latitude: 12.8343, longitude: 77.401 };
export const SVG_MAP = { width: 1000, height: 700, centerX: 500, centerY: 350 };
export const SAMPLE_MAP_METERS_PER_UNIT = 0.9;
export const MAIN_ENTRANCE = { x: 500, y: 586 };

export function projectGpsToIllustration(position) {
  const latMeters = (position.latitude - PARK_CENTER.latitude) * 111_320;
  const lngMeters = (position.longitude - PARK_CENTER.longitude) * 111_320 * Math.cos(PARK_CENTER.latitude * Math.PI / 180);
  return {
    x: SVG_MAP.centerX + lngMeters * SAMPLE_MAP_METERS_PER_UNIT,
    y: SVG_MAP.centerY - latMeters * SAMPLE_MAP_METERS_PER_UNIT,
  };
}

export const CATEGORIES = ["All", "Thrill rides", "Water rides", "Dining", "Facilities", "Park access"];

export const PARK_LOCATIONS = [
  { id: "recoil", name: "Recoil", category: "Thrill rides", type: "Roller coaster", area: "Thrill District", x: 720, y: 185, icon: "↗", color: "#f06445", description: "A high-energy launch coaster. Sample map location." },
  { id: "termite-coaster", name: "Termite Coaster", category: "Thrill rides", type: "Family coaster", area: "Adventure Grove", x: 655, y: 300, icon: "〰", color: "#ed9a32", description: "Family coaster with a winding sample walking path." },
  { id: "wonderla-bamba", name: "Wonderla Bamba", category: "Thrill rides", type: "Thrill ride", area: "Adventure Grove", x: 610, y: 230, icon: "✦", color: "#ed9a32", description: "A high-thrill attraction. Sample map location." },
  { id: "drop-loop", name: "Drop Loop", category: "Water rides", type: "Water slide", area: "Water World", x: 295, y: 220, icon: "↘", color: "#39a6ce", description: "A looping water slide. Sample map location." },
  { id: "wave-pool", name: "Wave Pool", category: "Water rides", type: "Pool", area: "Water World", x: 205, y: 400, icon: "≋", color: "#39a6ce", description: "Relax by the waves. Sample map location." },
  { id: "lazy-river", name: "Lazy River", category: "Water rides", type: "Water ride", area: "Water World", x: 340, y: 470, icon: "⌁", color: "#39a6ce", description: "A gentle river ride. Sample map location." },
  { id: "boomerang", name: "Boomerang", category: "Water rides", type: "Water slide", area: "Water World", x: 270, y: 300, icon: "↶", color: "#39a6ce", description: "A fast water slide. Sample map location." },
  { id: "harakiri", name: "Harakiri", category: "Water rides", type: "Water slide", area: "Water World", x: 390, y: 250, icon: "⌁", color: "#39a6ce", description: "A steep water slide. Sample map location." },
  { id: "galaxy", name: "Galaxy Restaurant", category: "Dining", type: "Restaurant", area: "Central Plaza", x: 510, y: 340, icon: "✦", color: "#8e70c9", description: "A place to pause and refuel. Sample map location." },
  { id: "park-view", name: "Park View Restaurant", category: "Dining", type: "Restaurant", area: "Park Entrance", x: 430, y: 520, icon: "♨", color: "#8e70c9", description: "Dining near the entrance. Sample map location." },
  { id: "food-court", name: "Food Court", category: "Dining", type: "Food court", area: "Central Plaza", x: 565, y: 385, icon: "☕", color: "#8e70c9", description: "Quick bites and refreshments. Sample map location." },
  { id: "first-aid", name: "First Aid", category: "Facilities", type: "Guest facility", area: "Central Plaza", x: 550, y: 300, icon: "+", color: "#36a77a", description: "Guest assistance point. Sample map location." },
  { id: "restroom-north", name: "Restroom · North", category: "Facilities", type: "Restroom", area: "Adventure Grove", x: 795, y: 330, icon: "♙", color: "#36a77a", description: "Restroom marker. Sample map location." },
  { id: "restroom-south", name: "Restroom · South", category: "Facilities", type: "Restroom", area: "Water World", x: 405, y: 425, icon: "♙", color: "#36a77a", description: "Restroom marker. Sample map location." },
  { id: "lockers", name: "Lockers & Changing", category: "Facilities", type: "Guest facility", area: "Water World", x: 170, y: 320, icon: "▣", color: "#36a77a", description: "Lockers and changing rooms. Sample map location." },
  { id: "main-entrance", name: "Main Entrance", category: "Park access", type: "Entrance", area: "Park Entrance", x: MAIN_ENTRANCE.x, y: MAIN_ENTRANCE.y, icon: "➜", color: "#d15e82", description: "Park entrance marker. Sample map location." },
  { id: "exit", name: "Exit & Guest Help", category: "Park access", type: "Exit", area: "Park Entrance", x: 575, y: 590, icon: "i", color: "#d15e82", description: "Exit and guest help point. Sample map location." },
];

// Example paths only. These lines are not verified park walking directions.
const ENTRANCE = [MAIN_ENTRANCE.x, MAIN_ENTRANCE.y];
export const SAMPLE_WALKING_PATHS = {
  recoil: [ENTRANCE, [500, 540], [620, 520], [760, 475], [815, 395], [780, 300], [720, 185]],
  "termite-coaster": [ENTRANCE, [500, 540], [620, 520], [720, 465], [720, 370], [655, 300]],
  "wonderla-bamba": [ENTRANCE, [500, 540], [620, 520], [720, 465], [720, 370], [610, 230]],
  "drop-loop": [ENTRANCE, [500, 540], [450, 500], [390, 460], [320, 390], [295, 220]],
  "wave-pool": [ENTRANCE, [500, 540], [450, 500], [390, 460], [300, 455], [205, 400]],
  "lazy-river": [ENTRANCE, [500, 540], [450, 500], [390, 460], [340, 470]],
  boomerang: [ENTRANCE, [500, 540], [450, 500], [390, 460], [320, 390], [270, 300]],
  harakiri: [ENTRANCE, [500, 540], [450, 500], [440, 400], [390, 330], [390, 250]],
  galaxy: [ENTRANCE, [500, 540], [500, 450], [500, 340]],
  "park-view": [ENTRANCE, [500, 540], [430, 520]],
  "food-court": [ENTRANCE, [500, 540], [500, 450], [565, 385]],
  "first-aid": [ENTRANCE, [500, 540], [500, 450], [500, 340], [550, 300]],
  "restroom-north": [ENTRANCE, [500, 540], [620, 520], [720, 465], [720, 370], [795, 330]],
  "restroom-south": [ENTRANCE, [500, 540], [450, 500], [390, 460], [405, 425]],
  lockers: [ENTRANCE, [500, 540], [450, 500], [390, 460], [300, 390], [170, 320]],
  "main-entrance": [ENTRANCE],
  exit: [ENTRANCE, [540, 586], [575, 590]],
};
