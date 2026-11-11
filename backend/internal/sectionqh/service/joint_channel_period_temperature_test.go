package service

import (
	"context"
	"strings"
	"testing"
	"time"

	"lostHeat/internal/sectionqh/domain"
)

func TestJointChannelMonthlyAirTemperaturesFormula611(t *testing.T) {
	t.Parallel()
	month := time.Date(2026, time.October, 19, 0, 0, 0, 0, time.UTC)
	stub := &repositoryStub{monthlyTemperatures: []domain.MonthlyTemperature{
		monthlyTemperature(2, 2026, time.October, "HEATING", 72, 52, 6),
		monthlyTemperature(2, 2026, time.October, "GVS", 61, 51, 6),
	}}
	service := New(stub)

	result, err := service.calculateJointChannelMonthlyAirTemperatures(
		context.Background(),
		2,
		month,
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
	assertClose(t, "tau_channel_period", result[17], 48.4)
	if stub.monthlyNetworkID != 2 ||
		stub.requestedMonth.Format("2006-01-02") != "2026-10-01" {
		t.Fatalf(
			"repository request = network %d, month %s",
			stub.monthlyNetworkID,
			stub.requestedMonth.Format("2006-01-02"),
		)
	}
}

func TestSelectMonthlyTemperaturesUsesOnlySelectedMonth(t *testing.T) {
	t.Parallel()
	month := time.Date(2026, time.October, 1, 0, 0, 0, 0, time.UTC)
	rows := []domain.MonthlyTemperature{
		monthlyTemperature(2, 2026, time.October, "HEATING", 70, 50, 5),
		monthlyTemperature(2, 2026, time.October, "GVS", 60, 50, 5),
	}

	temperatures, err := selectMonthlyTemperatures(2, month, rows)
	if err != nil {
		t.Fatal(err)
	}
	assertClose(t, "t1_avg", temperatures.t1Avg, 70)
	assertClose(t, "t2_avg", temperatures.t2Avg, 50)
	assertClose(t, "t3_avg", temperatures.t3Avg, 60)
	assertClose(t, "t4_avg", temperatures.t4Avg, 50)
	assertClose(t, "ground_avg", temperatures.groundAvg, 5)
}

func TestSelectMonthlyTemperaturesRejectsMissingNetworkType(t *testing.T) {
	t.Parallel()
	month := time.Date(2026, time.October, 1, 0, 0, 0, 0, time.UTC)
	rows := []domain.MonthlyTemperature{
		monthlyTemperature(2, 2026, time.October, "HEATING", 70, 50, 5),
	}

	_, err := selectMonthlyTemperatures(2, month, rows)
	if err == nil || !strings.Contains(err.Error(), "month=2026-10 network_type=GVS") {
		t.Fatalf("error = %v, want missing October GVS", err)
	}
}

func TestSelectMonthlyTemperaturesRejectsDifferentMonth(t *testing.T) {
	t.Parallel()
	month := time.Date(2026, time.October, 1, 0, 0, 0, 0, time.UTC)
	rows := []domain.MonthlyTemperature{
		monthlyTemperature(2, 2026, time.November, "HEATING", 70, 50, 5),
		monthlyTemperature(2, 2026, time.October, "GVS", 60, 50, 5),
	}

	_, err := selectMonthlyTemperatures(2, month, rows)
	if err == nil || !strings.Contains(err.Error(), "month=2026-11 differs from calculation month=2026-10") {
		t.Fatalf("error = %v, want month mismatch", err)
	}
}

func TestSelectMonthlyTemperaturesRejectsGroundMismatch(t *testing.T) {
	t.Parallel()
	month := time.Date(2026, time.October, 1, 0, 0, 0, 0, time.UTC)
	rows := []domain.MonthlyTemperature{
		monthlyTemperature(2, 2026, time.October, "HEATING", 70, 50, 5),
		monthlyTemperature(2, 2026, time.October, "GVS", 60, 50, 6),
	}

	_, err := selectMonthlyTemperatures(2, month, rows)
	if err == nil || !strings.Contains(err.Error(), "ground_t differs for month=2026-10") {
		t.Fatalf("error = %v, want ground mismatch", err)
	}
}

func TestJointChannelMonthlyRequiresSameHeatNetwork(t *testing.T) {
	t.Parallel()
	sections := jointB15Sections(57, 57, 57, 57)
	sections[1].HeatNetworkID = 3
	_, err := jointChannelIDsForHeatNetwork(2, sections)
	if err == nil || !strings.Contains(err.Error(), "heat_network_id=3, want 2") {
		t.Fatalf("error = %v, want heat network mismatch", err)
	}
}

func TestMonthlyFormula611IncludesHeatingReturnTerm(t *testing.T) {
	t.Parallel()
	result, err := calculateJointChannelMonthlyAirTemperatureValues(
		map[int64]struct{}{17: {}},
		jointChannelMonthlyTemperatures{
			t1Avg: 10, t2Avg: 100, t3Avg: 20, t4Avg: 30, groundAvg: 40,
		},
		map[int64]jointChannelNormalizedPipeResistances{
			17: {r1: 1, r2: 1, r3: 1, r4: 1},
		},
		map[int64]jointChannelThermalResistance{17: {total: 1}},
	)
	if err != nil {
		t.Fatal(err)
	}
	assertClose(t, "tau_channel_period", result[17], 40)
}

func monthlyTemperature(
	heatNetworkID int64,
	year int,
	month time.Month,
	networkType string,
	supply float64,
	returnTemperature float64,
	ground float64,
) domain.MonthlyTemperature {
	return domain.MonthlyTemperature{
		HeatNetworkID: heatNetworkID,
		Month:         time.Date(year, month, 1, 0, 0, 0, 0, time.UTC),
		NetworkType:   networkType,
		Supply:        number(supply),
		Return:        number(returnTemperature),
		Ground:        number(ground),
	}
}
