import React from "react";
import { notFound } from "next/navigation";
import { getPark } from "../_lib/store";
import QrCodeMain from "./main";

export const dynamic = "force-dynamic";

type Props = { params: Promise<{ park: string }> };

/** Server component: loads the park's config, hands it to the client UI. */
const ParkPage = async ({ params }: Props) => {
  const { park } = await params;
  const config = await getPark(park);
  if (!config || !config.active) notFound();
  // Reset guest navigation when changing parks so each park URL opens at its first screen.
  return <QrCodeMain key={config.slug} initialConfig={config} />;
};

export default ParkPage;
