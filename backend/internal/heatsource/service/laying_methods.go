package service

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (service *Service) ListLayingMethods(
	ctx context.Context,
) ([]domain.LayingMethod, error) {
	layingMethods, err :=
		service.repository.ListLayingMethods(ctx)

	if err != nil {
		return nil, fmt.Errorf(
			"list laying methods: %w",
			err,
		)
	}

	return layingMethods, nil
}
