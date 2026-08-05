package postgres

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (r *Repository) ListNetworkTypes(
	ctx context.Context,
) ([]domain.NetworkType, error) {
	const query = `
		SELECT
			id::TEXT,
			code,
			name,
			COALESCE(description, ''),
			is_active
		FROM network_types
		ORDER BY name
	`

	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf(
			"query network types: %w",
			err,
		)
	}
	defer rows.Close()

	networkTypes := make([]domain.NetworkType, 0)

	for rows.Next() {
		var networkType domain.NetworkType

		if err := rows.Scan(
			&networkType.ID,
			&networkType.Code,
			&networkType.Name,
			&networkType.Description,
			&networkType.IsActive,
		); err != nil {
			return nil, fmt.Errorf(
				"scan network type: %w",
				err,
			)
		}

		networkTypes = append(
			networkTypes,
			networkType,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate network types: %w",
			err,
		)
	}

	return networkTypes, nil
}
