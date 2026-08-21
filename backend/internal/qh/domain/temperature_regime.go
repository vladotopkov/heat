package domain

type TemperatureRegime struct {
	ID int64

	ProjectSupplyTemperatureC float64
	ProjectReturnTemperatureC float64

	CalculatedSupplyTemperatureC float64
}