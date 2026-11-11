package service

import (
	"math"
	"strings"
	"testing"

	"lostHeat/internal/sectionqh/domain"
)

func TestJointChannelAirTemperatureFormula66(t *testing.T) {
	t.Parallel()
	network := militaryTownNetwork()
	network.ProjectGroundTemperature = number(5)

	result, err := calculateJointChannelAirTemperatures(
		network,
		map[int64]jointChannelQHNorms{
			17: {
				q1n: 17.875,
				q2n: 999, // Formula 6.6 must use q2n=0 per 6.2.1.5.
				q3n: 12.625,
				q4n: 10,
			},
		},
		map[int64]jointChannelThermalResistance{
			17: {ground: 0.15, airToWall: 0.05, total: 0.2},
		},
	)
	if err != nil {
		t.Fatal(err)
	}
	if len(result) != 1 {
		t.Fatalf("calculated %d temperatures, want 1", len(result))
	}
	if math.Abs(result[17]-13.1) > 1e-12 {
		t.Fatalf("tau_channel = %.15f, want 13.1", result[17])
	}
}

func TestJointChannelAirTemperatureRequiresInputs(t *testing.T) {
	t.Parallel()
	validNetwork := militaryTownNetwork()
	validNetwork.ProjectGroundTemperature = number(5)
	validNorms := map[int64]jointChannelQHNorms{
		17: {q1n: 17.875, q3n: 12.625, q4n: 10},
	}
	validResistances := map[int64]jointChannelThermalResistance{
		17: {total: 0.2},
	}

	tests := []struct {
		name        string
		network     func() domain.HeatNetwork
		norms       map[int64]jointChannelQHNorms
		resistances map[int64]jointChannelThermalResistance
		want        string
	}{
		{
			name: "missing ground temperature",
			network: func() domain.HeatNetwork {
				network := validNetwork
				network.ProjectGroundTemperature = nil
				return network
			},
			norms: validNorms, resistances: validResistances,
			want: "project_ground_temperature_c",
		},
		{
			name:    "missing Rkan",
			network: func() domain.HeatNetwork { return validNetwork },
			norms:   validNorms, resistances: map[int64]jointChannelThermalResistance{},
			want: "no calculated Rkan",
		},
		{
			name:    "missing q norms",
			network: func() domain.HeatNetwork { return validNetwork },
			norms:   map[int64]jointChannelQHNorms{}, resistances: validResistances,
			want: "no calculated q1n, q3n and q4n",
		},
		{
			name:    "invalid q3n",
			network: func() domain.HeatNetwork { return validNetwork },
			norms: map[int64]jointChannelQHNorms{
				17: {q1n: 17.875, q3n: math.NaN(), q4n: 10},
			},
			resistances: validResistances,
			want:        "q3n",
		},
		{
			name:    "invalid Rkan",
			network: func() domain.HeatNetwork { return validNetwork },
			norms:   validNorms,
			resistances: map[int64]jointChannelThermalResistance{
				17: {total: 0},
			},
			want: "Rkan",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			_, err := calculateJointChannelAirTemperatures(
				test.network(),
				test.norms,
				test.resistances,
			)
			if err == nil || !strings.Contains(err.Error(), test.want) {
				t.Fatalf("error = %v, want %q", err, test.want)
			}
		})
	}
}
