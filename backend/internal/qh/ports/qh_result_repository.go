package ports

import (
	"context"

	"lostHeat/internal/qh/domain"
)

type QHResultRepository interface {
	ReplaceForSession(
		ctx context.Context,
		sessionID int64,
		results []domain.QHResult,
	) ([]domain.QHResult, error)

	GetBySessionID(
		ctx context.Context,
		sessionID int64,
	) ([]domain.QHResult, error)
}