package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/qh/domain"
)

type TableDimensionRepository struct {
	pool *pgxpool.Pool
}

func NewTableDimensionRepository(
	pool *pgxpool.Pool,
) *TableDimensionRepository {

	return &TableDimensionRepository{
		pool: pool,
	}
}

func (r *TableDimensionRepository) GetByTableID(
	ctx context.Context,
	tableID int64,
) ([]domain.QHTableDimensionConfig, error) {

	const query = `
		SELECT
			td.table_id,
			td.sequence_no,

			d.id,
			d.code,
			d.question_code,
			d.value_type,
			d.unit,
			d.description

		FROM qh_table_dimensions td

		JOIN qh_dimensions d
			ON d.id = td.dimension_id

		WHERE td.table_id = $1

		ORDER BY td.sequence_no ASC
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		tableID,
	)

	if err != nil {
		return nil, fmt.Errorf(
			"query table dimensions: %w",
			err,
		)
	}

	defer rows.Close()

	var result []domain.QHTableDimensionConfig

	for rows.Next() {

		var config domain.QHTableDimensionConfig

		var valueType string

		var unit pgtype.Text
		var description pgtype.Text

		err := rows.Scan(
			&config.TableID,
			&config.SequenceNo,

			&config.Dimension.ID,
			&config.Dimension.Code,
			&config.Dimension.QuestionCode,
			&valueType,
			&unit,
			&description,
		)

		if err != nil {
			return nil, fmt.Errorf(
				"scan table dimension: %w",
				err,
			)
		}

		config.Dimension.ValueType =
			domain.DimensionValueType(valueType)

		if unit.Valid {
			value := unit.String
			config.Dimension.Unit = &value
		}

		if description.Valid {
			value := description.String
			config.Dimension.Description = &value
		}

		result = append(
			result,
			config,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate table dimensions: %w",
			err,
		)
	}

	return result, nil
}