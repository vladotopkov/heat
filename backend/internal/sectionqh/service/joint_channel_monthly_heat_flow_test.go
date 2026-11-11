package service

import (
	"context"
	"math"
	"strings"
	"testing"
	"time"

	"lostHeat/internal/sectionqh/domain"
)

func TestJointChannelMonthlyNormalizedHeatFlows(t *testing.T) {
	t.Parallel()
	stub := &repositoryStub{monthlyTemperatures: []domain.MonthlyTemperature{
		monthlyTemperature(2, 2026, time.October, "HEATING", 72, 52, 6),
		monthlyTemperature(2, 2026, time.October, "GVS", 61, 51, 6),
	}}

	result, err := New(stub).calculateJointChannelMonthlyNormalizedHeatFlows(
		context.Background(),
		2,
		time.Date(2026, time.October, 28, 0, 0, 0, 0, time.UTC),
		jointB15Sections(57, 57, 57, 57),
		map[int64]jointChannelNormalizedPipeResistances{
			17: {r1: 1, r2: 1, r3: 1, r4: 1},
		},
		map[int64]jointChannelThermalResistance{
			17: {total: 1},
		},
	)
	if err != nil {
		t.Fatal(err)
	}
	flows := result[17]
	assertClose(t, "q1_norm_period", flows.q1, 23.6)
	assertClose(t, "q2_norm_period", flows.q2, 3.6)
	assertClose(t, "q3_norm_period", flows.q3, 12.6)
	assertClose(t, "q4_norm_period", flows.q4, 2.6)
	if stub.requestedMonth.Format("2006-01-02") != "2026-10-01" {
		t.Fatalf("requested month = %s", stub.requestedMonth.Format("2006-01-02"))
	}
}

func TestMonthlyNormalizedHeatFlowFormula613(t *testing.T) {
	t.Parallel()
	result, err := calculateJointChannelMonthlyNormalizedHeatFlowValues(
		map[int64]struct{}{17: {}},
		jointChannelMonthlyTemperatures{
			t1Avg: 70,
			t2Avg: 50,
			t3Avg: 60,
			t4Avg: 50,
		},
		map[int64]float64{17: 10},
		map[int64]jointChannelNormalizedPipeResistances{
			17: {r1: 2, r2: 4, r3: 5, r4: 8},
		},
	)
	if err != nil {
		t.Fatal(err)
	}
	flows := result[17]
	assertClose(t, "q1_norm_period", flows.q1, 30)
	assertClose(t, "q2_norm_period", flows.q2, 10)
	assertClose(t, "q3_norm_period", flows.q3, 10)
	assertClose(t, "q4_norm_period", flows.q4, 5)
}

func TestMonthlyNormalizedHeatFlowValidatesPreviousResults(t *testing.T) {
	t.Parallel()
	channelIDs := map[int64]struct{}{17: {}}
	temperatures := jointChannelMonthlyTemperatures{
		t1Avg: 70, t2Avg: 50, t3Avg: 60, t4Avg: 50,
	}
	resistances := map[int64]jointChannelNormalizedPipeResistances{
		17: {r1: 2, r2: 4, r3: 5, r4: 8},
	}

	_, err := calculateJointChannelMonthlyNormalizedHeatFlowValues(
		channelIDs,
		temperatures,
		map[int64]float64{},
		resistances,
	)
	if err == nil || !strings.Contains(err.Error(), "no calculated tau_channel_period") {
		t.Fatalf("missing tau error = %v", err)
	}

	_, err = calculateJointChannelMonthlyNormalizedHeatFlowValues(
		channelIDs,
		temperatures,
		map[int64]float64{17: math.NaN()},
		resistances,
	)
	if err == nil || !strings.Contains(err.Error(), "tau_channel_period") {
		t.Fatalf("invalid tau error = %v", err)
	}

	invalidResistances := map[int64]jointChannelNormalizedPipeResistances{
		17: {r1: 2, r2: 4, r3: 0, r4: 8},
	}
	_, err = calculateJointChannelMonthlyNormalizedHeatFlowValues(
		channelIDs,
		temperatures,
		map[int64]float64{17: 10},
		invalidResistances,
	)
	if err == nil || !strings.Contains(err.Error(), "R3_norm") {
		t.Fatalf("invalid resistance error = %v", err)
	}
}
