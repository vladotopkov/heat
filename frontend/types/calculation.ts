export interface CalculationRequest {
  name: string;
  calculationOperationId: string;

  boilerHouseId: string;
  section: string;

  periodStart: string;
  periodEnd: string;

  commissioningYear: number;

  networkTypeId: string;
  layingMethodId: string;

  lengthM: number;
  burialDepthM: number | null;

  supplyPipeDiameterMm: number;
  returnPipeDiameterMm: number;

  waterTemperatureC: number;

  insulationMaterialId: string;
  soilTypeId: string | null;
  soilTemperatureC: number;
}

export interface CalculationResponse {
  operationCode: string;

  periodStart: string;
  periodEnd: string;
  periodHours: number;

  insulationResistanceMKPerW: number;
  soilResistanceMKPerW: number;
  totalResistanceMKPerW: number;

  deltaTemperatureK: number;
  heatFlowWPerM: number;
  heatLossPowerW: number;

  energyKWh: number;
}

export interface APIErrorResponse {
  error?: {
    code?: string;
    message?: string;
  };
}
