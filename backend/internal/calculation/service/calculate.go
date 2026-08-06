package service

import (
	"context"
	"fmt"

	"lostHeat/internal/calculation/domain"
)

func (s *Service) Calculate(
	ctx context.Context,
	requestData CalculationRequestData,
) (domain.CalculationResult, error) {
	if err := validateCalculationRequestData(
		requestData,
	); err != nil {
		return domain.CalculationResult{}, err
	}

	references, err := s.repository.LoadReferences(
		ctx,
		domain.CalculationReferenceIDs{
			OperationID: requestData.CalculationOperationID,

			BoilerHouseID: requestData.BoilerHouseID,

			NetworkTypeID: requestData.NetworkTypeID,

			LayingMethodID: requestData.LayingMethodID,

			InsulationMaterialID: requestData.InsulationMaterialID,

			SoilTypeID: requestData.SoilTypeID,
		},
	)
	if err != nil {
		return domain.CalculationResult{},
			fmt.Errorf(
				"%w: %v",
				ErrNotFound,
				err,
			)
	}

	if requestData.SoilTypeID != nil &&
		references.SoilResistanceMKPerW == nil {
		return domain.CalculationResult{},
			fmt.Errorf(
				"%w: soil type",
				ErrNotFound,
			)
	}

	isAboveGround :=
		references.LayingMethodCode ==
			"above_ground"

	if !isAboveGround &&
		requestData.SoilTypeID == nil {
		return domain.CalculationResult{},
			fmt.Errorf(
				"%w: soil type is required for underground laying",
				ErrInvalidInput,
			)
	}

	if !isAboveGround &&
		requestData.BurialDepthM == nil {
		return domain.CalculationResult{},
			fmt.Errorf(
				"%w: burial depth is required for underground laying",
				ErrInvalidInput,
			)
	}

	soilResistance := 0.0

	if references.SoilResistanceMKPerW != nil {
		soilResistance =
			*references.SoilResistanceMKPerW
	}

	calculator, err := s.calculatorCatalog.Get(
		references.OperationCode,
	)
	if err != nil {
		return domain.CalculationResult{},
			fmt.Errorf(
				"select calculator: %w",
				err,
			)
	}

	result, err := calculator.Calculate(
		domain.CalculationInput{
			LengthM: requestData.LengthM,

			WaterTemperatureC: requestData.WaterTemperatureC,

			SoilTemperatureC: requestData.SoilTemperatureC,

			PeriodStart: requestData.PeriodStart,

			PeriodEnd: requestData.PeriodEnd,

			InsulationResistanceMKPerW: references.
				InsulationResistanceMKPerW,

			SoilResistanceMKPerW: soilResistance,
		},
	)
	if err != nil {
		return domain.CalculationResult{},
			fmt.Errorf(
				"%w: %v",
				ErrInvalidInput,
				err,
			)
	}

	result.OperationCode =
		references.OperationCode

	return result, nil
}
