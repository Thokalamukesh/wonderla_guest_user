import React, { useEffect, useMemo, useState } from "react";
import LocationPanel from "./components/LocationPanel.jsx";
import ParkMap from "./components/ParkMap.jsx";
import { PARK_LOCATIONS, projectGpsToIllustration, SVG_MAP } from "./data/parkMapData.js";

function MapLegend() {
  return <div className="map-legend"><strong>MAP KEY</strong><span><i className="legend-ride" />Ride / place</span><span><i className="legend-live" />You · live GPS</span><span><i className="legend-route" />Sample path</span></div>;
}

export default function App() {
  const [livePosition, setLivePosition] = useState(null);
  const [gpsStatus, setGpsStatus] = useState("Waiting for location permission…");
  const [gpsError, setGpsError] = useState(false);
  const [selectedId, setSelectedId] = useState("recoil");
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [search, setSearch] = useState("");
  const [zoom, setZoom] = useState(1);

  useEffect(() => {
    if (!navigator.geolocation) {
      setGpsStatus("Location is not supported by this browser.");
      setGpsError(true);
      return;
    }

    const watchId = navigator.geolocation.watchPosition(
      ({ coords }) => {
        setLivePosition({ latitude: coords.latitude, longitude: coords.longitude, accuracy: coords.accuracy });
        setGpsStatus("GPS location is updating");
        setGpsError(false);
      },
      (error) => {
        setGpsStatus(error.code === error.PERMISSION_DENIED
          ? "Location permission is off. Allow it in your browser settings."
          : "Could not find your location. Check device location services.");
        setGpsError(true);
      },
      { enableHighAccuracy: true, maximumAge: 5000, timeout: 15000 },
    );

    return () => navigator.geolocation.clearWatch(watchId);
  }, []);

  const locations = useMemo(() => {
    const query = search.trim().toLowerCase();
    return PARK_LOCATIONS.filter((location) =>
      (selectedCategory === "All" || location.category === selectedCategory)
      && (!query || `${location.name} ${location.category} ${location.type} ${location.area}`.toLowerCase().includes(query)),
    );
  }, [search, selectedCategory]);
  const selectedLocation = PARK_LOCATIONS.find((location) => location.id === selectedId) || null;
  const gpsPoint = livePosition ? projectGpsToIllustration(livePosition) : null;
  const gpsIsNearIllustration = gpsPoint && gpsPoint.x >= 35 && gpsPoint.x <= SVG_MAP.width - 35 && gpsPoint.y >= 35 && gpsPoint.y <= SVG_MAP.height - 35;

  const selectLocation = (id) => {
    setSelectedId(id);
    setSelectedCategory("All");
  };

  const resetMap = () => {
    setZoom(1);
    setSelectedId(null);
    setSearch("");
    setSelectedCategory("All");
  };

  return (
    <main className="app-shell">
      <header className="app-topbar">
        <a className="brand-mark" href="#map" aria-label="Wonderla Park Guide home"><span className="brand-burst">W</span><span>WONDERLA<span className="brand-light"> PARK GUIDE</span></span></a>
        <div className="topbar-center"><span className="topbar-pin">⌖</span> Wonderla Bengaluru <span className="topbar-dot">·</span> 12.8343, 77.4010</div>
        <div className={`topbar-live ${livePosition ? "is-live" : gpsError ? "is-error" : ""}`}><span />{livePosition ? "LIVE LOCATION" : gpsError ? "LOCATION OFF" : "LOCATING"}</div>
      </header>

      <div className="map-workspace" id="map">
        <section className="map-stage" aria-label="Interactive illustrated park map">
          <div className="map-caption"><span className="caption-pill"><i />ILLUSTRATED PARK MAP</span><span className="caption-place">A little wonder around every corner</span></div>
          <ParkMap
            zoom={zoom}
            locations={locations}
            selectedLocation={selectedLocation}
            selectedId={selectedId}
            livePosition={livePosition}
            onSelect={selectLocation}
          />
          <div className="map-tools" aria-label="Map controls">
            <button type="button" onClick={() => setZoom((value) => Math.min(2.1, +(value + 0.2).toFixed(1)))} aria-label="Zoom in" title="Zoom in">+</button>
            <button type="button" onClick={() => setZoom((value) => Math.max(0.8, +(value - 0.2).toFixed(1)))} aria-label="Zoom out" title="Zoom out">−</button>
            <span />
            <button type="button" onClick={resetMap} aria-label="Reset map" title="Reset map">⟲</button>
          </div>
          <MapLegend />
          {livePosition && !gpsIsNearIllustration && <div className="off-map-banner">Your GPS coordinates are live. The sample illustration does not cover your current area.</div>}
        </section>

        <LocationPanel
          allLocations={PARK_LOCATIONS}
          locations={locations}
          selectedLocation={selectedLocation}
          selectedCategory={selectedCategory}
          onCategoryChange={(category) => {
            setSelectedCategory(category);
            if (!PARK_LOCATIONS.some((location) => location.id === selectedId && (category === "All" || location.category === category))) setSelectedId(null);
          }}
          search={search}
          onSearchChange={setSearch}
          onSelect={selectLocation}
          gpsStatus={gpsStatus}
          livePosition={livePosition}
        />
      </div>
    </main>
  );
}
