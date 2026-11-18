import React from "react";
import Link from "next/link";
import { Oswald } from "next/font/google";
import { listParks } from "./_lib/store";

const oswald = Oswald({ subsets: ["latin"] });

export const dynamic = "force-dynamic";

/**
 * Park index. Each park's QR code points directly to /qr-code/<slug>,
 * so this page is mainly a human-friendly directory + link to admin.
 */
const QrCodeIndex = async () => {
  const parks = (await listParks()).filter((p) => p.active);

  return (
    <main className="relative mx-auto min-h-screen max-w-[520px] overflow-hidden bg-[#f1f5fb] px-5 pb-10 pt-6 sm:px-8">
      <div aria-hidden="true" className="absolute inset-x-0 top-0 h-[310px] rounded-b-[32px] bg-[#244bb0] shadow-[0_8px_24px_rgba(16,43,120,0.16)]" />
      <div className="relative">
        <div className="mb-7 flex items-center justify-between">
          <img src="/wonderla/logo.png" alt="Wonderla" className="h-12 w-auto object-contain" />
          <span className="rounded-full border border-white/25 bg-white/10 px-3 py-1.5 font-mulish text-[10px] font-extrabold uppercase tracking-[0.18em] text-white">Park guide</span>
        </div>
        <p className={`text-center text-xs font-bold uppercase tracking-[0.28em] text-white/75 ${oswald.className}`}>Your day starts here</p>
        <h1 className={`mb-3 mt-2 text-center text-[clamp(38px,12vw,56px)] font-bold uppercase leading-none text-white ${oswald.className}`}>
          Wonderla
        </h1>
        <p className="mx-auto mb-8 max-w-xs text-center font-mulish text-sm leading-relaxed text-white/80">Find your park and get ready for a day full of fun.</p>

      <section aria-label="Choose a park" className="flex flex-col gap-3">
        {parks.map((park) => (
          <Link
            key={park.slug}
            href={`/qr-code/${park.slug}`}
            className="group flex w-full items-center gap-4 rounded-2xl border border-[#dbe4f0] bg-white p-4 shadow-sm transition hover:border-[#b7c9e8] hover:shadow-md active:scale-[0.99]"
          >
            <span className="flex size-12 shrink-0 items-center justify-center rounded-xl bg-[#edf0ff] text-xl" aria-hidden="true">📍</span>
            <span className="min-w-0 flex-1">
              <span className="block font-mulish text-[15px] font-extrabold text-[#17234a]">{park.name}</span>
              {park.location && <span className="mt-0.5 block font-mulish text-xs text-slate-500">{park.location}</span>}
            </span>
            <span className="flex size-9 items-center justify-center rounded-full bg-[#f4f5fb] text-lg text-[#3048ba] transition group-hover:bg-[#3048ba] group-hover:text-white" aria-hidden="true">›</span>
          </Link>
        ))}
        {parks.length === 0 && (
          <p className="rounded-2xl border border-[#dbe4f0] bg-white p-5 text-center font-mulish text-sm leading-relaxed text-slate-600 shadow-sm">
            No parks configured yet. Add one from the admin panel.
          </p>
        )}
      </section>

      <div className="mt-8 flex items-center justify-between border-t border-slate-200 px-1 pt-5">
        <span className="font-mulish text-[11px] font-semibold text-slate-400">Have a Wonder-ful day!</span>
        <Link href="/qr-code/admin" className="font-mulish text-xs font-bold text-[#3048ba] underline decoration-[#3048ba]/30 underline-offset-4">
          Admin login
        </Link>
      </div>
      </div>
    </main>
  );
};

export default QrCodeIndex;
