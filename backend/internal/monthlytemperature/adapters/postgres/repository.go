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
	pool interface {
		Query(context.Context, string, ...any) (pgx.Rows, error)
		QueryRow(context.Context, string, ...any) pgx.Row
	}
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
			t.ground_t::double precision,
			gvs.supply_t::double precision,
			gvs.return_t::double precision
		FROM public."HeatNetwork" AS hn
		LEFT JOIN public.temperatures AS t
			ON t.heat_network_id = hn.id
			AND t.month = $1::date
			AND t.network_type = 'HEATING'
		LEFT JOIN public.temperatures AS gvs
			ON hn.id = 2 AND gvs.heat_network_id = hn.id
			AND gvs.month = $1::date
			AND gvs.network_type = 'GVS'
		ORDER BY hn.id
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
			&row.GVSSupply,
			&row.GVSReturn,
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
			ground_t,
			network_type
		)
		SELECT
			hn.id,
			$2::date,
			v.supply_t,
			v.return_t,
			$5,
			v.network_type
		FROM target_network AS hn
		CROSS JOIN (VALUES
			('HEATING', $3::numeric, $4::numeric),
			('GVS', $6::numeric, $7::numeric)
		) AS v(network_type, supply_t, return_t)
		WHERE v.network_type = 'HEATING'
			OR (hn.id = 2 AND v.supply_t IS NOT NULL AND v.return_t IS NOT NULL)
		ON CONFLICT (heat_network_id, month, network_type)
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
			ground_t::double precision,
			network_type
		)
		SELECT
			u.id,
			u.heat_network_id,
			tn.name,
			u.month,
			u.supply_t,
			u.return_t,
			u.ground_t,
			COALESCE(gvs.supply_t, existing_gvs.supply_t)::double precision,
			COALESCE(gvs.return_t, existing_gvs.return_t)::double precision
		FROM upserted AS u
		JOIN target_network AS tn ON tn.id = u.heat_network_id
		LEFT JOIN upserted AS gvs
			ON gvs.heat_network_id = u.heat_network_id AND gvs.network_type = 'GVS'
		LEFT JOIN public.temperatures AS existing_gvs
			ON u.heat_network_id = 2 AND existing_gvs.heat_network_id = u.heat_network_id
			AND existing_gvs.month = u.month AND existing_gvs.network_type = 'GVS'
		WHERE u.network_type = 'HEATING'
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
		values.GVSSupply,
		values.GVSReturn,
	).Scan(
		&row.ID,
		&row.HeatNetworkID,
		&row.HeatNetworkName,
		&row.Month,
		&row.Supply,
		&row.Return,
		&row.Ground,
		&row.GVSSupply,
		&row.GVSReturn,
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
