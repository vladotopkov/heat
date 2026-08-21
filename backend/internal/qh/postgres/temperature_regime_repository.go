package postgres

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/qh/domain"
)

type TemperatureRegimeRepository struct {
	pool *pgxpool.Pool
}

func NewTemperatureRegimeRepository(
	pool *pgxpool.Pool,
) *TemperatureRegimeRepository {

	return &TemperatureRegimeRepository{
		pool: pool,
	}
}

func (r *TemperatureRegimeRepository) GetAll(
	ctx context.Context,
) ([]domain.TemperatureRegime, error) {

	const query = `
		SELECT
			id,
			project_supply_temperature_c::double precision,
			project_return_temperature_c::double precision,
			calculated_supply_temperature_c::double precision

		FROM temperature_regimes

		ORDER BY
			project_supply_temperature_c,
			project_return_temperature_c
	`

	rows, err := r.pool.Query(
		ctx,
		query,
	)

	if err != nil {
		return nil, fmt.Errorf(
			"query temperature regimes: %w",
			err,
		)
	}

	defer rows.Close()

	var result []domain.TemperatureRegime

	for rows.Next() {

		var regime domain.TemperatureRegime

		err := rows.Scan(
			&regime.ID,
			&regime.ProjectSupplyTemperatureC,
			&regime.ProjectReturnTemperatureC,
			&regime.CalculatedSupplyTemperatureC,
		)

		if err != nil {
			return nil, fmt.Errorf(
				"scan temperature regime: %w",
				err,
			)
		}

		result = append(
			result,
			regime,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate temperature regimes: %w",
			err,
		)
	}

	return result, nil
}

func (r *TemperatureRegimeRepository) GetByID(
	ctx context.Context,
	id int64,
) (*domain.TemperatureRegime, error) {

	const query = `
		SELECT
			id,
			project_supply_temperature_c::double precision,
			project_return_temperature_c::double precision,
			calculated_supply_temperature_c::double precision

		FROM temperature_regimes

		WHERE id = $1
	`

	var regime domain.TemperatureRegime

	err := r.pool.QueryRow(
		ctx,
		query,
		id,
	).Scan(
		&regime.ID,
		&regime.ProjectSupplyTemperatureC,
		&regime.ProjectReturnTemperatureC,
		&regime.CalculatedSupplyTemperatureC,
	)

	if err != nil {

		if errors.Is(
			err,
			pgx.ErrNoRows,
		) {
			return nil, fmt.Errorf(
				"temperature regime %d not found",
				id,
			)
		}

		return nil, fmt.Errorf(
			"get temperature regime: %w",
			err,
		)
	}

	return &regime, nil
}