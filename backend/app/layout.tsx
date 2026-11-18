import type { Metadata } from "next";
import { Mulish, Anton, Oswald } from "next/font/google";
import "./globals.css";

const mulish = Mulish({ subsets: ["latin"], variable: "--font-mulish" });
const anton = Anton({ subsets: ["latin"], weight: "400", variable: "--font-anton" });
const oswald = Oswald({ subsets: ["latin"], variable: "--font-oswald" });

export const metadata: Metadata = {
  title: "Wonderla QR",
  description: "Wonderla in-park QR experience",
};

export const viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  themeColor: "#2A41B1",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={`${mulish.variable} ${anton.variable} ${oswald.variable}`}>
        {children}
      </body>
    </html>
  );
}
