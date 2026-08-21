package ports

import (
	"context"

	"lostHeat/internal/qh/domain"
)

type QHValueRepository interface {
	GetByRowID(
		ctx context.Context,
		rowID int64,
	) ([]domain.QHValue, error)
}