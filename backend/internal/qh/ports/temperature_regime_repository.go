package ports

import (
	"context"

	"lostHeat/internal/qh/domain"
)

type TemperatureRegimeRepository interface {
	GetAll(
		ctx context.Context,
	) ([]domain.TemperatureRegime, error)

	GetByID(
		ctx context.Context,
		id int64,
	) (*domain.TemperatureRegime, error)
}