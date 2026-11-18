"use client";
import React, { useCallback, useEffect, useState } from "react";
import type { ParkSummary } from "../../_lib/types";

type Role = "superadmin" | "park";
interface PublicUser {
  username: string;
  role: Role;
  parkSlug?: string;
  createdAt: string;
}

const UsersPanel = ({ currentUsername }: { currentUsername: string }) => {
  const [users, setUsers] = useState<PublicUser[]>([]);
  const [parks, setParks] = useState<ParkSummary[]>([]);

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState<Role>("park");
  const [parkSlug, setParkSlug] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    const [u, p] = await Promise.all([
      fetch("/qr-code/api/users", { cache: "no-store" }).then((r) => r.json()),
      fetch("/qr-code/api/parks", { cache: "no-store" }).then((r) => r.json()),
    ]);
    setUsers(u.users || []);
    setParks(p.parks || []);
    if (!parkSlug && p.parks?.length) setParkSlug(p.parks[0].slug);
  }, [parkSlug]);

  useEffect(() => {
    load();
  }, [load]);

  const create = async (e: React.FormEvent) => {
    e.preventDefault();
    setErr(null);
    setBusy(true);
    try {
      const res = await fetch("/qr-code/api/users", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          username,
          password,
          role,
          parkSlug: role === "park" ? parkSlug : undefined,
        }),
      });
      const json = await res.json();
      if (!res.ok || !json.ok) {
        setErr(json.error || "Failed to create user");
        return;
      }
      setUsername("");
      setPassword("");
      setRole("park");
      await load();
    } catch {
      setErr("Network error");
    } finally {
      setBusy(false);
    }
  };

  const remove = async (name: string) => {
    if (!confirm(`Delete user "${name}"?`)) return;
    const res = await fetch(`/qr-code/api/users/${encodeURIComponent(name)}`, {
      method: "DELETE",
    });
    const json = await res.json().catch(() => ({}));
    if (!res.ok || !json.ok) {
      alert(json.error || "Delete failed");
      return;
    }
    load();
  };

  const parkName = (slug?: string) =>
    parks.find((p) => p.slug === slug)?.name || slug || "—";

  return (
    <div className="grid gap-6 md:grid-cols-[1fr_320px]">
      {/* Existing users */}
      <section className="min-w-0 rounded-lg border border-slate-200 bg-white p-3 sm:p-4">
        <h3 className="mb-3 text-sm font-bold uppercase tracking-wide text-slate-700">Users</h3>
        <div className="overflow-x-auto">
        <table className="w-full min-w-[480px] text-sm">
          <thead>
            <tr className="border-b border-slate-200 text-left text-xs text-slate-500">
              <th className="py-2">Username</th>
              <th className="py-2">Role</th>
              <th className="py-2">Park</th>
              <th className="py-2"></th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.username} className="border-b border-slate-100">
                <td className="py-2 font-medium text-slate-800">{u.username}</td>
                <td className="py-2">
                  <span
                    className={`rounded-full px-2 py-0.5 text-[11px] font-semibold ${
                      u.role === "superadmin"
                        ? "bg-amber-100 text-amber-800"
                        : "bg-indigo-100 text-indigo-800"
                    }`}
                  >
                    {u.role}
                  </span>
                </td>
                <td className="py-2 text-slate-600">
                  {u.role === "park" ? parkName(u.parkSlug) : "All"}
                </td>
                <td className="py-2 text-right">
                  {u.username !== currentUsername && (
                    <button
                      onClick={() => remove(u.username)}
                      className="text-xs font-semibold text-red-600 hover:underline"
                    >
                      Delete
                    </button>
                  )}
                </td>
              </tr>
            ))}
            {users.length === 0 && (
              <tr>
                <td colSpan={4} className="py-3 text-xs text-slate-400">
                  No users yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
        </div>
      </section>

      {/* Create user */}
      <form onSubmit={create} className="h-fit rounded-lg border border-slate-200 bg-white p-4">
        <h3 className="mb-3 text-sm font-bold uppercase tracking-wide text-slate-700">
          Add user
        </h3>
        <label className="mb-1 block text-xs font-semibold text-slate-600">Username</label>
        <input
          className="mb-3 w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          required
        />
        <label className="mb-1 block text-xs font-semibold text-slate-600">Password</label>
        <input
          type="password"
          className="mb-3 w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          minLength={6}
          required
        />
        <label className="mb-1 block text-xs font-semibold text-slate-600">Role</label>
        <select
          className="mb-3 w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
          value={role}
          onChange={(e) => setRole(e.target.value as Role)}
        >
          <option value="park">Park user (edits one park)</option>
          <option value="superadmin">Superadmin (full access)</option>
        </select>

        {role === "park" && (
          <>
            <label className="mb-1 block text-xs font-semibold text-slate-600">Park</label>
            <select
              className="mb-3 w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
              value={parkSlug}
              onChange={(e) => setParkSlug(e.target.value)}
            >
              {parks.map((p) => (
                <option key={p.slug} value={p.slug}>
                  {p.name}
                </option>
              ))}
            </select>
          </>
        )}

        {err && <p className="mb-3 text-xs text-red-600">{err}</p>}
        <button
          type="submit"
          disabled={busy}
          className="w-full rounded-md bg-indigo-600 py-2 text-xs font-semibold text-white hover:bg-indigo-700 disabled:opacity-60"
        >
          {busy ? "Creating..." : "Create user"}
        </button>
      </form>
    </div>
  );
};

export default UsersPanel;
