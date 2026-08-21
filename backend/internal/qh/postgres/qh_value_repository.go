package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/qh/domain"
)

type QHValueRepository struct {
	pool *pgxpool.Pool
}

func NewQHValueRepository(
	pool *pgxpool.Pool,
) *QHValueRepository {

	return &QHValueRepository{
		pool: pool,
	}
}

func (r *QHValueRepository) GetByRowID(
	ctx context.Context,
	rowID int64,
) ([]domain.QHValue, error) {

	const query = `
		SELECT
			id,
			row_id,
			pipeline_role,
			placement_variant,
			supply_temperature_c::double precision,
			return_temperature_c::double precision,
			qh_w_per_m::double precision,
			source_interpolated,
			note

		FROM qh_values

		WHERE row_id = $1

		ORDER BY
			pipeline_role,
			supply_temperature_c,
			return_temperature_c
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		rowID,
	)

	if err != nil {
		return nil, fmt.Errorf(
			"query qh values: %w",
			err,
		)
	}

	defer rows.Close()

	var result []domain.QHValue

	for rows.Next() {

		var value domain.QHValue

		var role string

		var placementVariant pgtype.Text
		var supplyTemperature pgtype.Float8
		var returnTemperature pgtype.Float8
		var note pgtype.Text

		err := rows.Scan(
			&value.ID,
			&value.RowID,
			&role,
			&placementVariant,
			&supplyTemperature,
			&returnTemperature,
			&value.QHWPerM,
			&value.SourceInterpolated,
			&note,
		)

		if err != nil {
			return nil, fmt.Errorf(
				"scan qh value: %w",
				err,
			)
		}

		value.PipelineRole =
			domain.PipelineRole(role)

		if placementVariant.Valid {
			v := placementVariant.String

			value.PlacementVariant = &v
		}

		if supplyTemperature.Valid {
			v := supplyTemperature.Float64

			value.SupplyTemperatureC = &v
		}

		if returnTemperature.Valid {
			v := returnTemperature.Float64

			value.ReturnTemperatureC = &v
		}

		if note.Valid {
			v := note.String

			value.Note = &v
		}

		result = append(
			result,
			value,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate qh values: %w",
			err,
		)
	}

	return result, nil
}