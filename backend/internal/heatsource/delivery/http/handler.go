package heatsourcehttp

import (
	"context"
	"log/slog"

	"lostHeat/internal/heatsource/domain"
)

type Service interface {
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
}

type Handler struct {
	service Service
	logger  *slog.Logger
}

func NewHandler(
	service Service,
	logger *slog.Logger,
) *Handler {
	return &Handler{
		service: service,
		logger:  logger,
	}
}
