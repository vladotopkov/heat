
import { CalculationForm } from "@/components/calculation-form/calculation-form";
import { getCalculationFormOptions } from "@/lib/api/heatsource.server";

export const dynamic = "force-dynamic";

export default async function NewCalculationPage() {
  const options = await getCalculationFormOptions();

  return <CalculationForm options={options} />;
}