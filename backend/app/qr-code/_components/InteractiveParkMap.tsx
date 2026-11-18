"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
import type { ParkMapPlace } from "../_lib/types";

const WONDERLA: google.maps.LatLngLiteral = { lat: 12.8343, lng: 77.401 };
const REROUTE_AFTER_METERS = 35;
const KNOWN_PLACE_COORDINATES: Record<string, Coordinates> = {
  recoil: { lat: 12.832685, lng: 77.401272 },
};

declare global {
  interface Window {
    google?: typeof google;
  }
}

type Coordinates = { lat: number; lng: number };
type LiveLocation = Coordinates & { accuracy: number };
type RouteSummary = { distance: string; duration: string; steps: string[] };

let mapsScriptPromise: Promise<void> | null = null;
let mapsBootstrapPromise: Promise<void> | null = null;
let mapsLoaderInstalled = false;

function loadGoogleMaps(apiKey: string): Promise<void> {
  if (mapsScriptPromise) return mapsScriptPromise;
  const existingImportLibrary: unknown = window.google?.maps?.importLibrary;
  if (typeof existingImportLibrary === "function" && !mapsLoaderInstalled) return Promise.resolve();

  const googleNamespace = window.google || (window.google = {} as typeof google);
  const maps = (googleNamespace.maps || (googleNamespace.maps = {} as typeof google.maps)) as typeof google.maps & {
    __ib__?: () => void;
  };
  const requestedLibraries = new Set<string>();
  type DynamicImport = (library: string, ...args: unknown[]) => Promise<unknown>;

  const ensureScript = () => {
    if (mapsBootstrapPromise) return mapsBootstrapPromise;
    mapsBootstrapPromise = new Promise<void>((resolve, reject) => {
      const script = document.createElement("script");
      const params = new URLSearchParams({
        key: apiKey,
        v: "weekly",
        libraries: [...requestedLibraries].join(","),
        callback: "google.maps.__ib__",
      });
      maps.__ib__ = resolve;
      script.src = `https://maps.googleapis.com/maps/api/js?${params.toString()}`;
      script.async = true;
      script.onerror = () => {
        mapsBootstrapPromise = null;
        mapsScriptPromise = null;
        mapsLoaderInstalled = false;
        (maps as unknown as { importLibrary: DynamicImport }).importLibrary = undefined as unknown as DynamicImport;
        reject(new Error("Google Maps could not load. Check the key, enabled APIs, and website restrictions."));
      };
      script.nonce = document.querySelector<HTMLScriptElement>("script[nonce]")?.nonce || "";
      document.head.appendChild(script);
    });
    return mapsBootstrapPromise;
  };

  // Google requires its dynamic-library bootstrap loader to install importLibrary.
  mapsLoaderInstalled = true;
  (maps as unknown as { importLibrary: DynamicImport }).importLibrary = (library, ...args) => {
    requestedLibraries.add(library);
    return ensureScript().then(() =>
      (maps.importLibrary as DynamicImport)(library, ...args)
    );
  };
  mapsScriptPromise = (maps.importLibrary as DynamicImport)("maps")
    .then(() => undefined)
    .catch((error: unknown) => {
      mapsScriptPromise = null;
      throw error;
    });

  return mapsScriptPromise;
}

function distanceInMeters(from: Coordinates, to: Coordinates) {
  const radians = (degrees: number) => degrees * Math.PI / 180;
  const latitudeDelta = radians(to.lat - from.lat);
  const longitudeDelta = radians(to.lng - from.lng);
  const value = Math.sin(latitudeDelta / 2) ** 2
    + Math.cos(radians(from.lat)) * Math.cos(radians(to.lat)) * Math.sin(longitudeDelta / 2) ** 2;
  return 6371000 * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
}

function distanceInKm(from: Coordinates, to: Coordinates) {
  return distanceInMeters(from, to) / 1000;
}

interface Props {
  parkName?: string;
  places?: ParkMapPlace[];
}

