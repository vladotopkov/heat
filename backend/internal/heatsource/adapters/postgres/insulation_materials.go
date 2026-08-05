package postgres

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (r *Repository) ListInsulationMaterials(
	ctx context.Context,
) ([]domain.InsulationMaterial, error) {
	const query = `
		SELECT
			id::TEXT,
			code,
			name,
			COALESCE(description, '')
		FROM insulation_materials
		ORDER BY name
	`

	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf(
			"query insulation materials: %w",
			err,
		)
	}
	defer rows.Close()

	insulationMaterials := make(
		[]domain.InsulationMaterial,
		0,
	)

	for rows.Next() {
		var insulationMaterial domain.InsulationMaterial

		if err := rows.Scan(
			&insulationMaterial.ID,
			&insulationMaterial.Code,
			&insulationMaterial.Name,
			&insulationMaterial.Description,
		); err != nil {
			return nil, fmt.Errorf(
				"scan insulation material: %w",
				err,
			)
		}

		insulationMaterials = append(
			insulationMaterials,
			insulationMaterial,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate insulation materials: %w",
			err,
		)
	}

	return insulationMaterials, nil
}
