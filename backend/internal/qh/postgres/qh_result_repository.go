package postgres

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/qh/domain"
)

type QHResultRepository struct {
	pool *pgxpool.Pool
}

func NewQHResultRepository(
	pool *pgxpool.Pool,
) *QHResultRepository {

	return &QHResultRepository{
		pool: pool,
	}
}

func (r *QHResultRepository) ReplaceForSession(
	ctx context.Context,
	sessionID int64,
	results []domain.QHResult,
) ([]domain.QHResult, error) {

	tx, err :=
		r.pool.Begin(ctx)

	if err != nil {
		return nil, fmt.Errorf(
			"begin qh result transaction: %w",
			err,
		)
	}

	defer tx.Rollback(ctx)

	_, err =
		tx.Exec(
			ctx,
			`
				DELETE FROM qh_results
				WHERE session_id = $1
			`,
			sessionID,
		)

	if err != nil {
		return nil, fmt.Errorf(
			"delete previous qh results: %w",
			err,
		)
	}

	saved :=
		make(
			[]domain.QHResult,
			0,
			len(results),
		)

	const insertQuery = `
		INSERT INTO qh_results (
			session_id,
			qh_table_id,
			qh_row_id,
			pipeline_role,
			calculated_supply_temperature_c,
			calculated_return_temperature_c,
			base_qh_w_per_m,
			adjusted_qh_w_per_m,
			calculation_details
		)
		VALUES (
			$1,
			$2,
			$3,
			$4,
			$5,
			$6,
			$7,
			$8,
			$9::jsonb
		)
		RETURNING
			id,
			created_at
	`

	for _, result := range results {

		details :=
			result.CalculationDetails

		if len(details) == 0 {
			details =
				json.RawMessage(`{}`)
		}

		err :=
			tx.QueryRow(
				ctx,
				insertQuery,
				result.SessionID,
				result.QHTableID,
				result.QHRowID,
				string(result.PipelineRole),
				result.CalculatedSupplyTemperatureC,
				result.CalculatedReturnTemperatureC,
				result.BaseQHWPerM,
				result.AdjustedQHWPerM,
				string(details),
			).Scan(
				&result.ID,
				&result.CreatedAt,
			)

		if err != nil {
			return nil, fmt.Errorf(
				"insert qh result: %w",
				err,
			)
		}

		saved = append(
			saved,
			result,
		)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf(
			"commit qh result transaction: %w",
			err,
		)
	}

	return saved, nil
}

func (r *QHResultRepository) GetBySessionID(
	ctx context.Context,
	sessionID int64,
) ([]domain.QHResult, error) {

	const query = `
		SELECT
			id,
			session_id,
			qh_table_id,
			qh_row_id,
			pipeline_role,
			calculated_supply_temperature_c::double precision,
			calculated_return_temperature_c::double precision,
			base_qh_w_per_m::double precision,
			adjusted_qh_w_per_m::double precision,
			calculation_details,
			created_at

		FROM qh_results

		WHERE session_id = $1

		ORDER BY pipeline_role
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		sessionID,
	)

	if err != nil {
		return nil, fmt.Errorf(
			"query qh results: %w",
			err,
		)
	}

	defer rows.Close()

	var result []domain.QHResult

	for rows.Next() {

		var item domain.QHResult

		var role string

		var details []byte

		err := rows.Scan(
			&item.ID,
			&item.SessionID,
			&item.QHTableID,
			&item.QHRowID,
			&role,
			&item.CalculatedSupplyTemperatureC,
			&item.CalculatedReturnTemperatureC,
			&item.BaseQHWPerM,
			&item.AdjustedQHWPerM,
			&details,
			&item.CreatedAt,
		)

		if err != nil {
			return nil, fmt.Errorf(
				"scan qh result: %w",
				err,
			)
		}

		item.PipelineRole =
			domain.PipelineRole(role)

		item.CalculationDetails =
			details

		result = append(
			result,
			item,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate qh results: %w",
			err,
		)
	}

	return result, nil
}