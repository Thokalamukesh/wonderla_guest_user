import React from "react";

/**
 * Logo for the landing header. If `logoUrl` is set (admin → Park details),
 * it renders that image; otherwise it falls back to a styled text wordmark.
 * To bundle a fixed logo instead, drop the file in /public and pass
 * logoUrl="/wonderla-logo.png" from the park config.
 */
const Wordmark = ({ logoUrl }: { logoUrl?: string }) => {
  if (logoUrl) {
    return <img src={logoUrl} alt="Wonderla" className="h-14 w-auto object-contain" />;
  }
  return (
    <div className="flex flex-col items-start leading-none">
      <span className="font-anton text-[30px] uppercase tracking-tight text-blue">
        Wonder<span className="text-yellow [text-shadow:0_1px_0_rgba(0,0,0,0.15)]">la</span>
      </span>
      <span className="mt-0.5 font-mulish text-[9px] font-bold uppercase tracking-[0.3em] text-blue/70">
        Parks and Resorts
      </span>
    </div>
  );
};

export default Wordmark;
