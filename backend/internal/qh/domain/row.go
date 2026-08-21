package domain

type QHRow struct {
	ID int64

	TableID int64

	SourceRowNo int

	Note *string

	IsActive bool

	DimensionValues []QHRowDimensionValue
}

type QHRowDimensionValue struct {
	RowID int64

	DimensionID int64

	ValueNumeric *float64
	ValueText    *string
}