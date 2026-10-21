package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/monthlyuptime/domain"
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
) ([]domain.NetworkUptime, error) {
	const query = `
		SELECT
			u.id,
			hn.id,
			hn.name,
			$1::date,
			u.hours_per_month
		FROM public."HeatNetwork" AS hn
		LEFT JOIN public.up_time AS u
			ON u.heat_network_id = hn.id
			AND u.month = $1::date
		ORDER BY hn.name, hn.id
	`

	rows, err := r.pool.Query(ctx, query, month)
	if err != nil {
		return nil, fmt.Errorf("list monthly uptime: %w", err)
	}
	defer rows.Close()

	result := make([]domain.NetworkUptime, 0)
	for rows.Next() {
		var row domain.NetworkUptime
		if err := rows.Scan(
			&row.ID,
			&row.HeatNetworkID,
			&row.HeatNetworkName,
			&row.Month,
			&row.HoursPerMonth,
		); err != nil {
			return nil, fmt.Errorf("scan monthly uptime: %w", err)
		}

		result = append(result, row)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate monthly uptime: %w", err)
	}

	return result, nil
}

func (r *Repository) Upsert(
	ctx context.Context,
	heatNetworkID int64,
	month time.Time,
	hoursPerMonth int,
) (domain.NetworkUptime, error) {
	const query = `
		WITH target_network AS (
			SELECT id, name
			FROM public."HeatNetwork"
			WHERE id = $1
		),
		upserted AS (
			INSERT INTO public.up_time (
				heat_network_id,
				month,
				hours_per_month
			)
			SELECT
				hn.id,
				$2::date,
				$3
			FROM target_network AS hn
			ON CONFLICT (heat_network_id, month)
			DO UPDATE SET
				hours_per_month = EXCLUDED.hours_per_month
			RETURNING
				id,
				heat_network_id,
				month,
				hours_per_month
		)
		SELECT
			u.id,
			u.heat_network_id,
			tn.name,
			u.month,
			u.hours_per_month
		FROM upserted AS u
		JOIN target_network AS tn ON tn.id = u.heat_network_id
	`

	row := domain.NetworkUptime{HeatNetworkID: heatNetworkID}
	err := r.pool.QueryRow(
		ctx,
		query,
		heatNetworkID,
		month,
		hoursPerMonth,
	).Scan(
		&row.ID,
		&row.HeatNetworkID,
		&row.HeatNetworkName,
		&row.Month,
		&row.HoursPerMonth,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.NetworkUptime{}, fmt.Errorf(
			"%w: id=%d",
			domain.ErrHeatNetworkNotFound,
			heatNetworkID,
		)
	}
	if err != nil {
		return domain.NetworkUptime{}, fmt.Errorf(
			"upsert monthly uptime: %w",
			err,
		)
	}

	return row, nil
}
