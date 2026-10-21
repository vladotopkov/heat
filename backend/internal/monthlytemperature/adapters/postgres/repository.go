package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/monthlytemperature/domain"
)

type Repository struct {
	pool *pgxpool.Pool
}

func New(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) ListForMonth(
	ctx context.Context,
	month time.Time,
) ([]domain.NetworkTemperature, error) {
	const query = `
		SELECT
			t.id,
			hn.id,
			hn.name,
			$1::date,
			t.supply_t::double precision,
			t.return_t::double precision,
			t.ground_t::double precision
		FROM public."HeatNetwork" AS hn
		LEFT JOIN public.temperatures AS t
			ON t.heat_network_id = hn.id
			AND t.month = $1::date
		ORDER BY hn.name, hn.id
	`

	rows, err := r.pool.Query(ctx, query, month)
	if err != nil {
		return nil, fmt.Errorf("list monthly temperatures: %w", err)
	}
	defer rows.Close()

	result := make([]domain.NetworkTemperature, 0)
	for rows.Next() {
		var row domain.NetworkTemperature
		if err := rows.Scan(
			&row.ID,
			&row.HeatNetworkID,
			&row.HeatNetworkName,
			&row.Month,
			&row.Supply,
			&row.Return,
			&row.Ground,
		); err != nil {
			return nil, fmt.Errorf("scan monthly temperatures: %w", err)
		}

		result = append(result, row)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate monthly temperatures: %w", err)
	}

	return result, nil
}

func (r *Repository) Upsert(
	ctx context.Context,
	heatNetworkID int64,
	month time.Time,
	values domain.Values,
) (domain.NetworkTemperature, error) {
	const query = `
		WITH target_network AS (
			SELECT id, name
			FROM public."HeatNetwork"
			WHERE id = $1
		),
		upserted AS (
		INSERT INTO public.temperatures (
			heat_network_id,
			month,
			supply_t,
			return_t,
			ground_t
		)
		SELECT
			hn.id,
			$2::date,
			$3,
			$4,
			$5
		FROM target_network AS hn
		ON CONFLICT (heat_network_id, month)
		DO UPDATE SET
			supply_t = EXCLUDED.supply_t,
			return_t = EXCLUDED.return_t,
			ground_t = EXCLUDED.ground_t
		RETURNING
			id,
			heat_network_id,
			month,
			supply_t::double precision,
			return_t::double precision,
			ground_t::double precision
		)
		SELECT
			u.id,
			u.heat_network_id,
			tn.name,
			u.month,
			u.supply_t,
			u.return_t,
			u.ground_t
		FROM upserted AS u
		JOIN target_network AS tn ON tn.id = u.heat_network_id
	`

	row := domain.NetworkTemperature{
		HeatNetworkID: heatNetworkID,
	}

	err := r.pool.QueryRow(
		ctx,
		query,
		heatNetworkID,
		month,
		values.Supply,
		values.Return,
		values.Ground,
	).Scan(
		&row.ID,
		&row.HeatNetworkID,
		&row.HeatNetworkName,
		&row.Month,
		&row.Supply,
		&row.Return,
		&row.Ground,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.NetworkTemperature{}, fmt.Errorf(
			"%w: id=%d",
			domain.ErrHeatNetworkNotFound,
			heatNetworkID,
		)
	}
	if err != nil {
		return domain.NetworkTemperature{}, fmt.Errorf(
			"upsert monthly temperatures: %w",
			err,
		)
	}

	return row, nil
}
