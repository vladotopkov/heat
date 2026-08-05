package service

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (service *Service) ListCalculationOperations(
	ctx context.Context,
) ([]domain.CalculationOperation, error) {
	calculationOperations, err :=
		service.repository.ListCalculationOperations(ctx)

	if err != nil {
		return nil, fmt.Errorf(
			"list calculation operations: %w",
			err,
		)
	}

	return calculationOperations, nil
}
