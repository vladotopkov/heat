import type { Metadata } from "next";

import { HeatLossQuestionnaire } from "./heat-loss-questionnaire";

export const metadata: Metadata = {
  title: "Расчёт удельных тепловых потерь qh",
  description:
    "Опросник для подбора нормативной таблицы и расчёта удельных тепловых потерь тепловой сети",
};

export default function CalculateHeatLossPage() {
  return <HeatLossQuestionnaire />;
}
