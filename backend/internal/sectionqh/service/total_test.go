package service

import (
	"context"
	"math"
	"testing"

	"lostHeat/internal/sectionqh/domain"
)

func TestTotalNormalizedHeatLossPerHour(t *testing.T) {
	t.Parallel()

	length := 100.0
	beta := 1.15
	diameter := 57.0
	stub := &repositoryStub{
		network: eremichiNetwork(95, 50),
		sections: []domain.NetworkSection{{
			ID:                  4,
			HeatNetworkID:       1,
			QHTableID:           7,
			LengthM:             &length,
			Beta:                &beta,
			SupplyOuterDiameter: &diameter,
		}},
		valuesByTable: map[int64][]domain.QHValue{
			7: {{
				ID:              2,
				QHTableID:       7,
				OuterDiameterMM: &diameter,
				Value:           30,
			}},
		},
	}

	total, unavailableReason, err := New(stub).
		TotalNormalizedHeatLossPerHour(context.Background(), 1)
	if err != nil {
		t.Fatalf("TotalNormalizedHeatLossPerHour() error = %v", err)
	}
	if unavailableReason != nil {
		t.Fatalf("unavailableReason = %q, want nil", *unavailableReason)
	}

	const expected = 12420.0
	if math.Abs(total-expected) > 1e-9 {
		t.Errorf("total = %f, want %f", total, expected)
	}
}

func TestTotalNormalizedHeatLossPerHourReportsMissingLength(t *testing.T) {
	t.Parallel()

	beta := 1.0
	diameter := 57.0
	stub := &repositoryStub{
		network: eremichiNetwork(95, 50),
		sections: []domain.NetworkSection{{
			ID:                  4,
			HeatNetworkID:       1,
			QHTableID:           7,
			Beta:                &beta,
			SupplyOuterDiameter: &diameter,
		}},
		valuesByTable: map[int64][]domain.QHValue{
			7: {{
				ID:              2,
				QHTableID:       7,
				OuterDiameterMM: &diameter,
				Value:           30,
			}},
		},
	}

	_, unavailableReason, err := New(stub).
		TotalNormalizedHeatLossPerHour(context.Background(), 1)
	if err != nil {
		t.Fatalf("TotalNormalizedHeatLossPerHour() error = %v", err)
	}
	if unavailableReason == nil {
		t.Fatal("unavailableReason = nil, want missing length reason")
	}
}
