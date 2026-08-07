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

	supplyDeltaTemperature :=
		input.SupplyWaterTemperatureC -
			input.SoilTemperatureC

	if supplyDeltaTemperature <= 0 {
		return domain.CalculationResult{},
			fmt.Errorf(
				"supply water temperature must be greater than soil temperature",
			)
	}

	returnDeltaTemperature :=
		input.ReturnWaterTemperatureC -
			input.SoilTemperatureC

	if returnDeltaTemperature <= 0 {
		return domain.CalculationResult{},
			fmt.Errorf(
				"return water temperature must be greater than soil temperature",
			)
	}

	// Удельные тепловые потери подающего трубопровода, Вт/м.
	supplyHeatFlowWPerM :=
		supplyDeltaTemperature /
			totalResistance

	// Удельные тепловые потери обратного трубопровода, Вт/м.
	returnHeatFlowWPerM :=
		returnDeltaTemperature /
			totalResistance

	// Общие удельные потери двух труб, Вт/м.
	heatFlowWPerM :=
		supplyHeatFlowWPerM +
			returnHeatFlowWPerM

	// Общая мощность тепловых потерь участка, Вт.
	heatLossPowerW :=
		heatFlowWPerM *
			input.LengthM

	// Потери тепловой энергии за период:
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

		HeatFlowWPerM:
			heatFlowWPerM,

		HeatLossPowerW:
			heatLossPowerW,

		EnergyKWh:
			energyKWh,
	}, nil
}