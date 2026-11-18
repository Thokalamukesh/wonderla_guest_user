/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Keep `next dev` output separate from `next build`; sharing `.next` can
  // leave stale server chunks behind when switching between the two modes.
  distDir: process.env.NODE_ENV === "development" ? ".next-dev" : ".next",
};
module.exports = nextConfig;
