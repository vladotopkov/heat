package domain

import "time"

type AdjustmentOperation string

const (
	AdjustmentOperationMultiply       AdjustmentOperation = "MULTIPLY"
	AdjustmentOperationDivide         AdjustmentOperation = "DIVIDE"
	AdjustmentOperationLookupMultiply AdjustmentOperation = "LOOKUP_MULTIPLY" //what the fuck you talking about nigga
)

type QHAdjustmentRule struct {
	ID int64

	QHTableID *int64

	ProjectDateFrom *time.Time
	ProjectDateTo   *time.Time

	PipeType     *string
	LayingMethod *string

	Operation AdjustmentOperation

	Factor *float64

	RequiresQuestion *string

	CoefficientSource *string

	Description *string

	IsActive bool
}

type QHMaterialCoefficient struct {
	ID int64

	SourceTableCode string

	InsulationMaterial string

	NominalBoreFromMM *float64
	NominalBoreToMM   *float64

	Factor float64
}