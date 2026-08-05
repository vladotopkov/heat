package service

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (service *Service) ListSoilTypes(
	ctx context.Context,
) ([]domain.SoilType, error) {
	soilTypes, err := service.repository.ListSoilTypes(ctx)

	if err != nil {
		return nil, fmt.Errorf(
			"list soil types: %w",
			err,
		)
	}

	return soilTypes, nil
}
