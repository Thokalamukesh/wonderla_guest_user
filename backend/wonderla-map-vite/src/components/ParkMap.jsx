import React, { useMemo } from "react";
import { MAIN_ENTRANCE, PARK_LOCATIONS, projectGpsToIllustration, SAMPLE_WALKING_PATHS, SVG_MAP } from "../data/parkMapData.js";

const TREE_POINTS = [
  [146, 154], [204, 123], [263, 145], [355, 120], [452, 155], [545, 119], [625, 145], [851, 150], [907, 200], [886, 290], [868, 424], [822, 548], [733, 586], [244, 571], [145, 508], [118, 406], [123, 285], [337, 570], [896, 490], [475, 205], [858, 220], [132, 226], [758, 115], [925, 352],
];

function toPolyline(points) {
  return points.map(([x, y]) => `${x},${y}`).join(" ");
}

function Tree({ x, y, small = false }) {
  const size = small ? 12 : 18;
  return (
    <g transform={`translate(${x} ${y})`} aria-hidden="true">
      <ellipse cx="1" cy={size * 0.65} rx={size * 0.78} ry={size * 0.3} fill="#b8d5af" opacity=".42" />
      <circle cy="0" r={size * 0.7} fill="#83bc82" />
      <circle cx={-size * 0.34} cy={size * 0.15} r={size * 0.42} fill="#a1cf91" />
      <circle cx={size * 0.34} cy={size * 0.16} r={size * 0.4} fill="#6fae78" />
      <circle cx="-2" cy="-3" r={size * 0.13} fill="#d9eaa9" opacity=".85" />
    </g>
  );
}

function AttractionMarker({ location, selected, onSelect }) {
  return (
    <g
      className={`map-attraction ${selected ? "is-selected" : ""}`}
      transform={`translate(${location.x} ${location.y})`}
      role="button"
      tabIndex="0"
      aria-label={`${location.name}, ${location.category}`}
      aria-pressed={selected}
      onClick={() => onSelect(location.id)}
      onKeyDown={(event) => {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          onSelect(location.id);
        }
      }}
    >
      {selected && <circle className="marker-pulse" r="31" fill={location.color} opacity=".17" />}
      <circle className="marker-shadow" cy="2" r="20" fill="#274d3c" opacity=".13" />
      <circle className="marker-halo" r="19" fill="#fff" />
      <circle r="15" fill={location.color} />
      <text className="marker-glyph" y="1" textAnchor="middle" dominantBaseline="central">{location.icon}</text>
      <g className="marker-label" transform="translate(23 -12)">
        <rect x="0" y="-12" width={Math.max(68, location.name.length * 6.3)} height="23" rx="11.5" fill="#fff" />
        <text x="10" y="3" className="marker-label-text">{location.name}</text>
      </g>
      <title>{location.name} · sample location</title>
    </g>
  );
}

