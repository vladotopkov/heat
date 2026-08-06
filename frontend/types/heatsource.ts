export interface BoilerHouse {
  id: string;
  code: string;
  name: string;
  city: string;
  address: string;
}

export interface NetworkType {
  id: string;
  code: string;
  name: string;
  description: string;
}

export interface LayingMethod {
  id: string;
  code: string;
  name: string;
  description: string;
}

export interface InsulationMaterial {
  id: string;
  code: string;
  name: string;
  description: string;
}

export interface SoilType {
  id: string;
  code: string;
  name: string;
  description: string;
}

export interface CalculationOperation {
  id: string;
  code: string;
  name: string;
}

export interface CalculationFormOptions {
  boilerHouses: BoilerHouse[];
  networkTypes: NetworkType[];
  layingMethods: LayingMethod[];
  insulationMaterials: InsulationMaterial[];
  soilTypes: SoilType[];
  calculationOperations: CalculationOperation[];
}