import React from "react";
import { DEFAULT_LANDING_ICONS, steps, StepValue } from "../_lib/config.data";
import type { LandingIcons } from "../_lib/types";
import Wordmark from "./_shared/Wordmark";

interface Props {
  updateStep: (step: StepValue) => void;
  parkName?: string;
  logoUrl?: string;
  icons?: LandingIcons;
  heroImage?: string;
}

interface Tile { icon: keyof LandingIcons; label: string; subtitle: string; step: StepValue; color: string; tint: string; }

const LandingStep = ({ updateStep, parkName, logoUrl, heroImage, icons }: Props) => {
  const logo = logoUrl || "/wonderla/logo.png";
  const tileIcons = { ...DEFAULT_LANDING_ICONS, ...(icons || {}) };

  const tiles: Tile[] = [
    { icon: "parkMap", label: "Park Map", subtitle: "Find rides & facilities", step: steps.PARK_MAP, color: "#244bb0", tint: "#e4edff" },
    { icon: "ridesEvents", label: "Rides & Events", subtitle: "Explore rides and shows", step: steps.RIDE_EVENT_DETAILS, color: "#315ec0", tint: "#e7efff" },
    { icon: "dining", label: "Dining & Menu", subtitle: "Food, menus & prices", step: steps.DINING_MENU, color: "#426fd0", tint: "#eaf1ff" },
    { icon: "waitTimes", label: "Live Wait Times", subtitle: "Current ride queues", step: steps.LIVE_RIDE_WAIT_TIME, color: "#183d9a", tint: "#e2ebff" },
    { icon: "guidelines", label: "Ride Guidelines", subtitle: "Height limits & rules", step: steps.RIDE_GUIDELINES, color: "#355cb8", tint: "#e8eeff" },
    { icon: "wavePool", label: "Wave Pool & Rain Dance", subtitle: "Sessions & timings", step: steps.WAVE_POOL_RAIN_DANCE, color: "#3270bb", tint: "#e4f2ff" },
    { icon: "safety", label: "Safety & Hygiene", subtitle: "Guest safety information", step: steps.SAFETY_AND_HYGIENE_INFO, color: "#315ec0", tint: "#e7efff" },
    { icon: "maintenance", label: "Maintenance Log", subtitle: "Ride service records", step: steps.MAINTENANCE_LOG, color: "#405986", tint: "#eaf0fa" },
  ];

  return (
    <div className="min-h-screen bg-[#f1f5fb]">
      {/* Logo bar */}
      <header className="flex justify-center border-b border-[#e1e8f2] bg-white px-4 py-2.5">
        <Wordmark logoUrl={logo} />
      </header>

      <div className="mx-auto max-w-[560px] px-4 pb-8 pt-4 sm:px-5 sm:pt-5">
        {/* Hero banner — single focal image, clean */}
        <div className="relative aspect-[16/9] w-full min-h-[190px] max-h-[275px] overflow-hidden rounded-[24px] border border-[#d4deed] bg-[#183d9a] shadow-[0_10px_24px_rgba(15,31,100,0.16)]">
          {heroImage ? (
            <img src={heroImage} alt="" className="absolute inset-0 h-full w-full object-cover" />
          ) : (
            <div className="absolute inset-0 bg-[#244bb0]" />
          )}
          <div className="absolute inset-0 bg-black/35" />
          <div aria-hidden="true" className="absolute -right-12 -top-14 size-56 rounded-full border-[28px] border-white/10 sm:size-64" />
          <div aria-hidden="true" className="absolute right-10 top-12 size-20 rounded-full border border-white/20 sm:right-14 sm:top-16 sm:size-24" />
          <div className="absolute inset-x-0 bottom-0 p-5 sm:p-7">
            <span className="inline-flex items-center rounded-full border border-white/30 bg-white/10 px-3 py-1 font-mulish text-[10px] font-extrabold uppercase tracking-[0.18em] text-white">
              The fun starts here
            </span>
            <h1 className="mt-3 font-anton text-[clamp(38px,10vw,52px)] uppercase leading-[0.9] tracking-tight text-white [text-shadow:0_2px_10px_rgba(0,0,0,0.25)]">
              Welcome to<br />Wonderla
            </h1>
            {parkName && <p className="mt-1 font-mulish text-sm font-bold text-yellow">📍 {parkName}</p>}
          </div>
        </div>

        <div className="mb-3 mt-7 sm:mt-8">
          <h2 className="font-anton text-2xl uppercase tracking-tight text-[#142653]">Explore the Park</h2>
          <p className="mt-1 font-mulish text-sm text-[#63718c]">Choose what you want to discover.</p>
        </div>

        {/* Clean card grid */}
        <div className="grid grid-cols-2 gap-3 sm:gap-3.5">
          {tiles.map((t) => (
            <button
              key={t.label}
              type="button"
              aria-label={`${t.label}: ${t.subtitle}`}
              onClick={() => updateStep(t.step)}
              data-scroll-reveal
              className="group flex min-h-[104px] items-start gap-2.5 rounded-2xl border border-[#d6e0ef] border-l-[3px] border-l-[#315ec0] bg-white p-3 text-left shadow-[0_4px_12px_rgba(28,54,103,0.06)] transition hover:-translate-y-0.5 hover:border-[#b7c9e8] hover:shadow-[0_9px_18px_rgba(28,54,103,0.12)] active:scale-[0.98] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#8bb6ff] sm:min-h-[112px] sm:gap-3 sm:p-3.5"
            >
              <span
                className="flex size-10 shrink-0 items-center justify-center rounded-xl text-[22px] transition-transform group-hover:scale-105 sm:size-11"
                style={{ backgroundColor: t.tint, color: t.color }}
              >
                <span aria-hidden="true" className="leading-none">{tileIcons[t.icon]}</span>
              </span>
              <span className="min-w-0 flex-1 pt-0.5">
                <span className="block font-anton text-[13px] uppercase leading-tight tracking-tight text-[#0F1C3F] sm:text-[15px]">
                  {t.label}
                </span>
                <span className="mt-1 block font-mulish text-[12px] leading-snug text-[#0F1C3F]/75 sm:text-[12px]">
                  {t.subtitle}
                </span>
              </span>
              <span aria-hidden="true" className="mt-2 text-lg font-semibold text-[#7d91b6] transition-transform group-hover:translate-x-0.5 group-hover:text-[#244bb0]">›</span>
            </button>
          ))}
        </div>

        <p className="mt-8 text-center font-mulish text-[11px] font-semibold uppercase tracking-[0.25em] text-[#7d8eae]">
          Have a Wonder-ful day!
        </p>
      </div>
    </div>
  );
};

export default LandingStep;
