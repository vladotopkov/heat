package service

import (
	"fmt"
	"strings"
	"time"
)

func validateCalculationRequestData(
	requestData CalculationRequestData,
) error {
	if strings.TrimSpace(requestData.Name) == "" {
		return fmt.Errorf(
			"%w: name is required",
			ErrInvalidInput,
		)
	}

	if strings.TrimSpace(requestData.Section) == "" {
		return fmt.Errorf(
			"%w: section is required",
			ErrInvalidInput,
		)
	}

	requiredIDs := map[string]string{
		"calculationOperationId": requestData.CalculationOperationID,

		"boilerHouseId": requestData.BoilerHouseID,

		"networkTypeId": requestData.NetworkTypeID,

		"layingMethodId": requestData.LayingMethodID,

		"insulationMaterialId": requestData.InsulationMaterialID,
	}

	for fieldName, value := range requiredIDs {
		if strings.TrimSpace(value) == "" {
			return fmt.Errorf(
				"%w: %s is required",
				ErrInvalidInput,
				fieldName,
			)
		}
	}

	if requestData.PeriodStart.IsZero() {
		return fmt.Errorf(
			"%w: periodStart is required",
			ErrInvalidInput,
		)
	}

	if requestData.PeriodEnd.IsZero() {
		return fmt.Errorf(
			"%w: periodEnd is required",
			ErrInvalidInput,
		)
	}

	if requestData.PeriodEnd.Before(
		requestData.PeriodStart,
	) {
		return fmt.Errorf(
			"%w: periodEnd must not be before periodStart",
			ErrInvalidInput,
		)
	}

	if requestData.LengthM <= 0 {
		return fmt.Errorf(
			"%w: lengthM must be greater than zero",
			ErrInvalidInput,
		)
	}

	if requestData.SupplyPipeDiameterMM <= 0 {
		return fmt.Errorf(
			"%w: supplyPipeDiameterMm must be greater than zero",
			ErrInvalidInput,
		)
	}

	if requestData.ReturnPipeDiameterMM <= 0 {
		return fmt.Errorf(
			"%w: returnPipeDiameterMm must be greater than zero",
			ErrInvalidInput,
		)
	}

	if requestData.BurialDepthM != nil &&
		*requestData.BurialDepthM < 0 {
		return fmt.Errorf(
			"%w: burialDepthM must not be negative",
			ErrInvalidInput,
		)
	}

	currentYear := time.Now().Year()

	if requestData.CommissioningYear < 1900 ||
		requestData.CommissioningYear >
			currentYear {
		return fmt.Errorf(
			"%w: commissioningYear must be between 1900 and %d",
			ErrInvalidInput,
			currentYear,
		)
	}

	if requestData.SupplyWaterTemperatureC <=
		requestData.SoilTemperatureC {
		return fmt.Errorf(
			"%w: SupplyWaterTemperatureC must be greater than soilTemperatureC",
			ErrInvalidInput,
		)
	}

	if requestData.ReturnWaterTemperatureC <=
		requestData.ReturnWaterTemperatureC {
		return fmt.Errorf(
			"%w: ReturnWaterTemperatureC must be greater than soilTemperatureC",
			ErrInvalidInput,
		)
	}

	return nil
}
