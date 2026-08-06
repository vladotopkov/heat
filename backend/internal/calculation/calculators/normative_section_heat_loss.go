package calculators

import (
	"fmt"

	"lostHeat/internal/calculation/domain"
)

type NormativeSectionHeatLossCalculator struct{}

func NewNormativeSectionHeatLossCalculator() *NormativeSectionHeatLossCalculator {
	return &NormativeSectionHeatLossCalculator{}
}

func (c *NormativeSectionHeatLossCalculator) Calculate(
	input domain.CalculationInput,
) (domain.CalculationResult, error) {
	periodHours, err := input.PeriodHours()
	if err != nil {
		return domain.CalculationResult{},
			fmt.Errorf(
				"calculate period duration: %w",
				err,
			)
	}

	totalResistance :=
		input.InsulationResistanceMKPerW +
			input.SoilResistanceMKPerW

	if totalResistance <= 0 {
		return domain.CalculationResult{},
			fmt.Errorf(
				"total thermal resistance must be greater than zero",
			)
	}

	deltaTemperature :=
		input.WaterTemperatureC -
			input.SoilTemperatureC

	if deltaTemperature <= 0 {
		return domain.CalculationResult{},
			fmt.Errorf(
				"water temperature must be greater than soil temperature",
			)
	}

	// Удельные тепловые потери, Вт/м.
	heatFlowWPerM :=
		deltaTemperature / totalResistance

	// Мощность тепловых потерь всего участка, Вт.
	heatLossPowerW :=
		heatFlowWPerM * input.LengthM

	// Энергия тепловых потерь за период:
	// Вт × ч / 1000 = кВт·ч.
	energyKWh :=
		heatLossPowerW *
			periodHours /
			1000

	return domain.CalculationResult{
		PeriodStart: input.PeriodStart,
		PeriodEnd:   input.PeriodEnd,
		PeriodHours: periodHours,

		InsulationResistanceMKPerW:
			input.InsulationResistanceMKPerW,

		SoilResistanceMKPerW:
			input.SoilResistanceMKPerW,

		TotalResistanceMKPerW:
			totalResistance,

		DeltaTemperatureK:
			deltaTemperature,

		HeatFlowWPerM:
			heatFlowWPerM,

		HeatLossPowerW:
			heatLossPowerW,

		EnergyKWh:
			energyKWh,
	}, nil
}