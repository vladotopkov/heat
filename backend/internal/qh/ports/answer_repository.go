package ports

import (
	"context"

	"lostHeat/internal/qh/domain"
)

type AnswerRepository interface {
	Save(
		ctx context.Context,
		answer domain.QuestionnaireAnswer,
	) error

	GetBySessionID(
		ctx context.Context,
		sessionID int64,
	) ([]domain.QuestionnaireAnswer, error)
}