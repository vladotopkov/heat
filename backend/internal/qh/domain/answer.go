package domain

import "time"

type Answer struct {
	QuestionCode string

	TextValue    *string
	NumberValue  *float64
	DateValue    *time.Time
	BooleanValue *bool
}