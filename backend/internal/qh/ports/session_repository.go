package ports

import (
	"context"

	"lostHeat/internal/qh/domain"
)

type SessionRepository interface {
	Create(
		ctx context.Context,
	) (*domain.QuestionnaireSession, error)

	GetByID(
		ctx context.Context,
		sessionID int64,
	) (*domain.QuestionnaireSession, error)

	SelectTable(
		ctx context.Context,
		sessionID int64,
		ruleID int64,
		tableID int64,
	) error

	SelectRow(
		ctx context.Context,
		sessionID int64,
		rowID int64,
	) error

	SetStatus(
		ctx context.Context,
		sessionID int64,
		status domain.QuestionnaireStatus,
	) error
}