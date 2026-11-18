"use client";
import React, { useCallback, useEffect, useState } from "react";
import LandingStep from "../_components/LandingStep";
import ParkMapStep from "../_components/ParkMapStep";
import { PARK_LANDING_HERO, steps, StepValue } from "../_lib/config.data";
import type { ParkConfig } from "../_lib/types";
import RideEventDetailStep from "../_components/RideEventDetailStep";
import DiningMenuStep from "../_components/DiningMenuStep";
import RideWaitTimeStep from "../_components/RideWaitTimeStep";
import MaintenanceLog from "../_components/MaintenanceLog";
import RideGuidlinesStep from "../_components/RideGuidlinesStep";
import SafetyHygieneStep from "../_components/SafetyHygieneStep";
import WavePoolStep from "../_components/WavePoolStep";
import ScrollRevealEffects from "../_components/ScrollRevealEffects";

interface Props {
  initialConfig: ParkConfig;
}

const QrCodeMain = ({ initialConfig }: Props) => {
  const [step, setStep] = useState<StepValue>(steps.LANDING);
  const [config, setConfig] = useState<ParkConfig>(initialConfig);
  const [refreshing, setRefreshing] = useState(false);
  const [refreshError, setRefreshError] = useState(false);

  const updateStep = (next: StepValue) => {
    if (next === step) return;

    // Keep the in-app sections in browser history so browser and phone back
    // controls work the same way as the visible page back button.
    if (next === steps.LANDING) {
      if (window.history.state?.wonderlaStep) {
        window.history.back();
      } else {
        setStep(next);
      }
      return;
    }

    window.history.pushState({ wonderlaStep: next }, "", window.location.href);
    setStep(next);
  };

  useEffect(() => {
    const handlePopState = (event: PopStateEvent) => {
      const previousStep = event.state?.wonderlaStep as StepValue | undefined;
      setStep(previousStep || steps.LANDING);
    };

    window.addEventListener("popstate", handlePopState);
    return () => window.removeEventListener("popstate", handlePopState);
  }, []);

  // Re-fetch the latest config for this park (powers the "Refresh"
  // buttons on Live Wait Times & Maintenance Log — truly live now).
  const refresh = useCallback(async () => {
    try {
      setRefreshing(true);
      setRefreshError(false);
      const res = await fetch(`/qr-code/api/parks/${config.slug}?_=${Date.now()}`, { cache: "no-store" });
      const json = await res.json();
      if (!res.ok || !json?.ok || !json.config) throw new Error("Refresh failed");
      setConfig(json.config);
    } catch {
      setRefreshError(true);
    } finally {
      setRefreshing(false);
    }
  }, [config.slug]);

  // When a guest returns to an already-open QR page, re-check saved park data.
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    const refreshWhenVisible = () => {
      if (document.visibilityState !== "visible") return;
      clearTimeout(timer);
      timer = setTimeout(() => { void refresh(); }, 180);
    };
    window.addEventListener("focus", refreshWhenVisible);
    document.addEventListener("visibilitychange", refreshWhenVisible);
    return () => {
      clearTimeout(timer);
      window.removeEventListener("focus", refreshWhenVisible);
      document.removeEventListener("visibilitychange", refreshWhenVisible);
    };
  }, [refresh]);

  const renderSteps = () => {
    switch (step) {
      case steps.LANDING:
        return (
          <LandingStep
            updateStep={updateStep}
            parkName={config.name}
            logoUrl={config.logoUrl}
            icons={config.landingIcons}
            heroImage={config.heroImageUrl || PARK_LANDING_HERO[config.slug] || config.parkMap?.img}
          />
        );
      case steps.PARK_MAP:
        return (
          <ParkMapStep
            updateStep={updateStep}
            parkName={config.name}
            places={config.parkMap.places?.map((place) => ({
              ...place,
              avatarImage: config.rides.find((ride) => ride.title.toLowerCase() === place.name.toLowerCase())?.img
                || config.dining.find((outlet) => outlet.name.toLowerCase() === place.name.toLowerCase())?.img
                || config.waveRainDance.find((event) => event.title.toLowerCase() === place.name.toLowerCase())?.img
                || undefined,
            }))}
          />
        );
      case steps.RIDE_EVENT_DETAILS:
        return (
          <RideEventDetailStep
            updateStep={updateStep}
            rides={config.rides}
            events={config.events}
          />
        );
      case steps.DINING_MENU:
        return <DiningMenuStep updateStep={updateStep} data={config.dining} />;
      case steps.LIVE_RIDE_WAIT_TIME:
        return (
          <RideWaitTimeStep
            updateStep={updateStep}
            data={config.liveWaitTimes}
            onRefresh={refresh}
            refreshing={refreshing}
            refreshError={refreshError}
          />
        );
      case steps.MAINTENANCE_LOG:
        return (
          <MaintenanceLog
            updateStep={updateStep}
            data={config.maintenanceLog}
            onRefresh={refresh}
            refreshing={refreshing}
            refreshError={refreshError}
          />
        );
      case steps.RIDE_GUIDELINES:
        return <RideGuidlinesStep updateStep={updateStep} data={config.rideGuidelines} />;
      case steps.SAFETY_AND_HYGIENE_INFO:
        return <SafetyHygieneStep updateStep={updateStep} data={config.safetyHygiene} />;
      case steps.WAVE_POOL_RAIN_DANCE:
        return <WavePoolStep updateStep={updateStep} data={config.waveRainDance} />;
      default:
        return null;
    }
  };

  return (
    <div className="flex min-h-screen justify-center bg-[#e7edf7] sm:px-4 sm:py-5">
      <main data-guest-experience className="w-full max-w-[480px] overflow-x-clip bg-[#f4f7fc] shadow-[0_10px_36px_rgba(20,54,130,0.12)] sm:rounded-[24px]">
        <ScrollRevealEffects />
        {renderSteps()}
      </main>
    </div>
  );
};

export default QrCodeMain;
