package postgres

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (r *Repository) ListCalculationOperations(
	ctx context.Context,
) ([]domain.CalculationOperation, error) {
	const query = `
		SELECT
			id::TEXT,
			name
		FROM calculation_operations
		ORDER BY name
	`

	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf(
			"query calculation operations: %w",
			err,
		)
	}
	defer rows.Close()

	calculationOperations := make(
		[]domain.CalculationOperation,
		0,
	)

	for rows.Next() {
		var calculationOperation domain.CalculationOperation

		if err := rows.Scan(
			&calculationOperation.ID,
			&calculationOperation.Name,
		); err != nil {
			return nil, fmt.Errorf(
				"scan calculation operation: %w",
				err,
			)
		}

		calculationOperations = append(
			calculationOperations,
			calculationOperation,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate calculation operations: %w",
			err,
		)
	}

	return calculationOperations, nil
}
