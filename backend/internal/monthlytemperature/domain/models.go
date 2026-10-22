package domain

import (
	"errors"
	"time"
)

var (
	ErrHeatNetworkNotFound = errors.New("heat network not found")
	ErrInvalidMonth        = errors.New("invalid month")
	ErrInvalidTemperature  = errors.New("invalid temperature")
)

type NetworkTemperature struct {
	ID              *int64
	HeatNetworkID   int64
	HeatNetworkName string
	Month           time.Time
	Supply          *float64
	Return          *float64
	Ground          *float64
	GVSSupply       *float64
	GVSReturn       *float64
}

type Values struct {
	Supply    float64
	Return    float64
	Ground    float64
	GVSSupply *float64
	GVSReturn *float64
}
