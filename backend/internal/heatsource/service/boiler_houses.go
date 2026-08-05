package service

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (service *Service) ListBoilerHouses(
	ctx context.Context,
) ([]domain.BoilerHouse, error) {
	boilerHouses, err :=
		service.repository.ListBoilerHouses(ctx)

	if err != nil {
		return nil, fmt.Errorf(
			"list boiler houses: %w",
			err,
		)
	}

	return boilerHouses, nil
}
