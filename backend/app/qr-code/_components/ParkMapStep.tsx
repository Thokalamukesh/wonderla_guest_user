import React from "react";
import dynamic from "next/dynamic";
import { steps, StepValue } from "../_lib/config.data";
import type { ParkMapPlace } from "../_lib/types";
import Header from "./_shared/Header";

const InteractiveParkMap = dynamic(() => import("./InteractiveParkMap"), { ssr: false, loading: () => <div className="flex h-full min-h-0 w-full items-center justify-center rounded-2xl bg-white text-sm text-slate-500">Loading park map…</div> });

interface Props {
  updateStep: (step: StepValue) => void;
  parkName: string;
  places?: ParkMapPlace[];
}

const ParkMapStep = ({ updateStep, parkName, places }: Props) => (
  <div className="flex h-[100dvh] min-h-0 flex-col overflow-hidden bg-[#f1f5fb]">
    <Header title="Park Map" onBack={() => updateStep(steps.LANDING)} />
    <div className="flex min-h-0 flex-1 px-0 pb-0 pt-0">
      <InteractiveParkMap parkName={parkName} places={places} />
    </div>
  </div>
);

export default ParkMapStep;
