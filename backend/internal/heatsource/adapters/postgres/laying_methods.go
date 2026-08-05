package postgres

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (r *Repository) ListLayingMethods(
	ctx context.Context,
) ([]domain.LayingMethod, error) {
	const query = `
		SELECT
			id::TEXT,
			code,
			name,
			COALESCE(description, '')
		FROM laying_methods
		ORDER BY name
	`

	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf(
			"query laying methods: %w",
			err,
		)
	}
	defer rows.Close()

	layingMethods := make([]domain.LayingMethod, 0)

	for rows.Next() {
		var layingMethod domain.LayingMethod

		if err := rows.Scan(
			&layingMethod.ID,
			&layingMethod.Code,
			&layingMethod.Name,
			&layingMethod.Description,
		); err != nil {
			return nil, fmt.Errorf(
				"scan laying method: %w",
				err,
			)
		}

		layingMethods = append(
			layingMethods,
			layingMethod,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate laying methods: %w",
			err,
		)
	}

	return layingMethods, nil
}
