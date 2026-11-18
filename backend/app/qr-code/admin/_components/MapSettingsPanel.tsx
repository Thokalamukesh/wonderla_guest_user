"use client";

import React, { FormEvent, useEffect, useState } from "react";

export default function MapSettingsPanel() {
  const [apiKey, setApiKey] = useState("");
  const [configured, setConfigured] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    fetch("/qr-code/api/map-settings", { cache: "no-store" })
      .then(async (response) => {
        if (!response.ok) throw new Error("Could not load map settings.");
        return response.json();
      })
      .then((data) => setConfigured(Boolean(data.apiKey)))
      .catch((reason: unknown) => setError(reason instanceof Error ? reason.message : "Could not load map settings."))
      .finally(() => setLoading(false));
  }, []);

  const save = async (event: FormEvent) => {
    event.preventDefault();
    setSaving(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch("/qr-code/api/map-settings", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ apiKey }),
      });
      const data = await response.json();
      if (!response.ok || !data.ok) throw new Error(data.error || "Could not save the key.");
      setConfigured(Boolean(apiKey.trim()));
      setApiKey("");
      setMessage(apiKey.trim() ? "Map API key saved. Reload the park map to use it." : "Saved. The map API key has been cleared.");
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Could not save the key.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <main className="mx-auto max-w-3xl p-4 sm:p-6">
      <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
        <h2 className="text-lg font-bold text-slate-800">Google Maps settings</h2>
        <p className="mt-1 text-sm leading-relaxed text-slate-600">
          Add your browser API key here. Saving it makes the map use it without changing Vercel environment variables.
        </p>
        <div className="mt-4 rounded-lg bg-amber-50 p-3 text-xs leading-relaxed text-amber-900">
          The map key is sent to visitors’ browsers so Google Maps can load. In Google Cloud Console, enable Maps JavaScript API, Routes API, and Places API (New). Restrict the key to those APIs and allow your Vercel and custom domains as website referrers.
        </div>
        <form onSubmit={save} className="mt-5 space-y-3">
          <label className="block text-sm font-semibold text-slate-700" htmlFor="maps-api-key">Google Maps API key</label>
          <input
            id="maps-api-key"
            type="password"
            autoComplete="new-password"
            value={apiKey}
            onChange={(event) => setApiKey(event.target.value)}
            placeholder={configured ? "Key is saved. Enter a new key to replace it." : "Paste your Google Maps API key"}
            className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
            disabled={loading || saving}
          />
          <div className="flex flex-wrap items-center gap-3">
            <button type="submit" disabled={!apiKey.trim() || loading || saving} className="rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-indigo-700 disabled:opacity-50">
              {saving ? "Saving…" : "Save API key"}
            </button>
            <span className="text-xs text-slate-500">{loading ? "Loading settings…" : configured ? "A key is configured." : "No key is configured."}</span>
          </div>
        </form>
        {message && <p role="status" className="mt-3 text-sm text-emerald-700">{message}</p>}
        {error && <p role="alert" className="mt-3 text-sm text-red-600">{error}</p>}
      </section>
    </main>
  );
}
