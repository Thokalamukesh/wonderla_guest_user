"use client";
import React, { useCallback, useEffect, useState } from "react";
import ParkEditor from "./ParkEditor";
import UsersPanel from "./UsersPanel";
import MapSettingsPanel from "./MapSettingsPanel";
import type { ParkConfig, ParkSummary } from "../../_lib/types";

type Role = "superadmin" | "park";
interface SessionUser {
  username: string;
  role: Role;
  parkSlug?: string;
}

interface Props {
  user: SessionUser;
  onLogout: () => void;
}

const Dashboard = ({ user, onLogout }: Props) => {
  const isSuper = user.role === "superadmin";
  const [view, setView] = useState<"parks" | "users" | "map">("parks");

  const [parks, setParks] = useState<ParkSummary[]>([]);
  const [selected, setSelected] = useState<string | null>(null);
  const [config, setConfig] = useState<ParkConfig | null>(null);
  const [loading, setLoading] = useState(false);

  const [newName, setNewName] = useState("");
  const [newLocation, setNewLocation] = useState("");
  const [addErr, setAddErr] = useState<string | null>(null);
  const [adding, setAdding] = useState(false);

  const loadParks = useCallback(async () => {
    const res = await fetch("/qr-code/api/parks", { cache: "no-store" });
    const json = await res.json();
    setParks(json.parks || []);
    return (json.parks || []) as ParkSummary[];
  }, []);

  const loadConfig = useCallback(async (slug: string) => {
    setLoading(true);
    try {
      const res = await fetch(`/qr-code/api/parks/${slug}`, { cache: "no-store" });
      const json = await res.json();
      if (json.ok) {
        setConfig(json.config);
        setSelected(slug);
      } else {
        setConfig(null);
      }
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (isSuper) {
      loadParks().then((list) => {
        if (list.length > 0) loadConfig(list[0].slug);
      });
    } else if (user.parkSlug) {
      loadConfig(user.parkSlug);
    }
  }, [isSuper, user.parkSlug, loadParks, loadConfig]);

  const addPark = async (e: React.FormEvent) => {
    e.preventDefault();
    setAddErr(null);
    setAdding(true);
    try {
      const res = await fetch("/qr-code/api/parks", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: newName, location: newLocation }),
      });
      const json = await res.json();
      if (!res.ok || !json.ok) {
        setAddErr(json.error || "Failed to add park");
        return;
      }
      setNewName("");
      setNewLocation("");
      await loadParks();
      loadConfig(json.park.slug);
    } catch {
      setAddErr("Network error");
    } finally {
      setAdding(false);
    }
  };

  const logout = async () => {
    await fetch("/qr-code/api/auth/logout", { method: "POST" });
    onLogout();
  };

  return (
    <div className="min-h-screen bg-slate-100">
      <header className="flex flex-col gap-3 border-b border-slate-200 bg-white px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:px-6 sm:py-4">
        <div className="flex min-w-0 flex-wrap items-center justify-between gap-3 sm:justify-start sm:gap-4">
          <h1 className="text-base font-bold text-slate-800 sm:text-lg">Wonderla QR Admin</h1>
          {isSuper && (
            <nav className="flex gap-1 rounded-lg bg-slate-100 p-1">
              {(["parks", "map", "users"] as const).map((v) => (
                <button
                  key={v}
                  onClick={() => setView(v)}
                  className={`rounded-md px-3 py-1 text-xs font-semibold capitalize ${
                    view === v ? "bg-white text-indigo-700 shadow-sm" : "text-slate-500"
                  }`}
                >
                  {v}
                </button>
              ))}
            </nav>
          )}
        </div>
        <div className="flex items-center justify-between gap-3 sm:justify-end">
          <span className="min-w-0 truncate text-xs text-slate-500">
            {user.username}
            <span
              className={`ml-2 rounded-full px-2 py-0.5 text-[10px] font-semibold ${
                isSuper ? "bg-amber-100 text-amber-800" : "bg-indigo-100 text-indigo-800"
              }`}
            >
              {user.role}
            </span>
          </span>
          <button
            onClick={logout}
            className="rounded-md border border-slate-300 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50"
          >
            Log out
          </button>
        </div>
      </header>

      {/* Superadmin: Users view */}
      {isSuper && view === "users" && (
        <div className="mx-auto max-w-6xl p-6">
          <UsersPanel currentUsername={user.username} />
        </div>
      )}

      {isSuper && view === "map" && <MapSettingsPanel />}

      {/* Parks view (superadmin) OR single-park editor (park user) */}
      {(!isSuper || view === "parks") && (
          <div className="mx-auto flex max-w-6xl flex-col gap-4 p-3 sm:gap-6 sm:p-6 lg:flex-row">
          {isSuper && (
            <aside className="w-full min-w-0 shrink-0 lg:w-64">
              <div className="mb-4 rounded-lg border border-slate-200 bg-white p-3">
                <p className="mb-2 text-xs font-bold uppercase tracking-wide text-slate-500">
                  Parks
                </p>
                <ul className="flex gap-2 overflow-x-auto pb-1 lg:flex-col lg:overflow-visible">
                  {parks.map((p) => (
                    <li key={p.slug} className="min-w-40 flex-1 lg:min-w-0">
                      <button
                        onClick={() => loadConfig(p.slug)}
                        className={`w-full rounded-md px-3 py-2 text-left text-sm ${
                          selected === p.slug
                            ? "bg-indigo-600 text-white"
                            : "text-slate-700 hover:bg-slate-100"
                        }`}
                      >
                        <span className="block font-semibold">{p.name}</span>
                        <span
                          className={`block text-[11px] ${
                            selected === p.slug ? "text-indigo-100" : "text-slate-400"
                          }`}
                        >
                          {p.active ? p.location || p.slug : "Inactive"}
                        </span>
                      </button>
                    </li>
                  ))}
                  {parks.length === 0 && (
                    <li className="px-3 py-2 text-xs text-slate-400">No parks yet.</li>
                  )}
                </ul>
              </div>

              <form onSubmit={addPark} className="rounded-lg border border-slate-200 bg-white p-3">
                <p className="mb-2 text-xs font-bold uppercase tracking-wide text-slate-500">
                  Add park
                </p>
                <input
                  className="mb-2 w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
                  placeholder="Park name (e.g. Wonderla Pune)"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  required
                />
                <input
                  className="mb-2 w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
                  placeholder="Location"
                  value={newLocation}
                  onChange={(e) => setNewLocation(e.target.value)}
                />
                {addErr && <p className="mb-2 text-xs text-red-600">{addErr}</p>}
                <button
                  type="submit"
                  disabled={adding}
                  className="w-full rounded-md bg-indigo-600 py-2 text-xs font-semibold text-white hover:bg-indigo-700 disabled:opacity-60"
                >
                  {adding ? "Adding..." : "Create park"}
                </button>
              </form>
            </aside>
          )}

          <main className="min-w-0 flex-1">
            {loading && <p className="text-sm text-slate-500">Loading…</p>}
            {!loading && config && (
              <ParkEditor
                config={config}
                canManagePark={isSuper}
                onSaved={(c) => {
                  setConfig(c);
                  if (isSuper) loadParks();
                }}
                onDeleted={() => {
                  setConfig(null);
                  setSelected(null);
                  loadParks().then((list) => {
                    if (list.length > 0) loadConfig(list[0].slug);
                  });
                }}
              />
            )}
            {!loading && !config && (
              <p className="text-sm text-slate-500">
                {isSuper
                  ? "Select a park, or create one to begin."
                  : "No park is assigned to your account. Contact an administrator."}
              </p>
            )}
          </main>
        </div>
      )}
    </div>
  );
};

export default Dashboard;
