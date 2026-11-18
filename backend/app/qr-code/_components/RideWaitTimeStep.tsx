"use client";
import React from "react";
import { steps, StepValue } from "../_lib/config.data";
import type { WaitTimeItem } from "../_lib/types";
import Header from "./_shared/Header";
import KioskBookingCallout from "./_shared/KioskBookingCallout";

interface Props {
  updateStep: (step: StepValue) => void;
  data: WaitTimeItem[];
  onRefresh?: () => void;
  refreshing?: boolean;
  refreshError?: boolean;
}

const RefreshButton = ({ onRefresh, refreshing }: { onRefresh?: () => void; refreshing?: boolean }) => (
  <button type="button" onClick={onRefresh} disabled={refreshing} className="flex flex-col items-center gap-1 disabled:opacity-60">
    <span className={`flex size-9 items-center justify-center rounded-full bg-yellow text-lg ${refreshing ? "animate-spin" : ""}`}>â†»</span>
    <span className="font-mulish text-[11px] font-bold text-white">{refreshing ? "..." : "Refresh"}</span>
  </button>
);

const RideWaitTimeStep = ({ updateStep, data, onRefresh, refreshing, refreshError }: Props) => (
  <div className="min-h-screen bg-[#f1f5fb]">
    <Header title="Live Ride Wait Time" onBack={() => updateStep(steps.LANDING)} right={<RefreshButton onRefresh={onRefresh} refreshing={refreshing} />} />
    {refreshError && <p role="status" className="mx-4 mt-3 rounded-xl bg-red-50 px-4 py-3 text-center font-mulish text-xs font-semibold text-red-700">Could not refresh. Check your connection and try again.</p>}
    <div className="flex flex-col gap-3 px-4 py-5">
      {(data ?? []).map((item, i) => (
        <article data-scroll-reveal key={`${item.title}-${i}`} className="rounded-2xl border border-[#dbe4f0] bg-white p-3.5 shadow-sm">
          <div className="flex items-start gap-3">
            {item.img ? (
              <img src={item.img} alt={item.title} className="size-[76px] shrink-0 rounded-xl object-cover" />
            ) : (
              <div className="flex size-[76px] shrink-0 items-center justify-center rounded-xl bg-yellow text-3xl">ðŸŽ¢</div>
            )}
            <div className="min-w-0 flex-1">
              <h3 className="font-anton text-lg uppercase tracking-tight text-[#0F1C3F]">{item.title}</h3>
              <p className="font-mulish text-xs text-[#0F1C3F]/70">{item.description}</p>
            </div>
            <span className={`shrink-0 rounded-full px-3 py-1 font-mulish text-xs font-bold text-white ${item.time >= 20 ? "bg-[#E14F1B]" : item.time >= 10 ? "bg-blue" : "bg-[#477fdf]"}`}>
              {item.time} min
            </span>
          </div>
          {item.kioskBookingEnabled && <KioskBookingCallout />}
        </article>
      ))}
      {(!data || data.length === 0) && <p className="rounded-2xl border border-[#dbe4f0] bg-white p-5 text-center font-mulish text-sm text-slate-500 shadow-sm">Wait times are not available yet.</p>}
    </div>
  </div>
);

export default RideWaitTimeStep;
