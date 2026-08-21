package domain

type QHTableDimensionConfig struct {
	TableID int64

	Dimension QHDimension

	SequenceNo int
}

type RowSelectionOption struct {
	ValueText    *string
	ValueNumeric *float64

	Label string
}

type RowSelectionResult struct {
	Session *QuestionnaireSession

	// Если строка ещё не определена —
	// здесь будет следующий вопрос.
	Question *Question

	// Варианты ответа, полученные из qh_rows.
	Options []RowSelectionOption // НЕ ПОНЯТНО ЗАЧЕМ НУЖНЫ

	// Если строка уже определена —
	// здесь будет найденная строка.
	SelectedRow *QHRow
}