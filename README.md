# Wonderla Bengaluru Map

The app uses `flutter_map` with OpenStreetMap tiles and is initially centered on Wonderla Bengaluru (12.8343, 77.4010). On phones the map and in-park location list each use about half the screen; on wider layouts they sit side by side. The map requests device location at runtime and displays the live position when access is available. Chillies, Greens, the multipurpose hall, Wave Pools 1 and 2, Lazy River, and parking are included from verified OpenStreetMap features. Search also finds nearby mapped results when submitted. Selecting a destination starts a walking route, and live GPS updates can trigger an off-route recalculation.

## Map services

- OpenStreetMap raster tiles: [tile usage policy](https://operations.osmfoundation.org/policies/tiles/).
- In-park place data: Overpass API.
- User-submitted nearby search: Nominatim, limited to the Wonderla area and never requested for each keystroke; follow the [Nominatim usage policy](https://operations.osmfoundation.org/policies/nominatim/).
- Walking paths: public FOSSGIS OSRM foot router. Public community services have rate limits and no uptime guarantee; deploy a suitable hosted or self-hosted routing service before scaling production traffic.

The Wonderla PDF is used only as a visual reference. Park attractions and internal paths are not invented; OpenStreetMap coverage may not include rides inside the park. Configure verified attraction coordinates when they are available. The map keeps a close minimum zoom so visitors do not zoom out to a city view.

On Android, grant location permission and enable device location. If the map reports a DNS lookup failure for `tile.openstreetmap.org`, resolve the emulator/device network DNS issue; retrying tiles cannot repair DNS configuration.

## Visitor guide and CMS

The app opens on the responsive Wonderla visitor guide. The Park Map tile launches the existing Flutter map screen; its map, place search, GPS and walking navigation implementation is unchanged. The guide and CMS use the blue and yellow from `assets/images/wonderla_logo.webp`.

The CMS client at `lib/features/cms/cms_screen.dart` uses the existing Next.js endpoints under `/qr-code/api`. This repository contains the Flutter client; the Next.js CMS/API must also be running for park data and admin login to work. Local Chrome runs default to that server at `http://localhost:3000`. To use a different backend, pass `API_BASE_URL` (this override also applies to Flutter web):

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

The Flutter web app uses credentialed requests so the existing admin session cookie is retained. The Next.js middleware permits localhost Flutter origins only in development. For an independent production Flutter web origin, set `FLUTTER_WEB_ORIGIN` on Next.js to the exact Flutter site origin. For Android/iOS, pass the backend origin at build/run time; Android emulators typically reach a host machine using `10.0.2.2`:

```sh
flutter run --dart-define=API_BASE_URL=https://your-site.example
```

The CMS uses the existing admin login and session cookie. It supports superadmin and park editor roles, park creation/deletion and active status, park content CRUD, map image/places/zones, users, Google Maps settings, and the existing image upload endpoint. Images may be PNG, JPG, WebP, or GIF up to 5 MB. The picker uploads the image immediately; click **Save changes** to save the park configuration that points to it. The welcome banner also supports an optional video (`heroVideoUrl`), which plays muted in a loop in place of its image. Video uploads use `POST /qr-code/api/parks/{slug}/videos` with the multipart field `video`, and expect an `{ "ok": true, "url": "..." }` response. The Flutter repository does not include the remote Next.js API, so that video endpoint must be implemented on the connected backend for direct uploads to work; pasting a hosted video URL works without that upload route. The app contains no admin password or server secret.

The existing backend must be deployed and reachable. For production uploads and persistent park/user data, configure the Vercel Blob store as required by the Next.js project. Flutter web on a different origin also needs the backend to permit credentialed CORS; deploying the web client on the same origin avoids that extra setup. QR URLs continue to resolve to the React website's `/qr-code/{slug}` fallback.
