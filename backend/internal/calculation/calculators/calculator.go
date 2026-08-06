package calculators

import "lostHeat/internal/calculation/domain"

type Calculator interface {
	Calculate(
		input domain.CalculationInput,
	) (domain.CalculationResult, error)
}