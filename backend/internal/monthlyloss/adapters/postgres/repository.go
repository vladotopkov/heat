package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/monthlyloss/domain"
)

type Repository struct {
	pool *pgxpool.Pool
}

func New(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) ListInputsForMonth(
	ctx context.Context,
	month time.Time,
) ([]domain.CalculationInput, error) {
	const query = `
		SELECT
			hn.id,
			hn.name,
			$1::date,
			hn.project_supply_temperature_c::double precision,
			hn.project_return_temperature_c::double precision,
			hn.project_ground_temperature_c::double precision,
			t.supply_t::double precision,
			t.return_t::double precision,
			t.ground_t::double precision,
			u.hours_per_month
		FROM public."HeatNetwork" AS hn
		LEFT JOIN public.temperatures AS t
			ON t.heat_network_id = hn.id
			AND t.month = $1::date
			AND t.network_type = 'HEATING'
		LEFT JOIN public.up_time AS u
			ON u.heat_network_id = hn.id
			AND u.month = $1::date
		ORDER BY hn.name, hn.id
	`

	rows, err := r.pool.Query(ctx, query, month)
	if err != nil {
		return nil, fmt.Errorf("list monthly loss inputs: %w", err)
	}
	defer rows.Close()

	result := make([]domain.CalculationInput, 0)
	for rows.Next() {
		var row domain.CalculationInput
		if err := rows.Scan(
			&row.HeatNetworkID,
			&row.HeatNetworkName,
			&row.Month,
			&row.ProjectSupply,
			&row.ProjectReturn,
			&row.ProjectGround,
			&row.ActualSupply,
			&row.ActualReturn,
			&row.ActualGround,
			&row.Hours,
		); err != nil {
			return nil, fmt.Errorf("scan monthly loss input: %w", err)
		}

		result = append(result, row)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate monthly loss inputs: %w", err)
	}

	return result, nil
}
