import React from "react";

/** Green square/dot (veg) or red square/triangle (non-veg), FSSAI-style. */
export const VegMark = ({ veg, withLabel = false }: { veg: boolean; withLabel?: boolean }) => (
  <span className="inline-flex items-center gap-1">
    <span
      className={`inline-flex size-4 items-center justify-center rounded-[3px] border-2 ${
        veg ? "border-[#0B8043]" : "border-[#E14F1B]"
      }`}
    >
      {veg ? (
        <span className="size-2 rounded-full bg-[#0B8043]" />
      ) : (
        <span className="size-0 border-x-[5px] border-b-[8px] border-x-transparent border-b-[#E14F1B]" />
      )}
    </span>
    {withLabel && (
      <span className={`font-mulish text-xs font-bold ${veg ? "text-[#0B8043]" : "text-[#E14F1B]"}`}>
        {veg ? "Veg" : "Non-Veg"}
      </span>
    )}
  </span>
);

export default VegMark;
