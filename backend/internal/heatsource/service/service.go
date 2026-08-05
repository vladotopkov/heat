package service

import (
	"context"

	"lostHeat/internal/heatsource/domain"
)

type Repository interface {
	ListBoilerHouses(
		ctx context.Context,
	) ([]domain.BoilerHouse, error)

	ListNetworkTypes(
		ctx context.Context,
	) ([]domain.NetworkType, error)

	ListInsulationMaterials(
		ctx context.Context,
	) ([]domain.InsulationMaterial, error)

	ListLayingMethods(
		ctx context.Context,
	) ([]domain.LayingMethod, error)

	ListSoilTypes(
		ctx context.Context,
	) ([]domain.SoilType, error)

	ListCalculationOperations(
		ctx context.Context,
	) ([]domain.CalculationOperation, error)
}

type Service struct {
	repository Repository
}

func New(repository Repository) *Service {
	return &Service{
		repository: repository,
	}
}
