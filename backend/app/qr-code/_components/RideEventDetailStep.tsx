"use client";
import React, { useState } from "react";
import { steps, StepValue } from "../_lib/config.data";
import type { MediaItem, EventItem } from "../_lib/types";
import Header from "./_shared/Header";
import KioskBookingCallout from "./_shared/KioskBookingCallout";

const tabs = { RIDES: "rides", EVENTS: "events" } as const;
type TabValue = (typeof tabs)[keyof typeof tabs];

interface Props {
  updateStep: (step: StepValue) => void;
  rides: MediaItem[];
  events: EventItem[];
}

const RideEventDetailStep = ({ updateStep, rides, events }: Props) => {
  const [activeTab, setActiveTab] = useState<TabValue>(tabs.RIDES);
  const data: Array<MediaItem | EventItem> = activeTab === tabs.RIDES ? rides : events;

  return (
    <div className="min-h-screen bg-[#f1f5fb]">
      <Header title="Rides & Event Details" onBack={() => updateStep(steps.LANDING)} />

      <div className="mx-4 mt-4 flex w-auto items-stretch rounded-xl border border-[#dbe4f0] bg-white p-1.5 shadow-sm">
        {(["rides", "events"] as const).map((t) => (
          <button key={t} type="button" onClick={() => setActiveTab(t)} aria-pressed={activeTab === t} className={`w-full rounded-lg py-2.5 transition-colors ${activeTab === t ? "bg-[#244bb0] shadow-sm" : "bg-transparent"}`}>
            <span className={`font-anton text-lg uppercase tracking-tight ${activeTab === t ? "text-white" : "text-slate-500"}`}>{t}</span>
          </button>
        ))}
      </div>

      <div className="flex flex-col gap-3 p-4">
        {data.map((item, index) => (
          <article data-scroll-reveal key={`${activeTab}-${item.title}-${index}`} className="rounded-2xl border border-[#dbe4f0] bg-white p-3.5 shadow-sm transition-shadow hover:shadow-md">
            <div className="flex items-start gap-3">
              {item.img ? (
                <img src={item.img} alt={item.title} className="size-[88px] shrink-0 rounded-xl object-cover" />
              ) : (
                <div className="flex size-[88px] shrink-0 items-center justify-center rounded-xl bg-yellow text-3xl">{activeTab === "rides" ? "ðŸŽ¢" : "ðŸŽ‰"}</div>
              )}
              <div className="min-w-0 flex-1">
                {"time" in item && item.time && <span className="inline-block rounded-full bg-blue px-3 py-0.5 font-mulish text-[11px] font-bold text-white">{(item as EventItem).time}</span>}
                <h3 className="mt-1 font-anton text-lg uppercase tracking-tight text-[#0F1C3F]">{item.title}</h3>
                <p className="mt-0.5 font-mulish text-xs text-[#0F1C3F]/75">{item.description}</p>
                {item.tags && item.tags.length > 0 && (
                  <div className="mt-2 flex flex-wrap gap-1.5">
                    {item.tags.map((tag) => <span key={tag} className="rounded-full bg-[#0F1C3F] px-2.5 py-0.5 font-mulish text-[10px] font-bold text-white">{tag}</span>)}
                  </div>
                )}
              </div>
            </div>
            {activeTab === "rides" && item.kioskBookingEnabled && <KioskBookingCallout />}
          </article>
        ))}
        {data.length === 0 && <p className="rounded-2xl bg-white p-5 text-center font-mulish text-sm text-slate-500 shadow-sm">Nothing added yet.</p>}
      </div>
    </div>
  );
};

export default RideEventDetailStep;
