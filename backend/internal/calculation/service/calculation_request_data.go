package service

import "time"

// CalculationRequestData содержит данные,
// необходимые service-слою для выполнения расчёта.
type CalculationRequestData struct {
	Name string

	CalculationOperationID string

	BoilerHouseID string
	Section       string

	PeriodStart time.Time
	PeriodEnd   time.Time

	CommissioningYear int

	NetworkTypeID  string
	LayingMethodID string

	LengthM              float64
	BurialDepthM         *float64
	SupplyPipeDiameterMM float64
	ReturnPipeDiameterMM float64
	WaterTemperatureC    float64

	InsulationMaterialID string
	SoilTypeID           *string
	SoilTemperatureC     float64
}
