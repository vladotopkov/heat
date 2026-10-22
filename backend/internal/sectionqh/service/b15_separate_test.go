package service

import (
	"context"
	"errors"
	"math"
	"reflect"
	"strings"
	"testing"

	"lostHeat/internal/sectionqh/domain"
)

func militaryTownNetwork() domain.HeatNetwork {
	return domain.HeatNetwork{ID: 2, Name: "Военный городок",
		ProjectSupplyTemperature: number(80), ProjectReturnTemperature: number(50),
		GVSProjectSupplyTemperature: number(60), GVSProjectCirculationTemperature: number(50)}
}

func separateSection(networkType string, supplyDiameter, returnDiameter float64) domain.NetworkSection {
	return domain.NetworkSection{ID: 120, HeatNetworkID: 2, NetworkType: networkType,
		QHTableID: 7, QHTableCode: "Б.15",
		SupplyOuterDiameter: number(supplyDiameter), ReturnOuterDiameter: number(returnDiameter),
		SupplyTemperature: number(999), ReturnTemperature: number(999),
		Beta: number(1.2), LengthM: number(100)}
}

func separateValues() []domain.QHValue {
	values := append(b15Values(57, 10, 20.5), b15Values(159, 16.5, 35.1)...)
	for index := range values {
		values[index].ID = int64(index + 1)
	}
	// Separate pipe sums must not use a rounded TWO_PIPE_TOTAL from the table.
	values[2].Value = 999
	values[5].Value = 999
	return values
}

func TestMilitaryTownSeparateB15Calculation(t *testing.T) {
	t.Parallel()
	for _, tc := range []struct {
		name, networkType                                              string
		supplyDiameter, returnDiameter, supply, returnQH, totalPerHour float64
	}{
		{"heating 57", "HEATING", 57, 57, 17.875, 10, 12042},
		{"GVS 57 user example", "GVS", 57, 57, 12.625, 10, 9774},
		{"heating different diameters", "HEATING", 159, 57, 30.45, 10, 17474.4},
		{"GVS different diameters", "GVS", 57, 159, 12.625, 16.5, 12582},
	} {
		t.Run(tc.name, func(t *testing.T) {
			section := separateSection(tc.networkType, tc.supplyDiameter, tc.returnDiameter)
			values := separateValues()
			before := append([]domain.QHValue(nil), values...)
			stub := &repositoryStub{network: militaryTownNetwork(), section: section,
				sections: []domain.NetworkSection{section}, values: values}
			service := New(stub)
			ctx := context.Background()
			match, err := service.GetQHValue(ctx, section.ID)
			if err != nil {
				t.Fatal(err)
			}
			qh := match.QHValue
			if qh.ID != 0 || qh.PipelineRole == nil || *qh.PipelineRole != "TWO_PIPE_TOTAL" ||
				qh.SupplyValue == nil || math.Abs(*qh.SupplyValue-tc.supply) > 1e-9 ||
				qh.ReturnValue == nil || math.Abs(*qh.ReturnValue-tc.returnQH) > 1e-9 ||
				math.Abs(qh.Value-tc.supply-tc.returnQH) > 1e-9 || !qh.SourceInterpolated {
				t.Fatalf("unexpected two-pipe qh: %#v", qh)
			}
			list, err := service.ListNetworkSections(ctx, 2)
			if err != nil {
				t.Fatal(err)
			}
			row := list.Sections[0]
			wantSupply := 80.0
			if tc.networkType == "GVS" {
				wantSupply = 60
			}
			if row.QHValue == nil || row.QHValue.Value != qh.Value ||
				*row.Section.SupplyTemperature != wantSupply || *row.Section.ReturnTemperature != 50 {
				t.Fatalf("list result differs from individual result: %#v", row)
			}
			total, reason, err := service.TotalNormalizedHeatLossPerHour(ctx, 2)
			if err != nil || reason != nil || math.Abs(total-tc.totalPerHour) > 1e-8 {
				t.Fatalf("Qnorm/hour = %g, reason = %v, error = %v; want %g", total, reason, err, tc.totalPerHour)
			}
			if !reflect.DeepEqual(values, before) || !reflect.DeepEqual(stub.section, section) {
				t.Fatal("source table or stored section changed")
			}
		})
	}
}

func TestMilitaryTownUsesChangedNetworkTemperatures(t *testing.T) {
	t.Parallel()
	network := militaryTownNetwork()
	network.ProjectSupplyTemperature, network.GVSProjectSupplyTemperature = number(70), number(65)
	network.GVSProjectCirculationTemperature = number(60)
	for _, tc := range []struct {
		networkType      string
		supply, returnQH float64
	}{
		{"HEATING", 15.25, 10}, {"GVS", 13.9375, 12.625},
	} {
		qh, _, err := selectNetworkSectionValue(network, separateSection(tc.networkType, 57, 57), separateValues())
		if err != nil || qh.SupplyValue == nil || *qh.SupplyValue != tc.supply ||
			qh.ReturnValue == nil || *qh.ReturnValue != tc.returnQH {
			t.Fatalf("%s did not use project regime: %#v, %v", tc.networkType, qh, err)
		}
	}
}

