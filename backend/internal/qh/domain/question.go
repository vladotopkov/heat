package domain

type QuestionPhase string

const (
	QuestionPhaseTableSelection QuestionPhase = "TABLE_SELECTION"
	QuestionPhaseRowSelection   QuestionPhase = "ROW_SELECTION"
	QuestionPhaseTemperature    QuestionPhase = "TEMPERATURE"
	QuestionPhaseAdjustment     QuestionPhase = "ADJUSTMENT"
)

type InputType string

const (
	InputTypeText    InputType = "text"
	InputTypeNumber  InputType = "number"
	InputTypeDate    InputType = "date"
	InputTypeBoolean InputType = "boolean"
	InputTypeSelect  InputType = "select"
)

type OptionSource string

const (
	OptionSourceStatic             OptionSource = "STATIC"
	OptionSourceQHRows             OptionSource = "QH_ROWS"
	OptionSourceTemperatureRegimes OptionSource = "TEMPERATURE_REGIMES"
)

type Question struct {
	Code string

	Label       string
	Description *string

	Phase     QuestionPhase
	InputType InputType

	Unit *string

	SelectionOrder int

	OptionSource *OptionSource

	IsActive bool
}

type QuestionOption struct {
	ID int64

	QuestionCode string

	Value string
	Label string

	SortOrder int

	IsActive bool
}