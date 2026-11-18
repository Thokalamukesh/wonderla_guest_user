# Wonderla QR-code module

A per-park, QR-driven info experience with a single admin panel to configure
each park. Parks are data-driven — new parks can be added any time from the
admin UI, so this scales as Wonderla opens more locations.

## Routes

| Route                    | What it is                                              |
|--------------------------|---------------------------------------------------------|
| `/qr-code`               | Park directory (lists active parks) + link to admin     |
| `/qr-code/<park-slug>`   | The guest experience for one park (point QR codes here) |
| `/qr-code/admin`         | Admin login + configuration dashboard                   |

**QR codes:** generate one per park pointing at `https://<your-domain>/qr-code/<slug>`,
e.g. `/qr-code/bengaluru`, `/qr-code/chennai`.

## Seeded parks

On first run the store seeds 5 parks: `bengaluru`, `kochi`, `hyderabad`,
`bhubaneswar`, `chennai`. Add more from the admin panel (slug is derived from
the name, e.g. "Wonderla Pune" → `pune`).

## Data storage

Each park is one JSON file under `data/qr-code/parks/<slug>.json`
(configurable via `QR_DATA_DIR`). No database required. Swapping to a real DB
later only means reimplementing `_lib/store.ts`.

> Decide whether to commit `data/qr-code/` or gitignore it. Committing gives
> you versioned content; ignoring keeps prod content out of the repo.

## Users & roles

Two roles, managed at `/qr-code/admin`:

- **superadmin** — full access: edit any park, add/delete parks, toggle a
  park active/inactive, and create/delete users (Admin → **Users** tab).
- **park** — scoped to ONE park. Can edit only that park's content
  (rides, events, menu, wait times, etc.). Cannot add/delete parks, cannot
  change the active flag, and has no Users tab.

**Creating park-level users:** sign in as superadmin → **Users** tab →
*Add user* → set username/password, pick role **Park user**, choose the park.
That user then signs in at the same `/qr-code/admin` and sees only their
park's editor.

Users live in `data/qr-code/users.json`; passwords are salted + scrypt-hashed
(never stored in plaintext). On first run a single superadmin is seeded from
`QR_ADMIN_USERNAME` / `QR_ADMIN_PASSWORD`. Those env credentials also act as a
permanent bootstrap superadmin, so you can never lock yourself out even if
`users.json` is lost.

Login sets an HMAC-signed, httpOnly session cookie (8h) that carries the
user's identity + role + park, so the API enforces per-park access. Reads are
public; all writes require a valid session with the right role.

## API (under `/qr-code/api`)

| Method | Path                     | Auth  | Purpose                 |
|--------|--------------------------|-------|-------------------------|
| POST   | `/auth/login`            | —     | Sign in                 |
| POST   | `/auth/logout`           | —     | Sign out                |
| GET    | `/auth/session`          | —     | Is the caller signed in |
| GET    | `/parks`                 | —     | List park summaries     |
| POST   | `/parks`                 | super | Create a park           |
| GET    | `/parks/<slug>`          | —     | Full config for a park  |
| PUT    | `/parks/<slug>`          | owner | Replace a park's config |
| DELETE | `/parks/<slug>`          | super | Delete a park           |
| GET    | `/users`                 | super | List users              |
| POST   | `/users`                 | super | Create a user           |
| DELETE | `/users/<username>`      | super | Delete a user           |

Auth levels: **—** public · **owner** = superadmin or the park's own user ·
**super** = superadmin only. (`PUT /parks/<slug>` is **owner**.)

## Config shape

See `_lib/types.ts`. Each park has: `rides`, `events`, `liveWaitTimes`,
`waveRainDance`, `safetyHygiene`, `maintenanceLog`, `parkMap`, `dining`,
`rideGuidelines`, plus `name` / `location` / `active`.

## Notes / assumptions

- Relies on the parent app's Tailwind custom colors `bg-blue` / `bg-yellow`
  and the `@/assets/svgs/Icons` `LeftArrow`, both already used by the original
  code. Admin UI uses only default Tailwind colors.
- Images are referenced by URL (paste a URL in admin). Empty URL → the
  existing yellow placeholder is shown.
- "Refresh" on Live Wait Times & Maintenance Log now re-fetches the park
  config from the API.
- `main.tsx` at the module root is a deprecated stub (could not be deleted in
  this workspace); it is not imported anywhere.
