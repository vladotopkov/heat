package calculationhttp

import (
	"context"
	"log/slog"

	"lostHeat/internal/calculation/domain"
	"lostHeat/internal/calculation/service"
)

type Service interface {
	Calculate(
		ctx context.Context,
		requestData service.CalculationRequestData,
	) (domain.CalculationResult, error)
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