export default function ParkMap({ zoom, locations, selectedLocation, selectedId, livePosition, onSelect }) {
  const livePoint = useMemo(() => livePosition ? projectGpsToIllustration(livePosition) : null, [livePosition]);
  const livePointIsInView = livePoint && livePoint.x >= 35 && livePoint.x <= 965 && livePoint.y >= 35 && livePoint.y <= 665;
  const boundedLivePoint = livePoint && {
    x: Math.max(42, Math.min(958, livePoint.x)),
    y: Math.max(42, Math.min(658, livePoint.y)),
  };

  const routePoints = selectedLocation ? SAMPLE_WALKING_PATHS[selectedLocation.id] : null;
  const routeFromGps = Boolean(routePoints && livePointIsInView);
  const routeCoordinates = routePoints && routeFromGps
    ? [[livePoint.x, livePoint.y], ...routePoints]
    : routePoints;
  const viewWidth = SVG_MAP.width / zoom;
  const viewHeight = SVG_MAP.height / zoom;
  const viewBox = `${(SVG_MAP.width - viewWidth) / 2} ${(SVG_MAP.height - viewHeight) / 2} ${viewWidth} ${viewHeight}`;

  return (
    <div className="park-map-canvas">
      <svg className="park-map-svg" viewBox={viewBox} role="img" aria-label="Illustrated Wonderla park map with sample ride locations">
        <defs>
          <pattern id="mapGrass" width="28" height="28" patternUnits="userSpaceOnUse">
            <circle cx="4" cy="7" r="1.2" fill="#dcebd4" />
            <circle cx="19" cy="21" r="1" fill="#dcebd4" />
          </pattern>
          <pattern id="waterWaves" width="34" height="18" patternUnits="userSpaceOnUse">
            <path d="M0 9c5-5 11-5 17 0s12 5 17 0" fill="none" stroke="#91d2dd" strokeWidth="2" opacity=".55" />
          </pattern>
          <filter id="softShadow" x="-30%" y="-30%" width="160%" height="170%">
            <feDropShadow dx="0" dy="4" stdDeviation="5" floodColor="#41614b" floodOpacity=".12" />
          </filter>
        </defs>

        <rect width="1000" height="700" fill="#eaf3e5" />
        <rect width="1000" height="700" fill="url(#mapGrass)" opacity=".8" />
        <path d="M-30 84C112 37 171 53 288 30c149-29 212 13 338-4 170-22 247 17 403 71v-120H-30Z" fill="#f6eacb" />
        <path d="M-20 80c130-43 181-13 305-39 136-28 204 10 338-7 158-19 238 7 389 68" fill="none" stroke="#dfc795" strokeWidth="5" />

        <path d="M76 248c38-94 136-145 254-149 119-5 173 28 252 16 123-19 266 16 324 118 52 93 34 207-9 307-39 92-128 121-247 119-149-2-224 15-340 2-139-16-226-65-245-171-15-81-22-166 11-242Z" fill="#d7ebcf" stroke="#a6c79f" strokeWidth="3" />
        <path d="M76 248c38-94 136-145 254-149 119-5 173 28 252 16 123-19 266 16 324 118 52 93 34 207-9 307-39 92-128 121-247 119-149-2-224 15-340 2-139-16-226-65-245-171-15-81-22-166 11-242Z" fill="url(#mapGrass)" opacity=".65" />

        <g className="zone-labels" aria-hidden="true">
          <g transform="translate(170 194)"><rect width="142" height="30" rx="15" fill="#fff" opacity=".74" /><text x="71" y="20" textAnchor="middle">WATER WORLD</text></g>
          <g transform="translate(672 125)"><rect width="164" height="30" rx="15" fill="#fff" opacity=".74" /><text x="82" y="20" textAnchor="middle">ADVENTURE GROVE</text></g>
          <g transform="translate(430 286)"><rect width="142" height="30" rx="15" fill="#fff" opacity=".74" /><text x="71" y="20" textAnchor="middle">CENTRAL PLAZA</text></g>
        </g>

        <g aria-hidden="true">
          <path d="M157 355c14-46 76-74 137-63 51 9 68 48 58 94-9 43-39 84-96 87-59 2-112-38-109-79 1-16 4-27 10-39Z" fill="#8bd1db" stroke="#fff" strokeWidth="9" />
          <path d="M157 355c14-46 76-74 137-63 51 9 68 48 58 94-9 43-39 84-96 87-59 2-112-38-109-79 1-16 4-27 10-39Z" fill="url(#waterWaves)" />
          <path d="M244 328c31 2 58 13 69 31m-141 27c27-10 45 1 52 22" fill="none" stroke="#fff" strokeWidth="4" strokeLinecap="round" opacity=".65" />
          <path d="M346 418c18-23 62-26 83-5 16 16 14 38-4 54-18 15-50 18-68 4-19-15-26-33-11-53Z" fill="#b3e1dc" stroke="#fff" strokeWidth="7" />
          <path d="M352 441c20-12 48-13 67 1" fill="none" stroke="#fff" strokeWidth="3" strokeLinecap="round" />
        </g>

        <g aria-hidden="true">
          <path d="M500 585C500 534 488 506 500 460S510 392 500 350 486 283 500 239 515 179 500 127" fill="none" stroke="#f5e5bc" strokeWidth="31" strokeLinecap="round" />
          <path d="M500 585C500 534 488 506 500 460S510 392 500 350 486 283 500 239 515 179 500 127" fill="none" stroke="#fffaf0" strokeWidth="23" strokeLinecap="round" />
          <path d="M500 465C440 461 401 462 354 423S293 378 258 354M500 462c73 0 122-8 179-45 54-35 91-64 132-101M501 350c-55-10-94-29-126-69-23-28-30-54-32-90M501 350c52 3 100-12 136-42 41-34 54-64 63-113M500 540c-46-5-91-2-132-20-35-15-60-35-80-64M504 520c43-21 90-27 130-19 34 7 61 23 84 49" fill="none" stroke="#f5e5bc" strokeWidth="22" strokeLinecap="round" />
          <path d="M500 465C440 461 401 462 354 423S293 378 258 354M500 462c73 0 122-8 179-45 54-35 91-64 132-101M501 350c-55-10-94-29-126-69-23-28-30-54-32-90M501 350c52 3 100-12 136-42 41-34 54-64 63-113M500 540c-46-5-91-2-132-20-35-15-60-35-80-64M504 520c43-21 90-27 130-19 34 7 61 23 84 49" fill="none" stroke="#fffaf0" strokeWidth="15" strokeLinecap="round" />
          <path d="M499 582c-26 15-54 17-79 6-16-7-24-22-22-40 2-19 24-34 46-30 23 4 38 19 55 35 20-24 44-35 68-32 20 2 31 16 30 33-1 17-17 29-40 31-22 2-43-2-58-10Z" fill="#efbd68" stroke="#fff" strokeWidth="6" />
        </g>

        <g aria-hidden="true" filter="url(#softShadow)">
          <circle cx="500" cy="350" r="50" fill="#fff" />
          <circle cx="500" cy="350" r="43" fill="#f4ce81" />
          <circle cx="500" cy="350" r="30" fill="#ffe7ad" />
          <path d="M500 315v70m-35-35h70m-60-25 50 50m0-50-50 50" stroke="#fff7e3" strokeWidth="4" strokeLinecap="round" />
          <rect x="474" y="391" width="52" height="10" rx="5" fill="#e9f3dc" />
        </g>

        <g className="map-buildings" aria-hidden="true">
          <g transform="translate(235 524)"><rect x="-28" y="-17" width="56" height="37" rx="8" fill="#fff" /><path d="m-32-16 32-20 32 20" fill="#e88b61" /><rect x="-6" y="-1" width="13" height="21" rx="5" fill="#d7e5d7" /></g>
          <g transform="translate(680 426)"><rect x="-33" y="-15" width="66" height="37" rx="8" fill="#fff" /><path d="m-37-14 37-22 37 22" fill="#78a9a1" /><rect x="-7" y="-2" width="14" height="24" rx="5" fill="#d7e5d7" /></g>
          <g transform="translate(761 235)"><rect x="-24" y="-18" width="48" height="40" rx="7" fill="#fff" /><path d="m-28-17 28-20 28 20" fill="#e7a54f" /><rect x="-5" y="0" width="11" height="22" rx="5" fill="#d7e5d7" /></g>
        </g>

        {TREE_POINTS.map(([x, y]) => <Tree key={`${x}-${y}`} x={x} y={y} />)}

        <g className="map-feature-labels" aria-hidden="true">
          <text x="219" y="475">WAVE POOL</text>
          <text x="329" y="489">LAZY RIVER</text>
          <text x="500" y="329" textAnchor="middle">PLAZA</text>
          <text x="500" y="625" textAnchor="middle">MAIN GATE</text>
          <text x="755" y="468">GARDEN WALK</text>
        </g>

        {selectedLocation && routeCoordinates && (
          <g className="active-route" aria-label="Sample walking path">
            <polyline points={toPolyline(routeCoordinates)} fill="none" stroke="#fff" strokeWidth="16" strokeLinecap="round" strokeLinejoin="round" />
            <polyline points={toPolyline(routeCoordinates)} fill="none" stroke="#536ee8" strokeWidth="8" strokeLinecap="round" strokeLinejoin="round" strokeDasharray="1 1" />
          </g>
        )}

        <g aria-hidden="true">
          <circle cx={MAIN_ENTRANCE.x} cy={MAIN_ENTRANCE.y} r="8" fill="#fff" stroke="#d15e82" strokeWidth="4" />
        </g>

        {locations.map((location) => (
          <AttractionMarker key={location.id} location={location} selected={selectedId === location.id} onSelect={onSelect} />
        ))}

        {livePosition && boundedLivePoint && (
          <g className={`live-user-marker ${livePointIsInView ? "" : "is-off-map"}`} transform={`translate(${boundedLivePoint.x} ${boundedLivePoint.y})`} aria-label="Your live GPS position, approximate on illustrative layout">
            <circle className="gps-pulse" r="26" />
            <circle r="13" fill="#2778ed" stroke="#fff" strokeWidth="5" />
            <circle r="4" fill="#fff" />
            <g transform="translate(18 -20)"><rect width="73" height="24" rx="12" fill="#1d5fc3" /><text x="36.5" y="16" textAnchor="middle">YOU · GPS</text></g>
          </g>
        )}
      </svg>

      <div className="map-sample-stamp"><span className="sample-stamp-dot" />ILLUSTRATIVE LAYOUT · SAMPLE LOCATIONS</div>
      {!livePointIsInView && livePosition && <div className="map-edge-note">GPS is outside this sample map area</div>}
    </div>
  );
}
