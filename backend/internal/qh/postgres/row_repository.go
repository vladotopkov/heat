package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/qh/domain"
)

type RowRepository struct {
	pool *pgxpool.Pool
}

func NewRowRepository(
	pool *pgxpool.Pool,
) *RowRepository {

	return &RowRepository{
		pool: pool,
	}
}

func (r *RowRepository) GetByTableID(
	ctx context.Context,
	tableID int64,
) ([]domain.QHRow, error) {

	const query = `
		SELECT
			r.id,
			r.table_id,
			r.source_row_no,
			r.note,
			r.is_active,

			rdv.dimension_id,
			rdv.value_numeric::double precision,
			rdv.value_text

		FROM qh_rows r

		LEFT JOIN qh_row_dimension_values rdv
			ON rdv.row_id = r.id

		WHERE r.table_id = $1
		  AND r.is_active = true

		ORDER BY
			r.source_row_no ASC,
			rdv.dimension_id ASC
	`

	return r.queryRows(
		ctx,
		query,
		tableID,
	)
}

func (r *RowRepository) GetByID(
	ctx context.Context,
	rowID int64,
) (*domain.QHRow, error) {

	const query = `
		SELECT
			r.id,
			r.table_id,
			r.source_row_no,
			r.note,
			r.is_active,

			rdv.dimension_id,
			rdv.value_numeric::double precision,
			rdv.value_text

		FROM qh_rows r

		LEFT JOIN qh_row_dimension_values rdv
			ON rdv.row_id = r.id

		WHERE r.id = $1

		ORDER BY rdv.dimension_id ASC
	`

	rows, err := r.queryRows(
		ctx,
		query,
		rowID,
	)

	if err != nil {
		return nil, err
	}

	if len(rows) == 0 {
		return nil, fmt.Errorf(
			"qh row %d not found",
			rowID,
		)
	}

	return &rows[0], nil
}

func (r *RowRepository) queryRows(
	ctx context.Context,
	query string,
	args ...any,
) ([]domain.QHRow, error) {

	rows, err := r.pool.Query(
		ctx,
		query,
		args...,
	)

	if err != nil {
		return nil, fmt.Errorf(
			"query qh rows: %w",
			err,
		)
	}

	defer rows.Close()

	var result []domain.QHRow

	var currentRow *domain.QHRow

	for rows.Next() {

		var rowID int64
		var tableID int64
		var sourceRowNo int

		var note pgtype.Text

		var isActive bool

		var dimensionID pgtype.Int8
		var valueNumeric pgtype.Float8
		var valueText pgtype.Text

		err := rows.Scan(
			&rowID,
			&tableID,
			&sourceRowNo,
			&note,
			&isActive,

			&dimensionID,
			&valueNumeric,
			&valueText,
		)

		if err != nil {
			return nil, fmt.Errorf(
				"scan qh row: %w",
				err,
			)
		}

		// Началась новая строка qh_rows.
		if currentRow == nil ||
			currentRow.ID != rowID {

			row := domain.QHRow{
				ID:          rowID,
				TableID:     tableID,
				SourceRowNo: sourceRowNo,
				IsActive:    isActive,
			}

			if note.Valid {
				value := note.String
				row.Note = &value
			}

			result = append(
				result,
				row,
			)

			currentRow =
				&result[len(result)-1]
		}

		// LEFT JOIN позволяет теоретически получить
		// строку без dimension value.
		if !dimensionID.Valid {
			continue
		}

		dimensionValue :=
			domain.QHRowDimensionValue{
				RowID:
					rowID,

				DimensionID:
					dimensionID.Int64,
			}

		if valueNumeric.Valid {
			value := valueNumeric.Float64

			dimensionValue.ValueNumeric =
				&value
		}

		if valueText.Valid {
			value := valueText.String

			dimensionValue.ValueText =
				&value
		}

		currentRow.DimensionValues =
			append(
				currentRow.DimensionValues,
				dimensionValue,
			)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate qh rows: %w",
			err,
		)
	}

	return result, nil
}