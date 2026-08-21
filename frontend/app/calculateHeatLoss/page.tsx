import type { Metadata } from "next";

import { HeatLossQuestionnaire } from "./heat-loss-questionnaire";

export const metadata: Metadata = {
  title: "Расчёт тепловых потерь",
  description: "Опросник для расчёта тепловых потерь тепловой сети",
};

export default function CalculateHeatLossPage() {
  return <HeatLossQuestionnaire />;
}
