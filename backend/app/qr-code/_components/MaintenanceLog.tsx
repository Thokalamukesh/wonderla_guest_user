"use client";
import React from "react";
import { steps, StepValue } from "../_lib/config.data";
import type { MaintenanceItem } from "../_lib/types";
import Header from "./_shared/Header";

interface Props {
  updateStep: (step: StepValue) => void;
  data: MaintenanceItem[];
  onRefresh?: () => void;
  refreshing?: boolean;
  refreshError?: boolean;
}

const RefreshButton = ({ onRefresh, refreshing }: { onRefresh?: () => void; refreshing?: boolean }) => (
  <button type="button" onClick={onRefresh} disabled={refreshing} className="flex flex-col items-center gap-1 disabled:opacity-60">
    <span className={`flex size-9 items-center justify-center rounded-full bg-yellow text-lg ${refreshing ? "animate-spin" : ""}`}>↻</span>
    <span className="font-mulish text-[11px] font-bold text-white">{refreshing ? "..." : "Refresh"}</span>
  </button>
);

const MaintenanceLog = ({ updateStep, data, onRefresh, refreshing, refreshError }: Props) => (
  <div className="min-h-screen bg-[#f1f5fb]">
    <Header
      title="Maintenance Log"
      onBack={() => updateStep(steps.LANDING)}
      right={<RefreshButton onRefresh={onRefresh} refreshing={refreshing} />}
    />
    {refreshError && <p role="status" className="mx-4 mt-3 rounded-xl bg-red-50 px-4 py-3 text-center font-mulish text-xs font-semibold text-red-700">Could not refresh. Check your connection and try again.</p>}
    <div className="px-4 py-6">
      <div className="flex gap-2 rounded-t-2xl bg-[#244bb0] px-5 py-4">
        <div className="w-5/12"><p className="font-mulish text-xs font-bold text-white">Ride</p></div>
        <div className="w-4/12"><p className="font-mulish text-xs font-bold text-white">Last Service</p></div>
        <div className="w-3/12"><p className="text-center font-mulish text-xs font-bold text-white">Checks</p></div>
      </div>
      <div className="overflow-hidden rounded-b-2xl border border-slate-200 bg-white shadow-[0_8px_24px_rgba(20,36,90,0.08)]">
        {(data ?? []).map((item, i) => (
          <div data-scroll-reveal key={`${item.ride}-${i}`} className="flex gap-2 border-b border-[#e1e9f7] px-5 py-4 last:border-none even:bg-[#f1f5ff]">
            <div className="w-5/12"><p className="font-mulish text-xs font-bold text-slate-800">{item.ride}</p></div>
            <div className="w-4/12"><p className="font-mulish text-xs text-slate-600">{item.lastService}</p></div>
            <div className="w-3/12"><p className="text-center font-mulish text-xs text-slate-600">{item.checks}</p></div>
          </div>
        ))}
        {(!data || data.length === 0) && <p className="bg-white px-4 py-6 text-center font-mulish text-sm text-slate-500">No maintenance records are available yet.</p>}
      </div>
    </div>
  </div>
);

export default MaintenanceLog;
