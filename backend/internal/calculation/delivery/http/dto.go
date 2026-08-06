package calculationhttp

import (
	"fmt"
	"time"

	"lostHeat/internal/calculation/domain"
	"lostHeat/internal/calculation/service"
)

const dateLayout = "2006-01-02"

type calculateRequest struct {
	Name string `json:"name"`

	CalculationOperationID string `json:"calculationOperationId"`

	BoilerHouseID string `json:"boilerHouseId"`
	Section       string `json:"section"`

	PeriodStart string `json:"periodStart"`
	PeriodEnd   string `json:"periodEnd"`

	CommissioningYear int `json:"commissioningYear"`

	NetworkTypeID  string `json:"networkTypeId"`
	LayingMethodID string `json:"layingMethodId"`

	LengthM              float64  `json:"lengthM"`
	BurialDepthM         *float64 `json:"burialDepthM"`
	SupplyPipeDiameterMM float64  `json:"supplyPipeDiameterMm"`
	ReturnPipeDiameterMM float64  `json:"returnPipeDiameterMm"`
	WaterTemperatureC    float64  `json:"waterTemperatureC"`

	InsulationMaterialID string  `json:"insulationMaterialId"`
	SoilTypeID           *string `json:"soilTypeId"`
	SoilTemperatureC     float64 `json:"soilTemperatureC"`
}

func (request calculateRequest) toRequestData() (
	service.CalculationRequestData,
	error,
) {
	periodStart, err := time.Parse(
		dateLayout,
		request.PeriodStart,
	)
	if err != nil {
		return service.CalculationRequestData{},
			fmt.Errorf(
				"parse periodStart: %w",
				err,
			)
	}

	periodEnd, err := time.Parse(
		dateLayout,
		request.PeriodEnd,
	)
	if err != nil {
		return service.CalculationRequestData{},
			fmt.Errorf(
				"parse periodEnd: %w",
				err,
			)
	}

	return service.CalculationRequestData{
		Name: request.Name,

		CalculationOperationID: request.CalculationOperationID,

		BoilerHouseID: request.BoilerHouseID,

		Section: request.Section,

		PeriodStart: periodStart,

		PeriodEnd: periodEnd,

		CommissioningYear: request.CommissioningYear,

		NetworkTypeID: request.NetworkTypeID,

		LayingMethodID: request.LayingMethodID,

		LengthM: request.LengthM,

		BurialDepthM: request.BurialDepthM,

		SupplyPipeDiameterMM: request.SupplyPipeDiameterMM,

		ReturnPipeDiameterMM: request.ReturnPipeDiameterMM,

		WaterTemperatureC: request.WaterTemperatureC,

		InsulationMaterialID: request.InsulationMaterialID,

		SoilTypeID: request.SoilTypeID,

		SoilTemperatureC: request.SoilTemperatureC,
	}, nil
}

type calculateResponse struct {
	OperationCode string `json:"operationCode"`

	PeriodStart string  `json:"periodStart"`
	PeriodEnd   string  `json:"periodEnd"`
	PeriodHours float64 `json:"periodHours"`

	InsulationResistanceMKPerW float64 `json:"insulationResistanceMKPerW"`
	SoilResistanceMKPerW       float64 `json:"soilResistanceMKPerW"`
	TotalResistanceMKPerW      float64 `json:"totalResistanceMKPerW"`

	DeltaTemperatureK float64 `json:"deltaTemperatureK"`
	HeatFlowWPerM     float64 `json:"heatFlowWPerM"`
	HeatLossPowerW    float64 `json:"heatLossPowerW"`

	EnergyKWh float64 `json:"energyKWh"`
}

func newCalculateResponse(
	result domain.CalculationResult,
) calculateResponse {
	return calculateResponse{
		OperationCode: result.OperationCode,

		PeriodStart: result.PeriodStart.Format(dateLayout),

		PeriodEnd: result.PeriodEnd.Format(dateLayout),

		PeriodHours: result.PeriodHours,

		InsulationResistanceMKPerW: result.InsulationResistanceMKPerW,

		SoilResistanceMKPerW: result.SoilResistanceMKPerW,

		TotalResistanceMKPerW: result.TotalResistanceMKPerW,

		DeltaTemperatureK: result.DeltaTemperatureK,

		HeatFlowWPerM: result.HeatFlowWPerM,

		HeatLossPowerW: result.HeatLossPowerW,

		EnergyKWh: result.EnergyKWh,
	}
}
