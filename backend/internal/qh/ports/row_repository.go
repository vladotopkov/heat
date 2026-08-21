package ports

import (
	"context"

	"lostHeat/internal/qh/domain"
)

type RowRepository interface {
	GetByTableID(
		ctx context.Context,
		tableID int64,
	) ([]domain.QHRow, error)

	GetByID(
		ctx context.Context,
		rowID int64,
	) (*domain.QHRow, error)
}