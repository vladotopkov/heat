package ports

import (
	"context"

	"lostHeat/internal/qh/domain"
)

type SelectionRuleRepository interface {
	GetActive(
		ctx context.Context,
	) ([]domain.QHSelectionRule, error)
}