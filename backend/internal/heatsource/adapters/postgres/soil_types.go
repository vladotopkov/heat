package postgres

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (r *Repository) ListSoilTypes(
	ctx context.Context,
) ([]domain.SoilType, error) {
	const query = `
		SELECT
			id::TEXT,
			code,
			name,
			COALESCE(description, '')
		FROM soil_types
		ORDER BY name
	`

	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf(
			"query soil types: %w",
			err,
		)
	}
	defer rows.Close()

	soilTypes := make([]domain.SoilType, 0)

	for rows.Next() {
		var soilType domain.SoilType

		if err := rows.Scan(
			&soilType.ID,
			&soilType.Code,
			&soilType.Name,
			&soilType.Description,
		); err != nil {
			return nil, fmt.Errorf(
				"scan soil type: %w",
				err,
			)
		}

		soilTypes = append(
			soilTypes,
			soilType,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate soil types: %w",
			err,
		)
	}

	return soilTypes, nil
}
