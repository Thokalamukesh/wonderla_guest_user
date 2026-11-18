import React from "react";

const KioskBookingCallout = () => (
  <aside className="mt-3 flex items-start gap-3 rounded-xl border border-[#dbe4f0] bg-[#f4f7fc] p-3" aria-label="Kiosk slot booking information">
    <span className="flex size-9 shrink-0 items-center justify-center rounded-xl bg-yellow text-[#14245D] shadow-sm" aria-hidden="true">
      <svg viewBox="0 0 24 24" fill="none" className="size-5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
        <path d="M4 7.5A2.5 2.5 0 0 0 6.5 10v4A2.5 2.5 0 0 0 4 16.5V19h16v-2.5a2.5 2.5 0 0 1 0-5v-4A2.5 2.5 0 0 1 20 5H4v2.5Z" />
        <path d="M12 8v1m0 3v1m0 3v.01" />
      </svg>
    </span>
    <div className="min-w-0 flex-1">
      <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
        <p className="font-mulish text-[11px] font-extrabold uppercase tracking-[0.09em] text-[#14245D]">Book a Ride Slot</p>
        <span className="rounded-full bg-white px-2 py-0.5 font-mulish text-[9px] font-bold uppercase tracking-wide text-[#4057B2] ring-1 ring-[#DCE4FF]">At park kiosks</span>
      </div>
      <p className="mt-1 font-mulish text-xs leading-relaxed text-[#34415E]">Visit a kiosk in the park to choose your preferred ride time slot.</p>
    </div>
  </aside>
);

export default KioskBookingCallout;
