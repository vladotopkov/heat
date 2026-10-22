package service

import (
	"context"
	"errors"
	"fmt"
	"math"
	"strings"
	"testing"

	"lostHeat/internal/sectionqh/domain"
)

func TestEremichiB15UsesProjectSupplyAcrossAllCalculationPaths(t *testing.T) {
	t.Parallel()
	for _, tc := range []struct{ temperature, qh float64 }{
		{90, 51.6},
		{95, 53.925},
		{100, 56.25},
		{80, 46.95},
		{63.44, 39.2496},
	} {
		t.Run(fmt.Sprint(tc.temperature), func(t *testing.T) {
			section := domain.NetworkSection{
				ID: 42, HeatNetworkID: 1, QHTableID: 7, QHTableCode: "Б.15",
				SupplyOuterDiameter: number(159), ReturnOuterDiameter: number(159),
				SupplyTemperature: number(10), ReturnTemperature: number(20),
				Beta: number(1), LengthM: number(100),
			}
			second := section
			second.ID, second.LengthM = 43, number(50)
			second.SupplyTemperature, second.ReturnTemperature = nil, nil
			stub := &repositoryStub{
				network: eremichiNetwork(tc.temperature, 50),
				section: section, sections: []domain.NetworkSection{section, second},
				values: b15Values(159, 16.5, 35.1),
			}
			// Identification is by database ID, even if the display name changes.
			stub.network.Name = "Еремичи (новое название)"
			service := New(stub)
			ctx := context.Background()
			match, err := service.GetQHValue(ctx, section.ID)
			if err != nil || math.Abs(match.QHValue.Value-tc.qh) > 1e-9 {
				t.Fatalf("GetQHValue = %g, error = %v; want %g", match.QHValue.Value, err, tc.qh)
			}
			result, err := service.ListNetworkSections(ctx, 1)
			if err != nil {
				t.Fatal(err)
			}
			for _, row := range result.Sections {
				if row.QHValue == nil || math.Abs(row.QHValue.Value-tc.qh) > 1e-9 {
					t.Fatalf("section %d: qh = %#v, error = %v", row.Section.ID, row.QHValue, row.QHError)
				}
				if row.Section.SupplyTemperature == nil || *row.Section.SupplyTemperature != tc.temperature ||
					row.Section.ReturnTemperature == nil || *row.Section.ReturnTemperature != 50 {
					t.Fatalf("section %d does not display the network regime", row.Section.ID)
				}
			}
			total, reason, err := service.TotalNormalizedHeatLossPerHour(ctx, 1)
			if err != nil || reason != nil || math.Abs(total-3.6*tc.qh*150) > 1e-8 {
				t.Fatalf("total = %g, reason = %v, error = %v", total, reason, err)
			}
		})
	}
}

func TestEremichiUsesBothProjectTemperaturesForOtherTables(t *testing.T) {
	t.Parallel()
	stub := &repositoryStub{
		network: eremichiNetwork(80, 55),
		section: domain.NetworkSection{
			ID: 1, HeatNetworkID: 1, QHTableID: 8, QHTableCode: "Б.14",
			SupplyTemperature: number(90), ReturnTemperature: number(50),
			Beta: number(1), LengthM: number(100),
		},
		values: []domain.QHValue{
			{ID: 1, QHTableID: 8, SupplyTemperatureC: number(90), ReturnTemperatureC: number(50), Value: 10},
			{ID: 2, QHTableID: 8, SupplyTemperatureC: number(80), ReturnTemperatureC: number(55), Value: 20},
			{ID: 3, QHTableID: 8, SupplyTemperatureC: number(80), ReturnTemperatureC: number(60), Value: 30},
		},
	}
	stub.sections = []domain.NetworkSection{stub.section}
	service := New(stub)
	for _, tc := range []struct {
		returnTemperature float64
		wantID            int64
	}{{55, 2}, {60, 3}} {
		stub.network.ProjectReturnTemperature = number(tc.returnTemperature)
		match, err := service.GetQHValue(context.Background(), 1)
		if err != nil || match.QHValue.ID != tc.wantID {
			t.Fatalf("GetQHValue = %#v, error = %v", match, err)
		}
		result, err := service.ListNetworkSections(context.Background(), 1)
		if err != nil {
			t.Fatal(err)
		}
		row := result.Sections[0]
		if row.QHValue == nil || row.QHValue.ID != tc.wantID || *row.Section.ReturnTemperature != tc.returnTemperature {
			t.Fatalf("ListNetworkSections used stale section temperatures: %#v", row)
		}
	}
}

func TestEremichiDoesNotFallBackToStoredSectionTemperatures(t *testing.T) {
	t.Parallel()
	for _, field := range []string{"supply", "return", "nonfinite"} {
		t.Run(field, func(t *testing.T) {
			network := eremichiNetwork(95, 50)
			switch field {
			case "supply":
				network.ProjectSupplyTemperature = nil
			case "return":
				network.ProjectReturnTemperature = nil
			case "nonfinite":
				network.ProjectSupplyTemperature = number(math.NaN())
			}
			section := domain.NetworkSection{
				ID: 1, HeatNetworkID: 1, QHTableID: 7, QHTableCode: "Б.15",
				SupplyOuterDiameter: number(159), ReturnOuterDiameter: number(159),
				SupplyTemperature: number(95), ReturnTemperature: number(50),
				Beta: number(1), LengthM: number(100),
			}
			stub := &repositoryStub{network: network, section: section,
				sections: []domain.NetworkSection{section}, values: b15Values(159, 16.5, 35.1)}
			service := New(stub)
			_, err := service.GetQHValue(context.Background(), 1)
			if !errors.Is(err, domain.ErrQHValueNotFound) || !strings.Contains(err.Error(), "HeatNetwork") {
				t.Fatalf("missing project temperature: error = %v", err)
			}
			result, err := service.ListNetworkSections(context.Background(), 1)
			if err != nil {
				t.Fatal(err)
			}
			if result.Sections[0].QHValue != nil || result.Sections[0].QHError == nil {
				t.Fatal("missing project temperatures must not produce a qh")
			}
			total, reason, err := service.TotalNormalizedHeatLossPerHour(context.Background(), 1)
			if err != nil || reason == nil || total != 0 {
				t.Fatalf("total = %g, reason = %v, error = %v", total, reason, err)
			}
		})
	}
}

func TestEremichiB15ReportsUnsupportedProjectReturn(t *testing.T) {
	t.Parallel()
	section := domain.NetworkSection{QHTableID: 7, QHTableCode: "Б.15",
		SupplyOuterDiameter: number(159), ReturnOuterDiameter: number(159),
		SupplyTemperature: number(95), ReturnTemperature: number(50)}
	_, _, err := selectNetworkSectionValue(eremichiNetwork(95, 46.54), section, b15Values(159, 16.5, 35.1))
	if !errors.Is(err, domain.ErrQHValueNotFound) || !strings.Contains(err.Error(), "46.54") {
		t.Fatalf("unsupported return regime must not select a supply-only qh: %v", err)
	}
}
