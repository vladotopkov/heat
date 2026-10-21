package domain

import (
	"errors"
	"time"
)

var ErrInvalidMonth = errors.New("invalid month")

type CalculationInput struct {
	HeatNetworkID   int64
	HeatNetworkName string
	Month           time.Time

	ProjectSupply *float64
	ProjectReturn *float64
	ProjectGround *float64

	ActualSupply *float64
	ActualReturn *float64
	ActualGround *float64
	Hours        *int
}

type NetworkLoss struct {
	HeatNetworkID   int64
	HeatNetworkName string
	Month           time.Time

	TotalNormalizedHeatLossPerHour *float64
	LossGJ                         *float64
	CalculationError               *string
}
