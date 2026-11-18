# Wonderla illustrated park map

A standalone React + Vite map prototype. It runs separately from the existing Next.js app and does not use Google Maps or a backend.

## Run locally

```sh
cd wonderla-map-vite
npm install
npm run dev
```

Open the local URL printed by Vite. Browser location works on localhost and on deployed HTTPS sites. Allow location access to see the visitor GPS coordinates update continuously.

## Map data and accuracy

The artwork, attraction positions, and walking paths are deliberately illustrative sample data. They are not surveyed Wonderla directions. The app labels this in the UI and draws only a sample path, without an ETA.

- Edit attraction names, categories, icons, and sample SVG positions in `src/data/parkMapData.js` (`PARK_LOCATIONS`). The `x` and `y` fields use the 1000 × 700 SVG viewBox.
- Edit sample routes in `SAMPLE_WALKING_PATHS` in the same file. Each path is an array of `[x, y]` points beginning at `MAIN_ENTRANCE`.
- Replace the illustrated SVG artwork and park boundary in `src/components/ParkMap.jsx` with an approved layout. Keep all coordinates in the same viewBox, or update `SVG_MAP`.
- To accurately place the live GPS dot, calibrate `PARK_CENTER` and `SAMPLE_MAP_METERS_PER_UNIT` against the approved map’s real geographic bounds. Current mapping is approximate and should not be treated as an accurate park position.
- Replace every sample attraction coordinate and walking path with Wonderla-approved coordinates and paths before describing them as real directions.

Geolocation is handled locally in the browser. No location is sent to a server. Socket.IO is intentionally not included until a ride-status backend exists.
