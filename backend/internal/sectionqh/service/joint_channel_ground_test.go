package service

import (
	"math"
	"strings"
	"testing"

	"lostHeat/internal/sectionqh/domain"
)

func TestJointChannelGroundResistance(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name        string
		burialDepth float64
		want        float64
	}{
		{
			name:        "ordinary depth above threshold",
			burialDepth: 1,
			want:        0.1642891008759823,
		},
		{
			name:        "reduced depth at threshold",
			burialDepth: 0.7,
			want:        0.15167294958371372,
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			value, err := calculateJointChannelGroundResistance(jointChannelGroundInput{
				burialDepthM:   number(test.burialDepth),
				heightM:        number(0.45),
				widthM:         number(1.2),
				coverThickness: number(0.09),
				groundLambda:   number(1.8),
			})
			if err != nil {
				t.Fatal(err)
			}
			if math.Abs(value-test.want) > 1e-12 {
				t.Fatalf("Rkgr = %.15f, want %.15f", value, test.want)
			}
		})
	}
}

func TestJointChannelThermalResistanceCalculatedOncePerChannel(t *testing.T) {
	t.Parallel()
	channelOne := int64(10)
	channelTwo := int64(11)
	sections := []domain.NetworkSection{
		jointGroundSection(1, "GVS", channelOne, nil, 0.45, 1.2, 0.09, 1.8),
		jointGroundSection(2, "HEATING", channelOne, number(1), 0.45, 1.2, 0.09, 1.8),
		jointGroundSection(3, "HEATING", channelTwo, number(0.7), 0.45, 1.2, 0.09, 1.8),
		jointGroundSection(4, "GVS", channelTwo, nil, 0.45, 1.2, 0.09, 1.8),
		{ID: 5, HeatNetworkID: 2, NetworkType: "HEATING"},
	}
	values, err := calculateJointChannelThermalResistances(sections)
	if err != nil {
		t.Fatal(err)
	}
	if len(values) != 2 {
		t.Fatalf("calculated %d values, want one for each of 2 channels", len(values))
	}

	wantAirToWall := 1 / (math.Pi * 11 * (2 * 1.2 * 0.45 / (1.2 + 0.45)))
	if math.Abs(values[channelOne].ground-0.1642891008759823) > 1e-12 ||
		math.Abs(values[channelTwo].ground-0.15167294958371372) > 1e-12 {
		t.Fatalf("unexpected Rkgr values: %#v", values)
	}
	for channelID, value := range values {
		if math.Abs(value.airToWall-wantAirToWall) > 1e-12 {
			t.Fatalf("channel %d Rv.k = %.15f, want %.15f", channelID, value.airToWall, wantAirToWall)
		}
		if math.Abs(value.total-(value.ground+value.airToWall)) > 1e-12 {
			t.Fatalf("channel %d Rkan = %.15f, want Rkgr + Rv.k", channelID, value.total)
		}
	}
}

func TestJointChannelAirToWallResistance(t *testing.T) {
	t.Parallel()
	value, err := calculateJointChannelAirToWallResistance(number(1.2), number(0.45))
	if err != nil {
		t.Fatal(err)
	}
	want := 1 / (math.Pi * 11 * (2 * 1.2 * 0.45 / (1.2 + 0.45)))
	if math.Abs(value-want) > 1e-12 {
		t.Fatalf("Rv.k = %.15f, want %.15f", value, want)
	}
}

func TestJointChannelAirToWallResistanceRejectsInvalidDimensions(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name   string
		width  *float64
		height *float64
		field  string
	}{
		{name: "missing width", width: nil, height: number(0.45), field: "width_m"},
		{name: "zero width", width: number(0), height: number(0.45), field: "width_m"},
		{name: "infinite width", width: number(math.Inf(1)), height: number(0.45), field: "width_m"},
		{name: "missing height", width: number(1.2), height: nil, field: "height_m"},
		{name: "negative height", width: number(1.2), height: number(-1), field: "height_m"},
		{name: "NaN height", width: number(1.2), height: number(math.NaN()), field: "height_m"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			_, err := calculateJointChannelAirToWallResistance(test.width, test.height)
			if err == nil || !strings.Contains(err.Error(), test.field) {
				t.Fatalf("error = %v, want field %s", err, test.field)
			}
		})
	}
}

func TestJointChannelGroundResistanceRejectsInvalidInputs(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name   string
		change func(*jointChannelGroundInput)
		field  string
	}{
		{name: "missing burial", change: func(v *jointChannelGroundInput) { v.burialDepthM = nil }, field: "burial_depth_m"},
		{name: "zero burial", change: func(v *jointChannelGroundInput) { v.burialDepthM = number(0) }, field: "burial_depth_m"},
		{name: "missing height", change: func(v *jointChannelGroundInput) { v.heightM = nil }, field: "height_m"},
		{name: "negative height", change: func(v *jointChannelGroundInput) { v.heightM = number(-1) }, field: "height_m"},
		{name: "missing width", change: func(v *jointChannelGroundInput) { v.widthM = nil }, field: "width_m"},
		{name: "zero width", change: func(v *jointChannelGroundInput) { v.widthM = number(0) }, field: "width_m"},
		{name: "missing cover", change: func(v *jointChannelGroundInput) { v.coverThickness = nil }, field: "cover_thickness_m"},
		{name: "infinite cover", change: func(v *jointChannelGroundInput) { v.coverThickness = number(math.Inf(1)) }, field: "cover_thickness_m"},
		{name: "missing lambda", change: func(v *jointChannelGroundInput) { v.groundLambda = nil }, field: "ground_lambda"},
		{name: "NaN lambda", change: func(v *jointChannelGroundInput) { v.groundLambda = number(math.NaN()) }, field: "ground_lambda"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			input := jointChannelGroundInput{
				burialDepthM: number(1), heightM: number(0.45), widthM: number(1.2),
				coverThickness: number(0.09), groundLambda: number(1.8),
			}
			test.change(&input)
			_, err := calculateJointChannelGroundResistance(input)
			if err == nil || !strings.Contains(err.Error(), test.field) {
				t.Fatalf("error = %v, want field %s", err, test.field)
			}
		})
	}
}

func TestJointChannelGroundResistanceRequiresOneHeatingSection(t *testing.T) {
	t.Parallel()
	channelID := int64(5)
	gvs := jointGroundSection(1, "GVS", channelID, number(9), 0.45, 1.2, 0.09, 1.8)
	if _, err := calculateJointChannelThermalResistances([]domain.NetworkSection{gvs}); err == nil || !strings.Contains(err.Error(), "burial_depth_m") {
		t.Fatalf("missing HEATING section error = %v", err)
	}
	heating := jointGroundSection(2, "HEATING", channelID, number(1), 0.45, 1.2, 0.09, 1.8)
	duplicate := heating
	duplicate.ID = 3
	if _, err := calculateJointChannelThermalResistances([]domain.NetworkSection{heating, duplicate}); err == nil || !strings.Contains(err.Error(), "more than one HEATING") {
		t.Fatalf("duplicate HEATING error = %v", err)
	}
}

func jointGroundSection(
	id int64,
	networkType string,
	channelID int64,
	burial *float64,
	height, width, cover, lambda float64,
) domain.NetworkSection {
	return domain.NetworkSection{
		ID: id, HeatNetworkID: 2, NetworkType: networkType,
		JointChannelID: &channelID, BurialDepthM: burial,
		JointChannelHeightM: number(height), JointChannelWidthM: number(width),
		JointChannelCoverThicknessM: number(cover), JointChannelGroundLambda: number(lambda),
	}
}
