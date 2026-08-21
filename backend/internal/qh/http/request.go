package http

type SubmitAnswerRequest struct {
	QuestionCode string `json:"question_code"`

	ValueText    *string  `json:"value_text"`
	ValueNumeric *float64 `json:"value_numeric"`
	ValueDate    *string  `json:"value_date"`
	ValueBoolean *bool    `json:"value_boolean"`
}