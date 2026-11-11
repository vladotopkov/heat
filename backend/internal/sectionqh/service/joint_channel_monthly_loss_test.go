package service

import (
	"math"
	"strings"
	"testing"
)

func TestJointChannelMonthlyNormalizedLossFormula614(t *testing.T) {
	t.Parallel()

	result, err := calculateJointChannelMonthlyNormalizedLosses(
		jointChannelMonthlyNormalizedHeatFlows{q1: 30, q2: 10, q3: 12, q4: 5},
		number(100),
		number(80),
		720,
	)
	if err != nil {
		t.Fatal(err)
	}

	assertClose(t, "Q1_norm_period", result.q1, 7.776)
	assertClose(t, "Q2_norm_period", result.q2, 2.592)
	assertClose(t, "Q3_norm_period", result.q3, 2.48832)
	assertClose(t, "Q4_norm_period", result.q4, 1.0368)
}

func TestJointChannelMonthlyNormalizedLossValidatesInputs(t *testing.T) {
	t.Parallel()
	validFlows := jointChannelMonthlyNormalizedHeatFlows{q1: 1, q2: 1, q3: 1, q4: 1}

	_, err := calculateJointChannelMonthlyNormalizedLosses(
		validFlows,
		nil,
		number(10),
		720,
	)
	if err == nil || !strings.Contains(err.Error(), "HEATING") {
		t.Fatalf("missing heating length error = %v", err)
	}

	_, err = calculateJointChannelMonthlyNormalizedLosses(
		validFlows,
		number(10),
		number(10),
		-1,
	)
	if err == nil || !strings.Contains(err.Error(), "hours_per_month") {
		t.Fatalf("negative uptime error = %v", err)
	}

	invalidFlows := validFlows
	invalidFlows.q4 = math.NaN()
	_, err = calculateJointChannelMonthlyNormalizedLosses(
		invalidFlows,
		number(10),
		number(10),
		720,
	)
	if err == nil || !strings.Contains(err.Error(), "q4_norm_period") {
		t.Fatalf("invalid q error = %v", err)
	}
}
