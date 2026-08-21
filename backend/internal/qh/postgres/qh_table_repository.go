package postgres

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/qh/domain"
)

type QHTableRepository struct {
	pool *pgxpool.Pool
}

func NewQHTableRepository(
	pool *pgxpool.Pool,
) *QHTableRepository {
	return &QHTableRepository{
		pool: pool,
	}
}

func (r *QHTableRepository) GetByID(
	ctx context.Context,
	tableID int64,
) (*domain.QHTable, error) {

	const query = `
		SELECT
			id,
			code,
			appendix,
			title,
			table_kind,
			is_active
		FROM qh_tables
		WHERE id = $1
	`

	var table domain.QHTable

	var tableKind string

	err := r.pool.QueryRow(
		ctx,
		query,
		tableID,
	).Scan(
		&table.ID,
		&table.Code,
		&table.Appendix,
		&table.Title,
		&tableKind,
		&table.IsActive,
	)

	if err != nil {

		if errors.Is(
			err,
			pgx.ErrNoRows,
		) {
			return nil, fmt.Errorf(
				"qh table %d not found",
				tableID,
			)
		}

		return nil, fmt.Errorf(
			"query qh table: %w",
			err,
		)
	}

	table.Kind =
		domain.QHTableKind(tableKind)

	return &table, nil
}