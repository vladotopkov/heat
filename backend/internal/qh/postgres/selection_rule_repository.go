package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/qh/domain"
)

type SelectionRuleRepository struct {
	pool *pgxpool.Pool
}

func NewSelectionRuleRepository(
	pool *pgxpool.Pool,
) *SelectionRuleRepository {
	return &SelectionRuleRepository{
		pool: pool,
	}
}

func (r *SelectionRuleRepository) GetActive(
	ctx context.Context,
) ([]domain.QHSelectionRule, error) {

	const query = `
		SELECT
			r.id,
			r.code,
			r.qh_table_id,
			r.priority,
			r.description,
			r.is_active,

			c.id,
			c.rule_id,
			c.question_code,
			c.operator,
			c.value_text,
			c.value_numeric::double precision,
			c.value_numeric_to::double precision,
			c.value_date,
			c.value_date_to,
			c.value_boolean

		FROM qh_selection_rules r

		JOIN qh_rule_conditions c
			ON c.rule_id = r.id

		WHERE r.is_active = true

		ORDER BY
			r.priority ASC,
			r.id ASC,
			c.id ASC
	`

	rows, err := r.pool.Query(
		ctx,
		query,
	)

	if err != nil {
		return nil, fmt.Errorf(
			"query selection rules: %w",
			err,
		)
	}

	defer rows.Close()

	var result []domain.QHSelectionRule

	var currentRuleID int64 = -1

	for rows.Next() {

		var ruleID int64
		var ruleCode string
		var tableID int64
		var priority int
		var ruleDescription pgtype.Text
		var ruleActive bool

		var condition domain.QHRuleCondition

		var operator string

		var valueText pgtype.Text

		var valueNumeric pgtype.Float8
		var valueNumericTo pgtype.Float8

		var valueDate pgtype.Date
		var valueDateTo pgtype.Date

		var valueBoolean pgtype.Bool

		err := rows.Scan(
			&ruleID,
			&ruleCode,
			&tableID,
			&priority,
			&ruleDescription,
			&ruleActive,

			&condition.ID,
			&condition.RuleID,
			&condition.QuestionCode,
			&operator,
			&valueText,
			&valueNumeric,
			&valueNumericTo,
			&valueDate,
			&valueDateTo,
			&valueBoolean,
		)

		if err != nil {
			return nil, fmt.Errorf(
				"scan selection rule: %w",
				err,
			)
		}

		condition.Operator =
			domain.RuleOperator(operator)

		if valueText.Valid {
			value := valueText.String
			condition.ValueText = &value
		}

		if valueNumeric.Valid {
			value := valueNumeric.Float64
			condition.ValueNumeric = &value
		}

		if valueNumericTo.Valid {
			value := valueNumericTo.Float64
			condition.ValueNumericTo = &value
		}

		if valueDate.Valid {
			value := valueDate.Time
			condition.ValueDate = &value
		}

		if valueDateTo.Valid {
			value := valueDateTo.Time
			condition.ValueDateTo = &value
		}

		if valueBoolean.Valid {
			value := valueBoolean.Bool
			condition.ValueBoolean = &value
		}

		if ruleID != currentRuleID {

			rule := domain.QHSelectionRule{
				ID:        ruleID,
				Code:      ruleCode,
				QHTableID: tableID,
				Priority:  priority,
				IsActive:  ruleActive,
			}

			if ruleDescription.Valid {
				value :=
					ruleDescription.String

				rule.Description = &value
			}

			result = append(
				result,
				rule,
			)

			currentRuleID = ruleID
		}

		lastIndex := len(result) - 1

		result[lastIndex].Conditions =
			append(
				result[lastIndex].Conditions,
				condition,
			)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate selection rules: %w",
			err,
		)
	}

	return result, nil
}