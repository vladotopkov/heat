package domain

type PipelineRole string

const (
	PipelineRoleReturn PipelineRole = "RETURN"

	PipelineRoleSupply PipelineRole = "SUPPLY"

	PipelineRoleTwoPipeTotal PipelineRole = "TWO_PIPE_TOTAL"

	PipelineRoleDHWManagement PipelineRole = "DHW_SUPPLY"

	PipelineRoleDHWCirculation PipelineRole = "DHW_CIRCULATION"

	PipelineRoleSingle PipelineRole = "SINGLE"
)

type QHValue struct {
	ID int64

	RowID int64

	PipelineRole PipelineRole

	PlacementVariant *string

	SupplyTemperatureC *float64

	ReturnTemperatureC *float64

	QHWPerM float64

	SourceInterpolated bool

	Note *string
}