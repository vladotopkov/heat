package domain

import (
	"encoding/json"
	"time"
)

type QHResult struct {
	ID int64

	SessionID int64

	QHTableID int64

	QHRowID int64

	PipelineRole PipelineRole

	CalculatedSupplyTemperatureC *float64

	CalculatedReturnTemperatureC *float64

	BaseQHWPerM float64

	AdjustedQHWPerM float64

	CalculationDetails json.RawMessage

	CreatedAt time.Time
}