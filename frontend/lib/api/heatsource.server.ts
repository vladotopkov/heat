import type {
  BoilerHouse,
  CalculationFormOptions,
  CalculationOperation,
  InsulationMaterial,
  LayingMethod,
  NetworkType,
  SoilType,
} from "@/types/heatsource";

import { getList } from "./client.server";

export async function getBoilerHouses(): Promise<BoilerHouse[]> {
  return getList<BoilerHouse>("/api/v1/boiler-houses");
}

export async function getNetworkTypes(): Promise<NetworkType[]> {
  return getList<NetworkType>("/api/v1/network-types");
}

export async function getLayingMethods(): Promise<LayingMethod[]> {
  return getList<LayingMethod>("/api/v1/laying-methods");
}

export async function getInsulationMaterials(): Promise<
  InsulationMaterial[]
> {
  return getList<InsulationMaterial>(
    "/api/v1/insulation-materials",
  );
}

export async function getSoilTypes(): Promise<SoilType[]> {
  return getList<SoilType>("/api/v1/soil-types");
}

export async function getCalculationOperations(): Promise<
  CalculationOperation[]
> {
  return getList<CalculationOperation>(
    "/api/v1/calculation-operations",
  );
}

export async function getCalculationFormOptions(): Promise<
  CalculationFormOptions
> {
  const [
    boilerHouses,
    networkTypes,
    layingMethods,
    insulationMaterials,
    soilTypes,
    calculationOperations,
  ] = await Promise.all([
    getBoilerHouses(),
    getNetworkTypes(),
    getLayingMethods(),
    getInsulationMaterials(),
    getSoilTypes(),
    getCalculationOperations(),
  ]);

  return {
    boilerHouses,
    networkTypes,
    layingMethods,
    insulationMaterials,
    soilTypes,
    calculationOperations,
  };
}