export default function InteractiveParkMap({ parkName = "Wonderla Bengaluru", places = [] }: Props) {
  const mapElement = useRef<HTMLDivElement>(null);
  const mapInstance = useRef<google.maps.Map | null>(null);
  const userMarker = useRef<google.maps.Marker | null>(null);
  const destinationMarker = useRef<google.maps.Marker | null>(null);
  const routePolylines = useRef<google.maps.Polyline[]>([]);
  const lastRoutedOrigin = useRef<LiveLocation | null>(null);
  const lastRoutedDestination = useRef<string | null>(null);
  const routeRequestInFlight = useRef<number | null>(null);
  const routeRequestId = useRef(0);
  const [userLocation, setUserLocation] = useState<LiveLocation | null>(null);
  const [locationStatus, setLocationStatus] = useState("Finding your live location…");
  const [mapError, setMapError] = useState("");
  const [mapReady, setMapReady] = useState(false);
  const [activeDestination, setActiveDestination] = useState<ParkMapPlace | null>(null);
  const [routeStatus, setRouteStatus] = useState("");
  const [routeSummary, setRouteSummary] = useState<RouteSummary | null>(null);

  useEffect(() => {
    let active = true;
    fetch("/qr-code/api/map-settings", { cache: "no-store" })
      .then(async (response) => {
        if (!response.ok) throw new Error("Could not load map settings.");
        return response.json() as Promise<{ apiKey?: string }>;
      })
      .then(async ({ apiKey }) => {
        if (!apiKey) throw new Error("Add your Google Maps API key in Admin → Map to show the map.");
        await loadGoogleMaps(apiKey);
        const { Map } = await window.google!.maps.importLibrary("maps") as google.maps.MapsLibrary;
        if (!active || !mapElement.current) return;

        mapInstance.current = new Map(mapElement.current, {
          center: WONDERLA,
          zoom: 16,
          mapTypeId: "roadmap",
          disableDefaultUI: true,
          clickableIcons: false,
          gestureHandling: "greedy",
          zoomControl: true,
        });
        setMapReady(true);
      })
      .catch((error: unknown) => {
        if (active) setMapError(error instanceof Error ? error.message : "Google Maps could not be loaded.");
      });

    return () => {
      active = false;
      routeRequestId.current += 1;
      routeRequestInFlight.current = null;
      routePolylines.current.forEach((polyline) => polyline.setMap(null));
      userMarker.current?.setMap(null);
      destinationMarker.current?.setMap(null);
      mapInstance.current = null;
    };
  }, []);

  useEffect(() => {
    if (!navigator.geolocation) {
      setLocationStatus("Live location is not available in this browser.");
      return;
    }

    const watchId = navigator.geolocation.watchPosition(
      ({ coords }) => {
        setUserLocation({ lat: coords.latitude, lng: coords.longitude, accuracy: coords.accuracy });
        setLocationStatus("Live location active");
      },
      (error) => {
        setLocationStatus(error.code === error.PERMISSION_DENIED
          ? "Allow location access to show your position."
          : "Could not get your location. Check location services.");
      },
      { enableHighAccuracy: true, maximumAge: 3000, timeout: 15000 },
    );

    return () => navigator.geolocation.clearWatch(watchId);
  }, []);

  useEffect(() => {
    const map = mapInstance.current;
    if (!map || !mapReady || !userLocation) return;

    if (!userMarker.current) {
      userMarker.current = new google.maps.Marker({
        map,
        position: userLocation,
        title: "Your live location",
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          fillColor: "#1673e8",
          fillOpacity: 1,
          strokeColor: "#ffffff",
          strokeWeight: 3,
          scale: 9,
        },
        zIndex: 1000,
      });
      map.panTo(userLocation);
    } else {
      userMarker.current.setPosition(userLocation);
    }
  }, [activeDestination, mapReady, userLocation]);

  useEffect(() => {
    const map = mapInstance.current;
    if (!mapReady || !map || !activeDestination) return;
    if (!userLocation) {
      setRouteStatus("Allow location access to calculate a walking route.");
      return;
    }

    const previousOrigin = lastRoutedOrigin.current;
    // GPS can emit frequent updates while Google is still calculating. Keep that
    // request alive instead of cancelling it and starting over on every update.
    if (routeRequestInFlight.current !== null) return;
    if (
      previousOrigin
      && lastRoutedDestination.current === activeDestination.name
      && distanceInMeters(previousOrigin, userLocation) < REROUTE_AFTER_METERS
    ) return;

    const timeout = window.setTimeout(async () => {
      const requestId = ++routeRequestId.current;
      routeRequestInFlight.current = requestId;
      setRouteStatus("Finding the walking route…");

      try {
        const { Route } = await google.maps.importLibrary("routes") as google.maps.RoutesLibrary;
        const knownCoordinates = KNOWN_PLACE_COORDINATES[activeDestination.name.trim().toLowerCase()];
        let googlePlace: google.maps.places.Place | null = null;
        try {
          const { Place } = await google.maps.importLibrary("places") as google.maps.PlacesLibrary;
          const search = await Place.searchByText({
            textQuery: `${activeDestination.name}, ${parkName}`,
            fields: ["id", "displayName", "location"],
            locationBias: { center: WONDERLA, radius: 1500 },
            maxResultCount: 8,
            region: "IN",
          });
          const candidates = (search.places || [])
            .filter((place) => place.id && place.location)
            .filter((place) => distanceInMeters(WONDERLA, place.location!.toJSON()) <= 1500);
          const reference = knownCoordinates ?? WONDERLA;
          candidates.sort((a, b) =>
            distanceInMeters(reference, a.location!.toJSON()) - distanceInMeters(reference, b.location!.toJSON())
          );
          googlePlace = candidates[0] ?? null;
        } catch {
          // Use configured coordinates/text when Places API is not enabled or has no match.
        }
        const destinationCoordinates = typeof activeDestination.lat === "number" && typeof activeDestination.lng === "number"
          ? { lat: activeDestination.lat, lng: activeDestination.lng }
          : knownCoordinates;
        const response = await Route.computeRoutes({
          origin: { lat: userLocation.lat, lng: userLocation.lng },
          destination: googlePlace?.id
            ? new google.maps.places.Place({ id: googlePlace.id })
            : destinationCoordinates || `${activeDestination.name}, ${parkName}, India`,
          travelMode: google.maps.TravelMode.WALKING,
          language: "en",
          units: google.maps.UnitSystem.METRIC,
          fields: [
            "path",
            "distanceMeters",
            "durationMillis",
            "localizedValues",
            // Request the parent Route field. The JS Routes API rejects
            // nested legs.steps field paths in this request's field mask.
            "legs",
          ],
        });

        if (requestId !== routeRequestId.current) return;
        const route = response.routes?.[0];
        if (!route) throw new Error("Google Maps could not find a walking route to this place.");

        routePolylines.current.forEach((polyline) => polyline.setMap(null));
        routePolylines.current = route.createPolylines({
          polylineOptions: {
            strokeColor: "#1673e8",
            strokeOpacity: 0.94,
            strokeWeight: 7,
            zIndex: 900,
          },
        });
        routePolylines.current.forEach((polyline) => polyline.setMap(map));

        const path = route.path ?? [];
        if (!path.length || !routePolylines.current.length) {
          throw new Error("Google returned directions without a route line. Check that this place has a mapped location.");
        }
        if (path.length) {
          const end = path[path.length - 1];
          if (!destinationMarker.current) {
            destinationMarker.current = new google.maps.Marker({
              map,
              position: end,
              title: activeDestination.name,
              label: { text: activeDestination.name.slice(0, 1), color: "#ffffff", fontWeight: "700" },
              icon: {
                path: google.maps.SymbolPath.CIRCLE,
                fillColor: "#e11d48",
                fillOpacity: 1,
                strokeColor: "#ffffff",
                strokeWeight: 3,
                scale: 10,
              },
              zIndex: 950,
            });
          } else {
            destinationMarker.current.setPosition(end);
            destinationMarker.current.setTitle(activeDestination.name);
            destinationMarker.current.setLabel({ text: activeDestination.name.slice(0, 1), color: "#ffffff", fontWeight: "700" });
          }

          const destinationChanged = lastRoutedDestination.current !== activeDestination.name;
          if (destinationChanged) {
            const bounds = new google.maps.LatLngBounds();
            path.forEach((point) => bounds.extend(point));
            map.fitBounds(bounds, 56);
          }
        }

        const steps = (route.legs ?? [])
          .flatMap((leg) => leg.steps ?? [])
          .map((step) => step.instructions)
          .filter((instruction): instruction is string => Boolean(instruction));
        setRouteSummary({
          distance: route.localizedValues?.distance || `${((route.distanceMeters ?? 0) / 1000).toFixed(1)} km`,
          duration: route.localizedValues?.staticDuration || `${Math.max(1, Math.round((route.durationMillis ?? 0) / 60000))} min`,
          steps,
        });
        lastRoutedOrigin.current = userLocation;
        lastRoutedDestination.current = activeDestination.name;
        setRouteStatus("Walking route ready");
      } catch (error) {
        if (requestId !== routeRequestId.current) return;
        setRouteSummary(null);
        setRouteStatus(error instanceof Error ? error.message : "Could not calculate a walking route.");
      } finally {
        if (routeRequestInFlight.current === requestId) routeRequestInFlight.current = null;
      }
    }, 700);

    return () => {
      window.clearTimeout(timeout);
    };
  }, [activeDestination, mapReady, parkName, userLocation]);

  const centerOnUser = useCallback(() => {
    const map = mapInstance.current;
    if (map) map.panTo(userLocation ?? WONDERLA);
  }, [userLocation]);

  const selectDestination = useCallback((place: ParkMapPlace) => {
    routePolylines.current.forEach((polyline) => polyline.setMap(null));
    routePolylines.current = [];
    destinationMarker.current?.setMap(null);
    destinationMarker.current = null;
    lastRoutedOrigin.current = null;
    lastRoutedDestination.current = null;
    routeRequestId.current += 1;
    routeRequestInFlight.current = null;
    setRouteSummary(null);
    setRouteStatus(userLocation ? "Finding the walking route…" : "Waiting for live location…");
    setActiveDestination(place);
  }, [userLocation]);

  const clearRoute = useCallback(() => {
    routeRequestId.current += 1;
    routePolylines.current.forEach((polyline) => polyline.setMap(null));
    routePolylines.current = [];
    destinationMarker.current?.setMap(null);
    destinationMarker.current = null;
    lastRoutedOrigin.current = null;
    lastRoutedDestination.current = null;
    routeRequestId.current += 1;
    routeRequestInFlight.current = null;
    setActiveDestination(null);
    setRouteSummary(null);
    setRouteStatus("");
  }, []);

  const distance = userLocation ? distanceInKm(userLocation, WONDERLA) : null;

  return (
    <section className="grid h-full min-h-0 w-full grid-rows-[minmax(0,1fr)_minmax(0,1fr)] overflow-hidden bg-white lg:grid-cols-2 lg:grid-rows-1">
      <div className="relative z-0 min-h-0 overflow-hidden bg-[#e9eef0]">
        <div ref={mapElement} className="absolute inset-0" aria-label="Google map showing your live location and walking routes" />

        {mapError ? (
          <div className="absolute inset-0 z-10 flex items-center justify-center bg-slate-50 p-6 text-center">
            <div className="max-w-sm">
              <p className="font-bold text-slate-800">Google Map unavailable</p>
              <p className="mt-2 text-sm leading-relaxed text-slate-600">{mapError}</p>
              <p className="mt-2 text-xs text-slate-500">Check that Maps JavaScript API and Routes API are enabled and the website is allowed by the key restrictions.</p>
            </div>
          </div>
        ) : !mapReady ? (
          <div className="absolute inset-0 z-10 flex items-center justify-center text-sm text-slate-600">Loading Google Maps…</div>
        ) : null}

        {mapReady && activeDestination && (
          <div className="pointer-events-none absolute left-3 top-3 z-20 max-w-[calc(100%-24px)] rounded-xl bg-white/95 px-3 py-2.5 shadow-md">
            <p className="text-[10px] font-extrabold uppercase tracking-[0.13em] text-[#386da9]">Live walking route</p>
            <p className="truncate text-sm font-extrabold text-[#191919]">{activeDestination.name}</p>
          </div>
        )}

        {mapReady && (
          <button
            type="button"
            onClick={centerOnUser}
            className="absolute bottom-5 right-4 z-20 flex size-12 items-center justify-center rounded-full bg-white text-xl text-[#191919] shadow-lg transition hover:bg-[#f5f5f5] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#1673e8]"
            aria-label="Center map on my location"
            title="Center map on my location"
          >
            ◎
          </button>
        )}

        {mapReady && !activeDestination && (
          <div className="pointer-events-none absolute bottom-4 left-3 z-20 flex items-center gap-2 rounded-full bg-white px-3 py-2 text-[11px] font-bold text-[#454545] shadow-md">
            <i className="size-2.5 rounded-full bg-[#1673e8]" />Your live location
          </div>
        )}
      </div>

      <aside className="park-map-scroll-panel relative z-10 min-h-0 overflow-y-auto overscroll-contain rounded-t-[24px] border-t border-[#dbe4f0] bg-[#f4f7fc] px-4 pb-5 pt-2 shadow-[0_-4px_16px_rgba(24,61,154,0.08)] lg:rounded-none lg:border-l lg:border-t-0 lg:px-5 lg:pt-5 lg:shadow-none">
        <div className="mx-auto mb-3 h-1.5 w-10 rounded-full bg-[#d8d8d8] lg:hidden" aria-hidden="true" />
        <div className="mx-auto max-w-xl">
          <div className="flex items-center justify-between gap-3">
            <div>
              <p className="text-[10px] font-extrabold uppercase tracking-[0.16em] text-[#315ec0]">Explore Wonderla</p>
              <h1 className="mt-0.5 text-xl font-extrabold tracking-tight text-[#142653]">Available in the park</h1>
            </div>
            <span className="rounded-full bg-[#fff5c2] px-3 py-1.5 text-xs font-extrabold text-[#705900]">{places.length} places</span>
          </div>

          <article className="mt-3 flex items-center gap-3 rounded-xl border border-[#dbe4f0] bg-white px-3 py-2.5 shadow-sm">
            <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-[#eaf2ff] text-[#1673e8]">●</span>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-bold text-[#191919]">Your location</p>
              <p className="truncate text-xs text-[#777]">{locationStatus}</p>
            </div>
            <span className={`size-2.5 shrink-0 rounded-full ${userLocation ? "bg-[#477fdf]" : "bg-slate-300"}`} />
          </article>

          {activeDestination && (
            <article className="mt-3 rounded-xl border border-[#d7e7ff] bg-[#f4f8ff] px-3 py-2.5">
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0 flex-1">
                  <p className="text-[10px] font-extrabold uppercase tracking-[0.13em] text-[#386da9]">{routeStatus}</p>
                  <p className="mt-0.5 truncate text-sm font-bold text-[#202020]">To {activeDestination.name}</p>
                </div>
                {routeSummary && <span className="shrink-0 text-right text-xs font-bold text-[#386da9]">{routeSummary.distance}<br />{routeSummary.duration}</span>}
              </div>
              {routeSummary?.steps.length ? (
                <ol className="mt-2 space-y-1.5 border-t border-[#d7e7ff] pt-2">
                  {routeSummary.steps.slice(0, 8).map((step, index) => (
                    <li key={`${index}-${step}`} className="flex gap-2 text-xs leading-relaxed text-[#4d4d4d]">
                      <span className="font-bold text-[#1673e8]">{index + 1}.</span><span>{step}</span>
                    </li>
                  ))}
                </ol>
              ) : null}
              {routeSummary && routeSummary.steps.length === 0 && (
                <p className="mt-2 border-t border-[#d7e7ff] pt-2 text-xs leading-relaxed text-[#4d4d4d]">
                  Follow the blue walking path on the map to {activeDestination.name}.
                </p>
              )}
              {routeSummary && (
                <p className="mt-2 text-[10px] leading-relaxed text-[#777]">Walking routes can miss some pedestrian paths. Follow park signs and staff directions.</p>
              )}
              <button
                type="button"
                onClick={clearRoute}
                className="mt-2 text-xs font-bold text-[#386da9] underline underline-offset-2"
              >
                Clear route
              </button>
            </article>
          )}

          <div className="mt-3 space-y-2">
            {places.map((place) => {
              const isActive = activeDestination?.name === place.name;
              return (
                <button
                  key={`${place.name}-${place.category}`}
                  type="button"
                  onClick={() => selectDestination(place)}
                  disabled={!mapReady}
                  aria-pressed={isActive}
                  data-scroll-reveal
                  className={`flex min-h-[58px] w-full items-center gap-3 rounded-xl border px-3 py-2 text-left transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#477fdf] disabled:cursor-wait disabled:opacity-55 ${isActive ? "border-[#adc7f6] bg-[#eaf1ff]" : "border-[#dbe4f0] bg-white hover:border-[#bfd1f6] hover:bg-[#f7f9fd]"}`}
                >
                  <span
                    className="flex size-11 shrink-0 items-center justify-center overflow-hidden rounded-full border border-[#d1def7] bg-[#e4edff] bg-cover bg-center text-sm font-extrabold text-[#31508e]"
                    style={{
                      backgroundImage: `url("${place.avatarImage || "/wonderla/parks/bengaluru-layout.jpg"}")`,
                      backgroundSize: place.avatarImage ? "cover" : "350% auto",
                      backgroundPosition: place.avatarImage ? "center" : `${place.x}% ${place.y}%`,
                    }}
                    aria-hidden="true"
                  />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-bold text-[#222]">{place.name}</span>
                    <span className="mt-0.5 block text-xs text-[#858585]">{place.category}</span>
                  </span>
                  <span className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-extrabold ${isActive ? "bg-[#244bb0] text-white" : "bg-[#e2ebff] text-[#244b9c]"}`}>
                    {isActive ? "Routing" : "Navigate"}
                  </span>
                </button>
              );
            })}
            {places.length === 0 && (
              <p className="rounded-xl bg-[#f7f7f7] p-3 text-sm text-[#777]">Park locations have not been added yet.</p>
            )}
          </div>

          {!activeDestination && (
            <p className="mt-3 text-center text-[11px] leading-relaxed text-[#858585]">
              {userLocation && distance !== null ? `${distance < 1 ? `${Math.round(distance * 1000)} m` : `${distance.toFixed(1)} km`} from Wonderla` : mapError || "Allow location access to get walking directions from where you are."}
            </p>
          )}
        </div>
      </aside>
    </section>
  );
}
