package service

import (
	"context"

	"lostHeat/internal/calculation/calculators"
	"lostHeat/internal/calculation/domain"
)

type Repository interface {
	LoadReferences(
		ctx context.Context,
		ids domain.CalculationReferenceIDs,
	) (domain.CalculationReferences, error)
}
type Service struct {
	repository        Repository
	calculatorCatalog *calculators.CalculatorCatalog
}

func New(
	repository Repository,
	calculatorCatalog *calculators.CalculatorCatalog,
) *Service {
	return &Service{
		repository:        repository,
		calculatorCatalog: calculatorCatalog,
	}
}