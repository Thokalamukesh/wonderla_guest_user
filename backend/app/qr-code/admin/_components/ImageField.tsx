"use client";
import React, { useState } from "react";

export default function ImageField({ label, value, onChange, parkSlug }: { label: string; value: string; onChange: (url: string) => void; parkSlug: string }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function upload(file?: File) {
    if (!file) return;
    setError("");
    if (!file.type.startsWith("image/") || file.size > 5 * 1024 * 1024) {
      setError("Choose an image under 5 MB.");
      return;
    }
    setBusy(true);
    try {
      const form = new FormData();
      form.set("image", file);
      const response = await fetch(`/qr-code/api/parks/${parkSlug}/images`, { method: "POST", body: form });
      const json = await response.json();
      if (!response.ok || !json.ok) throw new Error(json.error || "Upload failed");
      onChange(json.url);
      window.alert("Image uploaded successfully");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Upload failed");
    } finally {
      setBusy(false);
    }
  }

  return <div className="block">
    <label className="mb-1 block text-xs font-semibold text-slate-600">{label}</label>
    <div className="flex flex-col gap-2 sm:flex-row">
      <input className="min-w-0 flex-1 rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500" value={value || ""} placeholder="Paste image URL or upload below" onChange={(e) => onChange(e.target.value)} />
      <label className={`cursor-pointer rounded-md border border-indigo-200 px-3 py-2 text-center text-xs font-semibold text-indigo-700 hover:bg-indigo-50 ${busy ? "opacity-60" : ""}`}>
        {busy ? "Uploading…" : "📤 Upload image"}
        <input className="sr-only" type="file" accept="image/png,image/jpeg,image/webp,image/gif" disabled={busy} onChange={(e) => { void upload(e.target.files?.[0]); e.currentTarget.value = ""; }} />
      </label>
    </div>
    {error && <p role="alert" className="mt-1 text-xs text-red-600">{error}</p>}
    {value && <div className="mt-2 flex items-center gap-3 rounded-md bg-slate-50 p-2"><img src={value} alt="Selected image preview" className="size-16 rounded object-cover" /><span className="break-all text-[11px] text-slate-500">Image preview</span></div>}
  </div>;
}
