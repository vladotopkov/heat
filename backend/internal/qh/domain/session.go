package domain

import "time"

type QuestionnaireStatus string

const (
	QuestionnaireStatusInProgress    QuestionnaireStatus = "IN_PROGRESS"
	QuestionnaireStatusTableSelected QuestionnaireStatus = "TABLE_SELECTED"
	QuestionnaireStatusRowSelected   QuestionnaireStatus = "ROW_SELECTED"
	QuestionnaireStatusCompleted     QuestionnaireStatus = "COMPLETED"
	QuestionnaireStatusUnsupported   QuestionnaireStatus = "UNSUPPORTED"
	QuestionnaireStatusAmbiguous     QuestionnaireStatus = "AMBIGUOUS"
	QuestionnaireStatusError         QuestionnaireStatus = "ERROR"
)

type QuestionnaireSession struct {
	ID int64

	Status QuestionnaireStatus

	SelectedTableRuleID *int64
	SelectedQHTableID   *int64
	SelectedQHRowID     *int64

	CreatedAt time.Time
	UpdatedAt time.Time
}

type QuestionnaireAnswer struct {
	ID int64

	SessionID int64

	QuestionCode string

	ValueText    *string
	ValueNumeric *float64
	ValueDate    *time.Time
	ValueBoolean *bool

	CreatedAt time.Time
	UpdatedAt time.Time
}

