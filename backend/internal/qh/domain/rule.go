package domain

import "time"

type RuleOperator string

const (
	RuleOperatorEQ      RuleOperator = "EQ"
	RuleOperatorNEQ     RuleOperator = "NEQ"
	RuleOperatorGT      RuleOperator = "GT"
	RuleOperatorGTE     RuleOperator = "GTE"
	RuleOperatorLT      RuleOperator = "LT"
	RuleOperatorLTE     RuleOperator = "LTE"
	RuleOperatorBetween RuleOperator = "BETWEEN"
)

type QHSelectionRule struct {
	ID int64

	Code string

	QHTableID int64

	Priority int

	Description *string

	IsActive bool

	Conditions []QHRuleCondition
}

type QHRuleCondition struct {
	ID int64

	RuleID int64

	QuestionCode string

	Operator RuleOperator

	ValueText *string

	ValueNumeric   *float64
	ValueNumericTo *float64

	ValueDate   *time.Time
	ValueDateTo *time.Time

	ValueBoolean *bool
}