package service

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (service *Service) ListNetworkTypes(
	ctx context.Context,
) ([]domain.NetworkType, error) {
	networkTypes, err :=
		service.repository.ListNetworkTypes(ctx)

	if err != nil {
		return nil, fmt.Errorf(
			"list network types: %w",
			err,
		)
	}

	return networkTypes, nil
}
