package domain

import (
	"errors"
	"time"
)

var ErrInvalidCalculationPeriod = errors.New(
	"invalid calculation period",
)

type CalculationReferenceIDs struct {
	OperationID          string
	BoilerHouseID        string
	NetworkTypeID        string
	LayingMethodID       string
	InsulationMaterialID string
	SoilTypeID           *string
}

type CalculationReferences struct {
	OperationCode    string
	LayingMethodCode string

	InsulationResistanceMKPerW float64
	SoilResistanceMKPerW       *float64
}

type CalculationInput struct {
	LengthM float64

	WaterTemperatureC float64
	SoilTemperatureC  float64

	PeriodStart time.Time
	PeriodEnd   time.Time

	InsulationResistanceMKPerW float64
	SoilResistanceMKPerW       float64
}

type CalculationResult struct {
	OperationCode string

	PeriodStart time.Time
	PeriodEnd   time.Time
	PeriodHours float64

	InsulationResistanceMKPerW float64
	SoilResistanceMKPerW       float64
	TotalResistanceMKPerW      float64

	DeltaTemperatureK float64
	HeatFlowWPerM     float64
	HeatLossPowerW    float64

	EnergyKWh float64
}

func (input CalculationInput) PeriodHours() (float64, error) {
	start := dateOnly(input.PeriodStart)
	end := dateOnly(input.PeriodEnd)

	if start.IsZero() || end.IsZero() {
		return 0, ErrInvalidCalculationPeriod
	}

	if end.Before(start) {
		return 0, ErrInvalidCalculationPeriod
	}

	const hoursPerDay = 24

	periodDays :=
		int(end.Sub(start).Hours()/hoursPerDay) + 1

	return float64(periodDays * hoursPerDay), nil
}

func dateOnly(value time.Time) time.Time {
	return time.Date(
		value.Year(),
		value.Month(),
		value.Day(),
		0,
		0,
		0,
		0,
		time.UTC,
	)
}