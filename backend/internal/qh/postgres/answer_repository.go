package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/qh/domain"
)

type AnswerRepository struct {
	pool *pgxpool.Pool
}

func NewAnswerRepository(
	pool *pgxpool.Pool,
) *AnswerRepository {
	return &AnswerRepository{
		pool: pool,
	}
}

func (r *AnswerRepository) Save(
	ctx context.Context,
	answer domain.QuestionnaireAnswer,
) error {

	const query = `
		INSERT INTO questionnaire_answers (
			session_id,
			question_code,
			value_text,
			value_numeric,
			value_date,
			value_boolean
		)
		VALUES (
			$1,
			$2,
			$3,
			$4,
			$5,
			$6
		)
		ON CONFLICT (
			session_id,
			question_code
		)
		DO UPDATE SET
			value_text = EXCLUDED.value_text,
			value_numeric = EXCLUDED.value_numeric,
			value_date = EXCLUDED.value_date,
			value_boolean = EXCLUDED.value_boolean,
			updated_at = now()
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		answer.SessionID,
		answer.QuestionCode,
		answer.ValueText,
		answer.ValueNumeric,
		answer.ValueDate,
		answer.ValueBoolean,
	)

	if err != nil {
		return fmt.Errorf(
			"save questionnaire answer: %w",
			err,
		)
	}

	return nil
}

func (r *AnswerRepository) GetBySessionID(
	ctx context.Context,
	sessionID int64,
) ([]domain.QuestionnaireAnswer, error) {

	const query = `
		SELECT
			id,
			session_id,
			question_code,
			value_text,
			value_numeric::double precision,
			value_date,
			value_boolean,
			created_at,
			updated_at
		FROM questionnaire_answers
		WHERE session_id = $1
		ORDER BY id
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		sessionID,
	)

	if err != nil {
		return nil, fmt.Errorf(
			"query questionnaire answers: %w",
			err,
		)
	}

	defer rows.Close()

	var answers []domain.QuestionnaireAnswer

	for rows.Next() {

		var answer domain.QuestionnaireAnswer

		var valueText pgtype.Text
		var valueNumeric pgtype.Float8
		var valueDate pgtype.Date
		var valueBoolean pgtype.Bool

		err := rows.Scan(
			&answer.ID,
			&answer.SessionID,
			&answer.QuestionCode,
			&valueText,
			&valueNumeric,
			&valueDate,
			&valueBoolean,
			&answer.CreatedAt,
			&answer.UpdatedAt,
		)

		if err != nil {
			return nil, fmt.Errorf(
				"scan questionnaire answer: %w",
				err,
			)
		}

		if valueText.Valid {
			value := valueText.String
			answer.ValueText = &value
		}

		if valueNumeric.Valid {
			value := valueNumeric.Float64
			answer.ValueNumeric = &value
		}

		if valueDate.Valid {
			value := valueDate.Time
			answer.ValueDate = &value
		}

		if valueBoolean.Valid {
			value := valueBoolean.Bool
			answer.ValueBoolean = &value
		}

		answers = append(
			answers,
			answer,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate questionnaire answers: %w",
			err,
		)
	}

	return answers, nil
}