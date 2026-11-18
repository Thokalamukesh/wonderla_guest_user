import React from "react";
import { LeftArrow } from "@/assets/svgs/Icons";

interface Props {
  title: string;
  onBack: () => void;
  right?: React.ReactNode;
}

/** Shared branded header for each guest section. */
const Header = ({ title, onBack, right }: Props) => (
  <section className="sticky top-0 z-20 flex items-center justify-between gap-3 rounded-b-2xl bg-[#244bb0] px-4 py-4 shadow-[0_6px_18px_rgba(24,61,154,0.16)] sm:px-5">
    <div className="flex min-w-0 items-center gap-3">
      <button
        type="button"
        onClick={onBack}
        aria-label="Back"
        className="flex size-10 shrink-0 items-center justify-center rounded-full border border-white bg-white text-[#244b9c] shadow-sm transition hover:bg-[#eaf1ff] active:scale-95"
      >
        <LeftArrow />
      </button>
      <h2 className="truncate font-anton text-[clamp(20px,5vw,26px)] uppercase leading-none tracking-tight text-white">
        {title}
      </h2>
    </div>
    {right}
  </section>
);

export default Header;
