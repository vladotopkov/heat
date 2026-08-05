package postgres

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (r *Repository) ListBoilerHouses(
	ctx context.Context,
) ([]domain.BoilerHouse, error) {
	const query = `
		SELECT
			id::TEXT,
			code,
			name,
			city,
			address
		FROM boiler_houses
		ORDER BY name
	`

	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf(
			"query active boiler houses: %w",
			err,
		)
	}
	defer rows.Close()

	boilerHouses := make([]domain.BoilerHouse, 0)

	for rows.Next() {
		var boilerHouse domain.BoilerHouse

		if err := rows.Scan(
			&boilerHouse.ID,
			&boilerHouse.Code,
			&boilerHouse.Name,
			&boilerHouse.City,
			&boilerHouse.Address,
		); err != nil {
			return nil, fmt.Errorf(
				"scan boiler house: %w",
				err,
			)
		}

		boilerHouses = append(
			boilerHouses,
			boilerHouse,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate boiler houses: %w",
			err,
		)
	}

	return boilerHouses, nil
}