func TestMilitaryTownRejectsIncompleteCalculation(t *testing.T) {
	t.Parallel()
	for _, tc := range []struct {
		name   string
		change func(*domain.HeatNetwork, *domain.NetworkSection, *[]domain.QHValue)
		want   error
	}{
		{"joint channel", func(_ *domain.HeatNetwork, s *domain.NetworkSection, _ *[]domain.QHValue) {
			id := int64(1)
			s.JointChannelID = &id
		}, domain.ErrQHValueNotFound},
		{"unknown type", func(_ *domain.HeatNetwork, s *domain.NetworkSection, _ *[]domain.QHValue) { s.NetworkType = "UNKNOWN" }, domain.ErrQHValueNotFound},
		{"different table", func(_ *domain.HeatNetwork, s *domain.NetworkSection, _ *[]domain.QHValue) { s.QHTableCode = "Б.14" }, domain.ErrQHValueNotFound},
		{"missing GVS supply", func(n *domain.HeatNetwork, _ *domain.NetworkSection, _ *[]domain.QHValue) {
			n.GVSProjectSupplyTemperature = nil
		}, domain.ErrQHValueNotFound},
		{"missing circulation", func(n *domain.HeatNetwork, _ *domain.NetworkSection, _ *[]domain.QHValue) {
			n.GVSProjectCirculationTemperature = nil
		}, domain.ErrQHValueNotFound},
		{"infinite temperature", func(n *domain.HeatNetwork, _ *domain.NetworkSection, _ *[]domain.QHValue) {
			n.GVSProjectSupplyTemperature = number(math.Inf(1))
		}, domain.ErrQHValueNotFound},
		{"missing supply diameter", func(_ *domain.HeatNetwork, s *domain.NetworkSection, _ *[]domain.QHValue) {
			s.SupplyOuterDiameter = nil
		}, domain.ErrQHValueNotFound},
		{"missing return diameter", func(_ *domain.HeatNetwork, s *domain.NetworkSection, _ *[]domain.QHValue) {
			s.ReturnOuterDiameter = nil
		}, domain.ErrQHValueNotFound},
		{"unknown diameter", func(_ *domain.HeatNetwork, s *domain.NetworkSection, _ *[]domain.QHValue) {
			s.ReturnOuterDiameter = number(40)
		}, domain.ErrQHValueNotFound},
		{"missing q90", func(_ *domain.HeatNetwork, _ *domain.NetworkSection, v *[]domain.QHValue) { (*v)[1].QHTableID = 999 }, domain.ErrQHValueNotFound},
		{"missing return q50", func(_ *domain.HeatNetwork, _ *domain.NetworkSection, v *[]domain.QHValue) { (*v)[3].QHTableID = 999 }, domain.ErrQHValueNotFound},
		{"inconsistent anchors", func(_ *domain.HeatNetwork, _ *domain.NetworkSection, v *[]domain.QHValue) {
			(*v)[1].ChannelHeightM = number(3)
		}, domain.ErrQHValueNotFound},
		{"ambiguous anchors", func(_ *domain.HeatNetwork, _ *domain.NetworkSection, v *[]domain.QHValue) { *v = append(*v, (*v)[1]) }, domain.ErrAmbiguousQHValue},
	} {
		t.Run(tc.name, func(t *testing.T) {
			network, section, values := militaryTownNetwork(), separateSection("GVS", 57, 159), separateValues()
			tc.change(&network, &section, &values)
			qh, _, err := selectNetworkSectionValue(network, section, values)
			if !errors.Is(err, tc.want) || qh.Value != 0 {
				t.Fatalf("unexpected partial result %#v, error %v", qh, err)
			}
		})
	}
}

func TestMilitaryTownJointSectionsDoNotProducePartialNetworkTotal(t *testing.T) {
	t.Parallel()
	separate := separateSection("GVS", 57, 57)
	joint := separate
	id := int64(7)
	joint.ID, joint.JointChannelID = 121, &id
	stub := &repositoryStub{network: militaryTownNetwork(), section: joint,
		sections: []domain.NetworkSection{separate, joint}, values: separateValues()}
	service := New(stub)
	rows, err := service.ListNetworkSections(context.Background(), 2)
	if err != nil {
		t.Fatal(err)
	}
	if rows.Sections[0].QHValue == nil || rows.Sections[1].QHValue != nil || rows.Sections[1].QHError == nil ||
		!strings.Contains(*rows.Sections[1].QHError, "совместная прокладка") {
		t.Fatalf("unexpected section results: %#v", rows)
	}
	if _, err = service.GetQHValue(context.Background(), 121); !errors.Is(err, domain.ErrQHValueNotFound) {
		t.Fatal(err)
	}
	total, reason, err := service.TotalNormalizedHeatLossPerHour(context.Background(), 2)
	if err != nil || reason == nil || total != 0 {
		t.Fatalf("partial network total returned: %g, %v, %v", total, reason, err)
	}
}

func TestMilitaryTownReturn50NeedsOnlyItsOwnQ50(t *testing.T) {
	t.Parallel()
	values := separateValues()
	values = values[:4] // Return diameter 159 has q50 only; its q90 is unnecessary.
	qh, _, err := selectNetworkSectionValue(militaryTownNetwork(), separateSection("GVS", 57, 159), values)
	if err != nil || math.Abs(qh.Value-29.125) > 1e-9 {
		t.Fatalf("qh=%g, error=%v", qh.Value, err)
	}
}
