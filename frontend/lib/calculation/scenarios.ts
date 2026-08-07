export type CalculationScenarioField =
  | "burialDepthM"
  | "supplyPipeDiameterMm"
  | "returnPipeDiameterMm"
  | "supplyWaterTemperatureC"
  | "returnWaterTemperatureC"
  | "soilTemperatureC"
  | "soilTypeId";

export type CalculationScenarioCode =
  | "water-underground-channelless"
  | "unsupported";

export interface CalculationScenario {
  code: CalculationScenarioCode;
  isSupported: boolean;
  visibleFields: ReadonlySet<CalculationScenarioField>;
}

const WATER_NETWORK_NAME = "Водяная тепловая сеть";

const UNDERGROUND_CHANNELLESS_NAME =
  "Подземная бесканальная прокладка";

const waterUndergroundChannellessScenario: CalculationScenario = {
  code: "water-underground-channelless",
  isSupported: true,

  visibleFields: new Set<CalculationScenarioField>([
    "burialDepthM",
    "supplyPipeDiameterMm",
    "returnPipeDiameterMm",

    "supplyWaterTemperatureC",
    "returnWaterTemperatureC",
    "soilTemperatureC",

    "soilTypeId",
  ]),
};

const unsupportedScenario: CalculationScenario = {
  code: "unsupported",
  isSupported: false,
  visibleFields: new Set<CalculationScenarioField>(),
};

export function resolveCalculationScenario(
  networkTypeName: string | null,
  layingMethodName: string | null,
): CalculationScenario {
  const isWaterUndergroundChannelless =
    networkTypeName === WATER_NETWORK_NAME &&
    layingMethodName === UNDERGROUND_CHANNELLESS_NAME;

  if (isWaterUndergroundChannelless) {
    return waterUndergroundChannellessScenario;
  }

  return unsupportedScenario;
}

export function isScenarioFieldVisible(
  scenario: CalculationScenario,
  field: CalculationScenarioField,
): boolean {
  return scenario.visibleFields.has(field);
}