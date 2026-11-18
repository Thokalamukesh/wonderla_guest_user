import React from "react";
import { CATEGORIES } from "../data/parkMapData.js";

function LocationCard({ location, active, onClick }) {
  return (
    <button type="button" className={`location-card ${active ? "active" : ""}`} onClick={onClick} aria-pressed={active}>
      <span className="location-icon" style={{ "--location-color": location.color }}>{location.icon}</span>
      <span className="location-card-copy">
        <span className="location-card-name">{location.name}</span>
        <span className="location-card-meta">{location.type}<span className="meta-separator">·</span>{location.area}</span>
      </span>
      <span className="location-card-arrow" aria-hidden="true">↗</span>
    </button>
  );
}

export default function LocationPanel({
  allLocations,
  locations,
  selectedLocation,
  selectedCategory,
  onCategoryChange,
  search,
  onSearchChange,
  onSelect,
  gpsStatus,
  livePosition,
}) {
  return (
    <aside className="location-panel">
      <div className="panel-heading">
        <div>
          <div className="eyebrow"><span className="eyebrow-sparkle">✳</span> WONDERLA · BENGALURU</div>
          <h1>Park guide</h1>
          <p className="panel-subtitle">Find your next little adventure.</p>
        </div>
        <span className="park-status"><span />OPEN MAP</span>
      </div>

      <div className="search-box">
        <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="10.8" cy="10.8" r="6.8" /><path d="m16 16 5 5" /></svg>
        <input
          type="search"
          value={search}
          onChange={(event) => onSearchChange(event.target.value)}
          placeholder="Search rides, food, facilities"
          aria-label="Search rides, food and facilities"
        />
        {search && <button type="button" onClick={() => onSearchChange("")} aria-label="Clear search">×</button>}
      </div>

      <div className="gps-card">
        <div className={`gps-card-icon ${livePosition ? "active" : ""}`}><span /></div>
        <div className="gps-card-copy">
          <strong>{livePosition ? "Your live location" : "Your location"}</strong>
          <span>{gpsStatus}</span>
          {livePosition && <small>{livePosition.latitude.toFixed(5)}° {livePosition.latitude < 0 ? "S" : "N"}, {livePosition.longitude.toFixed(5)}° {livePosition.longitude < 0 ? "W" : "E"} <i>±{Math.round(livePosition.accuracy)} m</i></small>}
        </div>
        <span className={`gps-state-dot ${livePosition ? "on" : ""}`} />
      </div>

      {selectedLocation && (
        <div className="selected-place-card">
          <div className="selected-place-topline"><span>SELECTED PLACE</span><span className="sample-tag">SAMPLE</span></div>
          <div className="selected-place-title"><span className="selected-place-icon" style={{ "--location-color": selectedLocation.color }}>{selectedLocation.icon}</span><div><h2>{selectedLocation.name}</h2><p>{selectedLocation.type} <span>·</span> {selectedLocation.area}</p></div></div>
          <p className="selected-place-description">{selectedLocation.description}</p>
          <div className="route-preview"><span className="route-line-icon"><i /></span><span><strong>Walking path preview</strong><small>Illustrative sample route · no ETA</small></span><span className="route-arrow">↗</span></div>
        </div>
      )}

      <div className="locations-head">
        <div><h2>Explore the park</h2><p>{locations.length} {locations.length === 1 ? "place" : "places"} shown</p></div>
        <span className="location-total">{allLocations.length}</span>
      </div>
      <div className="category-filters" role="group" aria-label="Filter places by category">
        {CATEGORIES.map((category) => <button key={category} type="button" className={selectedCategory === category ? "selected" : ""} onClick={() => onCategoryChange(category)} aria-pressed={selectedCategory === category}>{category}</button>)}
      </div>

      <div className="location-list" aria-live="polite">
        {locations.map((location) => <LocationCard key={location.id} location={location} active={selectedLocation?.id === location.id} onClick={() => onSelect(location.id)} />)}
        {locations.length === 0 && <div className="empty-results"><span>⌕</span><strong>No matching places</strong><p>Try another search or category.</p></div>}
      </div>
      <div className="panel-footnote"><span>ⓘ</span> Ride positions and paths are sample data, not surveyed park directions.</div>
    </aside>
  );
}
