import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./assets/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Wonderla brand tokens used by the QR module.
        // Adjust these to the exact brand hex when you have them.
        blue: "#2A41B1",
        yellow: "#FFD400",
      },
      fontFamily: {
        mulish: ["var(--font-mulish)", "sans-serif"],
        anton: ["var(--font-anton)", "sans-serif"],
        oswald: ["var(--font-oswald)", "sans-serif"],
      },
    },
  },
  plugins: [],
};
export default config;
