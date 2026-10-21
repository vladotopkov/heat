package domain

import (
	"errors"
	"time"
)

var (
	ErrHeatNetworkNotFound = errors.New("heat network not found")
	ErrInvalidMonth        = errors.New("invalid month")
	ErrInvalidHours        = errors.New("invalid hours per month")
)

type NetworkUptime struct {
	ID              *int64
	HeatNetworkID   int64
	HeatNetworkName string
	Month           time.Time
	HoursPerMonth   *int
}
