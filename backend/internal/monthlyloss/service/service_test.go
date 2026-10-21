package service

import (
	"context"
	"math"
	"testing"
	"time"

	"lostHeat/internal/monthlyloss/domain"
)

type repositoryStub struct {
	inputs []domain.CalculationInput
}

func (stub *repositoryStub) ListInputsForMonth(
	_ context.Context,
	_ time.Time,
) ([]domain.CalculationInput, error) {
	return stub.inputs, nil
}

type normalizedHeatLossProviderStub struct {
	total             float64
	unavailableReason *string
	requests          int
}

func (stub *normalizedHeatLossProviderStub) TotalNormalizedHeatLossPerHour(
	_ context.Context,
	_ int64,
) (float64, *string, error) {
	stub.requests++
	return stub.total, stub.unavailableReason, nil
}

func TestListForMonthCalculatesLossByFormula(t *testing.T) {
	t.Parallel()

	month := time.Date(2026, time.August, 1, 0, 0, 0, 0, time.UTC)
	repository := &repositoryStub{inputs: []domain.CalculationInput{{
		HeatNetworkID:   1,
		HeatNetworkName: "Еремичи",
		Month:           month,
		ProjectSupply:   floatPointer(95),
		ProjectReturn:   floatPointer(70),
		ProjectGround:   floatPointer(9.6),
		ActualSupply:    floatPointer(80),
		ActualReturn:    floatPointer(60),
		ActualGround:    floatPointer(10),
		Hours:           intPointer(720),
	}}}
	provider := &normalizedHeatLossProviderStub{total: 1000}

	rows, err := New(repository, provider).ListForMonth(
		context.Background(),
		month,
	)
	if err != nil {
		t.Fatalf("ListForMonth() error = %v", err)
	}
	if len(rows) != 1 {
		t.Fatalf("len(rows) = %d, want 1", len(rows))
	}
	if rows[0].LossGJ == nil {
		t.Fatalf("LossGJ = nil, error = %v", rows[0].CalculationError)
	}

	const expected = 0.5925925925925926
	if math.Abs(*rows[0].LossGJ-expected) > 1e-12 {
		t.Errorf("LossGJ = %.15f, want %.15f", *rows[0].LossGJ, expected)
	}
	if rows[0].TotalNormalizedHeatLossPerHour == nil ||
		*rows[0].TotalNormalizedHeatLossPerHour != 1000 {
		t.Errorf(
			"TotalNormalizedHeatLossPerHour = %v, want 1000",
			rows[0].TotalNormalizedHeatLossPerHour,
		)
	}
}

func TestListForMonthKeepsNetworkWithMissingTemperatures(t *testing.T) {
	t.Parallel()

	month := time.Date(2026, time.August, 1, 0, 0, 0, 0, time.UTC)
	repository := &repositoryStub{inputs: []domain.CalculationInput{{
		HeatNetworkID:   2,
		HeatNetworkName: "Без показаний",
		Month:           month,
	}}}
	provider := &normalizedHeatLossProviderStub{total: 1000}

	rows, err := New(repository, provider).ListForMonth(
		context.Background(),
		month,
	)
	if err != nil {
		t.Fatalf("ListForMonth() error = %v", err)
	}
	if len(rows) != 1 || rows[0].CalculationError == nil {
		t.Fatalf("rows = %#v, want a row with calculation error", rows)
	}
	if rows[0].LossGJ != nil {
		t.Errorf("LossGJ = %v, want nil", rows[0].LossGJ)
	}
	if provider.requests != 0 {
		t.Errorf("normalized heat loss requests = %d, want 0", provider.requests)
	}
}

func intPointer(value int) *int {
	return &value
}
