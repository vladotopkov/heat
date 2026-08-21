package domain

type DimensionValueType string

const (
	DimensionValueTypeNumber DimensionValueType = "NUMBER"
	DimensionValueTypeText   DimensionValueType = "TEXT"
)

type QHDimension struct {
	ID int64

	Code string

	QuestionCode string

	ValueType DimensionValueType

	Unit *string

	Description *string
}

type QHTableDimension struct {
	TableID int64

	DimensionID int64

	SequenceNo int
}
