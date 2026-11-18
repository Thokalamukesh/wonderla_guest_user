import React from "react";
import { steps, StepValue } from "../_lib/config.data";
import type { SafetyItem } from "../_lib/types";
import Header from "./_shared/Header";

interface Props {
  updateStep: (step: StepValue) => void;
  data: SafetyItem[];
}

const SafetyHygieneStep = ({ updateStep, data }: Props) => (
  <div className="min-h-screen bg-[#f1f5fb]">
    <Header title="Safety & Hygiene" onBack={() => updateStep(steps.LANDING)} />
    <div className="flex flex-col gap-3 px-4 py-5">
      {(data ?? []).map((item, i) => (
        <div data-scroll-reveal key={`${item.title}-${i}`} className="flex gap-3 rounded-2xl border border-[#dbe4f0] bg-white p-3.5 shadow-sm">
          {item.img ? (
            <img src={item.img} alt={item.title} className="size-[90px] shrink-0 rounded-xl object-cover" />
          ) : (
            <div className="flex size-[90px] shrink-0 items-center justify-center rounded-xl bg-yellow text-4xl">🛡️</div>
          )}
          <div className="min-w-0">
            <h3 className="font-anton text-lg uppercase tracking-tight text-[#0F1C3F]">{item.title}</h3>
            <p className="mt-1 font-mulish text-xs text-[#0F1C3F]/75">{item.description}</p>
          </div>
        </div>
      ))}
      {(!data || data.length === 0) && <p className="rounded-2xl border border-[#dbe4f0] bg-white p-5 text-center font-mulish text-sm text-slate-500 shadow-sm">Safety information will be available here soon.</p>}
    </div>
  </div>
);

export default SafetyHygieneStep;
