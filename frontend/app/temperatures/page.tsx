import type { Metadata } from "next";

import { TemperaturesWorkspace } from "./temperatures-workspace";

export const metadata: Metadata = {
  title: "Температуры за месяц",
  description: "Месячные температуры тепловых сетей",
};

export const dynamic = "force-dynamic";

export default function TemperaturesPage() {
  return <TemperaturesWorkspace initialMonth={currentMonthInMinsk()} />;
}

function currentMonthInMinsk() {
  const parts = new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "2-digit",
    timeZone: "Europe/Minsk",
  }).formatToParts(new Date());
  const year = parts.find((part) => part.type === "year")?.value;
  const month = parts.find((part) => part.type === "month")?.value;

  if (!year || !month) {
    return new Date().toISOString().slice(0, 7);
  }

  return `${year}-${month}`;
}
