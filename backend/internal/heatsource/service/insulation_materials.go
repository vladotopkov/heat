package service

import (
	"context"
	"fmt"

	"lostHeat/internal/heatsource/domain"
)

func (service *Service) ListInsulationMaterials(
	ctx context.Context,
) ([]domain.InsulationMaterial, error) {
	insulationMaterials, err :=
		service.repository.ListInsulationMaterials(ctx)

	if err != nil {
		return nil, fmt.Errorf(
			"list insulation materials: %w",
			err,
		)
	}

	return insulationMaterials, nil
}
