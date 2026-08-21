package ports

import (
	"context"

	"lostHeat/internal/qh/domain"
)

type TableDimensionRepository interface {
	GetByTableID(
		ctx context.Context,
		tableID int64,
	) ([]domain.QHTableDimensionConfig, error)
}