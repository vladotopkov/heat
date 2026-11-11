package service

import (
	"math"
	"strings"
	"testing"
)

func TestJointChannelNormalizedPipeResistances(t *testing.T) {
	t.Parallel()
	network := militaryTownNetwork()
	norms := map[int64]jointChannelQHNorms{
		17: {
			q1n: 17.875,
			q2n: 999, // R2_norm must not use q2n.
			q3n: 12.625,
			q4n: 10,
		},
	}

	result, err := calculateJointChannelNormalizedPipeResistances(
		network,
		norms,
		map[int64]float64{17: 13.1},
	)
	if err != nil {
		t.Fatal(err)
	}
	if len(result) != 1 {
		t.Fatalf("calculated %d resistance sets, want 1", len(result))
	}

	resistances := result[17]
	assertClose(t, "R1_norm", resistances.r1, 3.74265734265734)
	assertClose(t, "R2_norm", resistances.r2, 3.74265734265734)
	assertClose(t, "R3_norm", resistances.r3, 3.71485148514851)
	assertClose(t, "R4_norm", resistances.r4, 3.69)
	if resistances.r2 != resistances.r1 {
		t.Fatalf("R2_norm = %g, want R1_norm = %g", resistances.r2, resistances.r1)
	}
}

func TestJointChannelNormalizedPipeResistancesUseHeatNetworkTemperatures(t *testing.T) {
	t.Parallel()
	network := militaryTownNetwork()
	network.ProjectSupplyTemperature = number(75)
	network.GVSProjectSupplyTemperature = number(55)
	network.GVSProjectCirculationTemperature = number(45)

	result, err := calculateJointChannelNormalizedPipeResistances(
		network,
		map[int64]jointChannelQHNorms{17: {q1n: 13, q3n: 9, q4n: 7}},
		map[int64]float64{17: 10},
	)
	if err != nil {
		t.Fatal(err)
	}

	resistances := result[17]
	assertClose(t, "R1_norm", resistances.r1, 5)
	assertClose(t, "R2_norm", resistances.r2, 5)
	assertClose(t, "R3_norm", resistances.r3, 5)
	assertClose(t, "R4_norm", resistances.r4, 5)
}

func TestJointChannelNormalizedPipeResistancesValidateInputs(t *testing.T) {
	t.Parallel()
	validNetwork := militaryTownNetwork()
	validNorms := map[int64]jointChannelQHNorms{
		17: {q1n: 17.875, q3n: 12.625, q4n: 10},
	}
	validTemperatures := map[int64]float64{17: 13.1}

	t.Run("missing project temperature", func(t *testing.T) {
		network := validNetwork
		network.GVSProjectSupplyTemperature = nil
		_, err := calculateJointChannelNormalizedPipeResistances(
			network,
			validNorms,
			validTemperatures,
		)
		assertResistanceError(t, err, "gvs_project_supply_temperature_c")
	})

	t.Run("missing tau_channel", func(t *testing.T) {
		_, err := calculateJointChannelNormalizedPipeResistances(
			validNetwork,
			validNorms,
			map[int64]float64{},
		)
		assertResistanceError(t, err, "no calculated tau_channel")
	})

	t.Run("invalid tau_channel", func(t *testing.T) {
		_, err := calculateJointChannelNormalizedPipeResistances(
			validNetwork,
			validNorms,
			map[int64]float64{17: math.NaN()},
		)
		assertResistanceError(t, err, "tau_channel")
	})

	for _, test := range []struct {
		name  string
		norms jointChannelQHNorms
		want  string
	}{
		{name: "zero q1n", norms: jointChannelQHNorms{q1n: 0, q3n: 12.625, q4n: 10}, want: "q1n"},
		{name: "NaN q3n", norms: jointChannelQHNorms{q1n: 17.875, q3n: math.NaN(), q4n: 10}, want: "q3n"},
		{name: "negative q4n", norms: jointChannelQHNorms{q1n: 17.875, q3n: 12.625, q4n: -1}, want: "q4n"},
	} {
		t.Run(test.name, func(t *testing.T) {
			_, err := calculateJointChannelNormalizedPipeResistances(
				validNetwork,
				map[int64]jointChannelQHNorms{17: test.norms},
				validTemperatures,
			)
			assertResistanceError(t, err, test.want)
		})
	}

	t.Run("non-positive result", func(t *testing.T) {
		_, err := calculateJointChannelNormalizedPipeResistances(
			validNetwork,
			validNorms,
			map[int64]float64{17: 80},
		)
		assertResistanceError(t, err, "calculated R")
	})

	t.Run("tau_channel without q norms", func(t *testing.T) {
		_, err := calculateJointChannelNormalizedPipeResistances(
			validNetwork,
			map[int64]jointChannelQHNorms{},
			validTemperatures,
		)
		assertResistanceError(t, err, "no calculated q1n, q3n and q4n")
	})
}

func assertResistanceError(t *testing.T, err error, expected string) {
	t.Helper()
	if err == nil || !strings.Contains(err.Error(), expected) {
		t.Fatalf("error = %v, want %q", err, expected)
	}
}
