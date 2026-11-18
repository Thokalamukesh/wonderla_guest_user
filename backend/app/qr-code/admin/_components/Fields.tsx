"use client";
import React from "react";

export const Text = ({
  label,
  value,
  onChange,
  placeholder,
}: {
  label?: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}) => (
  <label className="block">
    {label && <span className="mb-1 block text-xs font-semibold text-slate-600">{label}</span>}
    <input
      className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
      value={value}
      placeholder={placeholder}
      onChange={(e) => onChange(e.target.value)}
    />
  </label>
);

export const Num = ({
  label,
  value,
  onChange,
}: {
  label?: string;
  value: number;
  onChange: (v: number) => void;
}) => (
  <label className="block">
    {label && <span className="mb-1 block text-xs font-semibold text-slate-600">{label}</span>}
    <input
      type="number"
      className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
      value={Number.isFinite(value) ? value : 0}
      onChange={(e) => onChange(Number(e.target.value))}
    />
  </label>
);

export const Area = ({
  label,
  value,
  onChange,
}: {
  label?: string;
  value: string;
  onChange: (v: string) => void;
}) => (
  <label className="block">
    {label && <span className="mb-1 block text-xs font-semibold text-slate-600">{label}</span>}
    <textarea
      rows={2}
      className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
      value={value}
      onChange={(e) => onChange(e.target.value)}
    />
  </label>
);

export const Toggle = ({
  label,
  value,
  onChange,
}: {
  label: string;
  value: boolean;
  onChange: (v: boolean) => void;
}) => (
  <label className="flex items-center gap-2">
    <input type="checkbox" checked={value} onChange={(e) => onChange(e.target.checked)} />
    <span className="text-xs font-semibold text-slate-600">{label}</span>
  </label>
);

export const Section = ({
  title,
  visible = true,
  onAdd,
  addLabel = "+ Add",
  children,
}: {
  title: string;
  visible?: boolean;
  onAdd?: () => void;
  addLabel?: string;
  children: React.ReactNode;
}) => (
  <section id={`editor-${title.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`} hidden={!visible} className="mb-6 scroll-mt-24 rounded-lg border border-slate-200 bg-white p-4">
    <div className="mb-3 flex items-center justify-between">
      <h3 className="flex items-center gap-2 text-sm font-bold uppercase tracking-wide text-slate-700"><span aria-hidden="true">{({"Park details":"🏞️","Landing Tile Icons":"✨","Park Map":"🧭",Rides:"🎢",Events:"🎭","Live Ride Wait Times":"⏱️","Wave Pool & Rain Dance":"🌊","Safety & Hygiene":"🛟","Maintenance Log":"🔧","Ride Guidelines":"📏","Dining & Menu":"🍽️"} as Record<string,string>)[title] || "📝"}</span>{title}</h3>
      {onAdd && (
        <button
          type="button"
          onClick={onAdd}
          className="rounded-md bg-indigo-50 px-3 py-1 text-xs font-semibold text-indigo-700 hover:bg-indigo-100"
        >
          {addLabel}
        </button>
      )}
    </div>
    {children}
  </section>
);

export const Row = ({
  children,
  onRemove,
}: {
  children: React.ReactNode;
  onRemove?: () => void;
}) => (
  <div className="mb-3 rounded-md border border-slate-200 bg-slate-50 p-3">
    <div className="grid gap-2">{children}</div>
    {onRemove && (
      <button
        type="button"
        onClick={onRemove}
        className="mt-2 text-xs font-semibold text-red-600 hover:underline"
      >
        Remove
      </button>
    )}
  </div>
);
