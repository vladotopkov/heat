package calculators

import (
	"errors"
	"fmt"
)

var ErrCalculatorNotFound = errors.New(
	"calculator not found",
)

// CalculatorCatalog хранит соответствие:
//
//	код операции → алгоритм расчёта
type CalculatorCatalog struct {
	calculators map[string]Calculator
}

func NewCalculatorCatalog() *CalculatorCatalog {
	return &CalculatorCatalog{
		calculators: make(map[string]Calculator),
	}
}

func (c *CalculatorCatalog) MustRegister(
	operationCode string,
	calculator Calculator,
) {
	if operationCode == "" {
		panic("operation code must not be empty")
	}

	if calculator == nil {
		panic("calculator must not be nil")
	}

	if _, exists := c.calculators[operationCode]; exists {
		panic(
			fmt.Sprintf(
				"calculator already registered for operation %q",
				operationCode,
			),
		)
	}

	c.calculators[operationCode] = calculator
}

func (c *CalculatorCatalog) Get(
	operationCode string,
) (Calculator, error) {
	calculator, exists := c.calculators[operationCode]
	if !exists {
		return nil, fmt.Errorf(
			"%w: operation code %q",
			ErrCalculatorNotFound,
			operationCode,
		)
	}

	return calculator, nil
}