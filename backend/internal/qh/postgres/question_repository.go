package postgres

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/qh/domain"
)

type QuestionRepository struct {
	pool *pgxpool.Pool
}

func NewQuestionRepository(
	pool *pgxpool.Pool,
) *QuestionRepository {
	return &QuestionRepository{
		pool: pool,
	}
}

func (r *QuestionRepository) GetByCode(
	ctx context.Context,
	code string,
) (*domain.Question, error) {

	const query = `
		SELECT
			code,
			label,
			description,
			phase,
			input_type,
			unit,
			selection_order,
			option_source,
			is_active
		FROM questions
		WHERE code = $1
		  AND is_active = true
	`

	question, err := scanQuestion(
		r.pool.QueryRow(
			ctx,
			query,
			code,
		),
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf(
				"question %s not found",
				code,
			)
		}

		return nil, err
	}

	return question, nil
}

func (r *QuestionRepository) GetActiveByPhase(
	ctx context.Context,
	phase domain.QuestionPhase,
) ([]domain.Question, error) {

	const query = `
		SELECT
			code,
			label,
			description,
			phase,
			input_type,
			unit,
			selection_order,
			option_source,
			is_active
		FROM questions
		WHERE phase = $1
		  AND is_active = true
		ORDER BY selection_order ASC
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		string(phase),
	)

	if err != nil {
		return nil, fmt.Errorf(
			"query questions by phase: %w",
			err,
		)
	}

	defer rows.Close()

	var questions []domain.Question

	for rows.Next() {

		question, err := scanQuestion(rows)

		if err != nil {
			return nil, err
		}

		questions = append(
			questions,
			*question,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate questions: %w",
			err,
		)
	}

	return questions, nil
}

func (r *QuestionRepository) GetStaticOptions(
	ctx context.Context,
	questionCode string,
) ([]domain.QuestionOption, error) {

	const query = `
		SELECT
			id,
			question_code,
			value,
			label,
			sort_order,
			is_active
		FROM question_options
		WHERE question_code = $1
		  AND is_active = true
		ORDER BY sort_order ASC, id ASC
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		questionCode,
	)

	if err != nil {
		return nil, fmt.Errorf(
			"query question options: %w",
			err,
		)
	}

	defer rows.Close()

	var options []domain.QuestionOption

	for rows.Next() {

		var option domain.QuestionOption

		err := rows.Scan(
			&option.ID,
			&option.QuestionCode,
			&option.Value,
			&option.Label,
			&option.SortOrder,
			&option.IsActive,
		)

		if err != nil {
			return nil, fmt.Errorf(
				"scan question option: %w",
				err,
			)
		}

		options = append(
			options,
			option,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate question options: %w",
			err,
		)
	}

	return options, nil
}

type questionScanner interface {
	Scan(dest ...any) error
}

func scanQuestion(
	row questionScanner,
) (*domain.Question, error) {

	var question domain.Question

	var description pgtype.Text
	var unit pgtype.Text
	var optionSource pgtype.Text

	var phase string
	var inputType string

	err := row.Scan(
		&question.Code,
		&question.Label,
		&description,
		&phase,
		&inputType,
		&unit,
		&question.SelectionOrder,
		&optionSource,
		&question.IsActive,
	)

	if err != nil {
		return nil, err
	}

	question.Phase =
		domain.QuestionPhase(phase)

	question.InputType =
		domain.InputType(inputType)

	if description.Valid {
		value := description.String
		question.Description = &value
	}

	if unit.Valid {
		value := unit.String
		question.Unit = &value
	}

	if optionSource.Valid {
		value :=
			domain.OptionSource(
				optionSource.String,
			)

		question.OptionSource = &value
	}

	return &question, nil
}