package ports

import (
	"context"

	"lostHeat/internal/qh/domain"
)

type QuestionRepository interface {
	GetByCode(
		ctx context.Context,
		code string,
	) (*domain.Question, error)

	GetActiveByPhase(
		ctx context.Context,
		phase domain.QuestionPhase,
	) ([]domain.Question, error)

	GetStaticOptions(
		ctx context.Context,
		questionCode string,
	) ([]domain.QuestionOption, error)
}