package ports

import (
	"context"

	"lostHeat/internal/qh/domain"
)

type QHTableRepository interface {
	GetByID(
		ctx context.Context,
		tableID int64,
	) (*domain.QHTable, error)
}