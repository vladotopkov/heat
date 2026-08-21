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

type SessionRepository struct {
	pool *pgxpool.Pool
}

func NewSessionRepository(
	pool *pgxpool.Pool,
) *SessionRepository {

	return &SessionRepository{
		pool: pool,
	}
}

func (r *SessionRepository) Create(
	ctx context.Context,
) (*domain.QuestionnaireSession, error) {

	const query = `
		INSERT INTO questionnaire_sessions
		DEFAULT VALUES
		RETURNING
			id,
			status,
			selected_table_rule_id,
			selected_qh_table_id,
			selected_qh_row_id,
			created_at,
			updated_at
	`

	return r.scanSession(
		r.pool.QueryRow(
			ctx,
			query,
		),
	)
}

func (r *SessionRepository) GetByID(
	ctx context.Context,
	sessionID int64,
) (*domain.QuestionnaireSession, error) {

	const query = `
		SELECT
			id,
			status,
			selected_table_rule_id,
			selected_qh_table_id,
			selected_qh_row_id,
			created_at,
			updated_at

		FROM questionnaire_sessions

		WHERE id = $1
	`

	session, err :=
		r.scanSession(
			r.pool.QueryRow(
				ctx,
				query,
				sessionID,
			),
		)

	if err != nil {

		if errors.Is(
			err,
			pgx.ErrNoRows,
		) {
			return nil, fmt.Errorf(
				"questionnaire session %d not found",
				sessionID,
			)
		}

		return nil, err
	}

	return session, nil
}

func (r *SessionRepository) SelectTable(
	ctx context.Context,
	sessionID int64,
	ruleID int64,
	tableID int64,
) error {

	const query = `
		UPDATE questionnaire_sessions

		SET
			status = 'TABLE_SELECTED',
			selected_table_rule_id = $2,
			selected_qh_table_id = $3,
			selected_qh_row_id = NULL,
			updated_at = now()

		WHERE id = $1
	`

	result, err := r.pool.Exec(
		ctx,
		query,
		sessionID,
		ruleID,
		tableID,
	)

	if err != nil {
		return fmt.Errorf(
			"select qh table for session: %w",
			err,
		)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf(
			"questionnaire session %d not found",
			sessionID,
		)
	}

	return nil
}

func (r *SessionRepository) SelectRow(
	ctx context.Context,
	sessionID int64,
	rowID int64,
) error {

	const query = `
		UPDATE questionnaire_sessions

		SET
			status = 'ROW_SELECTED',
			selected_qh_row_id = $2,
			updated_at = now()

		WHERE id = $1
		  AND selected_qh_table_id IS NOT NULL
	`

	result, err := r.pool.Exec(
		ctx,
		query,
		sessionID,
		rowID,
	)

	if err != nil {
		return fmt.Errorf(
			"select qh row for session: %w",
			err,
		)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf(
			"questionnaire session %d not found or qh table is not selected",
			sessionID,
		)
	}

	return nil
}

func (r *SessionRepository) SetStatus(
	ctx context.Context,
	sessionID int64,
	status domain.QuestionnaireStatus,
) error {

	const query = `
		UPDATE questionnaire_sessions

		SET
			status = $2,
			updated_at = now()

		WHERE id = $1
	`

	result, err := r.pool.Exec(
		ctx,
		query,
		sessionID,
		string(status),
	)

	if err != nil {
		return fmt.Errorf(
			"update questionnaire status: %w",
			err,
		)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf(
			"questionnaire session %d not found",
			sessionID,
		)
	}

	return nil
}

type sessionScanner interface {
	Scan(dest ...any) error
}

func (r *SessionRepository) scanSession(
	row sessionScanner,
) (*domain.QuestionnaireSession, error) {

	var session domain.QuestionnaireSession

	var status string

	var selectedTableRuleID pgtype.Int8
	var selectedQHTableID pgtype.Int8
	var selectedQHRowID pgtype.Int8

	err := row.Scan(
		&session.ID,
		&status,
		&selectedTableRuleID,
		&selectedQHTableID,
		&selectedQHRowID,
		&session.CreatedAt,
		&session.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf(
			"scan questionnaire session: %w",
			err,
		)
	}

	session.Status =
		domain.QuestionnaireStatus(status)

	if selectedTableRuleID.Valid {
		value := selectedTableRuleID.Int64

		session.SelectedTableRuleID =
			&value
	}

	if selectedQHTableID.Valid {
		value := selectedQHTableID.Int64

		session.SelectedQHTableID =
			&value
	}

	if selectedQHRowID.Valid {
		value := selectedQHRowID.Int64

		session.SelectedQHRowID =
			&value
	}

	return &session, nil
}