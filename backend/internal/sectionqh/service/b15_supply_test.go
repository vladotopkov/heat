package service

import (
	"context"
	"errors"
	"fmt"
	"math"
	"reflect"
	"testing"

	"lostHeat/internal/sectionqh/domain"
)

func TestB15Supply95AllDiameters(t *testing.T) {
	t.Parallel()

	// All 31 rows from newSql/fill_qh_values_b15_table_id_1.sql.
	// Expected values are independent, precomputed results at 95 C.
	rows := []struct{ diameter, q50, q90, want float64 }{
		{32, 7.9, 15.8, 16.7875},
		{33.5, 8.2, 16.4, 17.425},
		{38, 7.7, 15.5, 16.475},
		{42.3, 8.5, 17.1, 18.175},
		{45, 9, 18.2, 19.35},
		{48, 9.6, 19.5, 20.7375},
		{57, 10, 20.5, 21.8125},
		{60, 10.6, 21.8, 23.2},
		{75.5, 12.2, 25.6, 27.275},
		{76, 12.5, 26, 27.6875},
		{88.5, 12.8, 26.8, 28.55},
		{89, 12.9, 27, 28.7625},
		{108, 12.6, 26.1, 27.7875},
		{114, 13.6, 28.4, 30.25},
		{133, 14.4, 30.3, 32.2875},
		{140, 15.6, 33.3, 35.5125},
		{159, 16.5, 35.1, 37.425},
		{165, 17.6, 37.9, 40.4375},
		{219, 20, 43.6, 46.55},
		{273, 19.6, 42.1, 44.9125},
		{325, 22.6, 49.2, 52.525},
		{377, 25.2, 56.2, 60.075},
		{426, 26.3, 58.5, 62.525},
		{530, 25.2, 55.5, 59.2875},
		{630, 29.5, 67.3, 72.025},
		{720, 32, 73, 78.125},
		{820, 35.2, 81.9, 87.7375},
		{920, 38.6, 91.6, 98.225},
		{1020, 41.7, 100.9, 108.3},
		{1220, 43.5, 103.9, 111.45},
		{1420, 52.2, 134.7, 145.0125},
	}
	var values []domain.QHValue
	for _, row := range rows {
		values = append(values, b15Values(row.diameter, row.q50, row.q90)...)
	}
	before := append([]domain.QHValue(nil), values...)

	for _, row := range rows {
		t.Run(fmt.Sprint(row.diameter), func(t *testing.T) {
			section := domain.NetworkSection{
				QHTableID: 7, SupplyOuterDiameter: number(row.diameter),
				// A different return diameter and temperature must not select q50.
				ReturnOuterDiameter: number(1420), ReturnTemperature: number(70),
				SupplyTemperature: number(90),
			}
			value, fields, err := selectB15Supply(section, values, 95)
			if err != nil {
				t.Fatalf("selectB15Supply() error = %v", err)
			}
			if math.Abs(value.Value-row.want) > 1e-9 {
				t.Errorf("q95 = %g, want %g", value.Value, row.want)
			}
			if value.SupplyTemperatureC == nil || *value.SupplyTemperatureC != 95 ||
				value.PipelineRole == nil || *value.PipelineRole != "SUPPLY" {
				t.Errorf("result must describe supply at 95 C: %#v", value)
			}
			if !reflect.DeepEqual(fields, []string{"outer_diameter_mm=supply_outer_diameter_mm"}) {
				t.Errorf("matched fields = %v", fields)
			}
		})
	}
	if !reflect.DeepEqual(values, before) {
		t.Error("the shared normative values were modified")
	}
}

func TestB15Supply95RejectsMissingOrInconsistentAnchors(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		change func(*domain.NetworkSection, *[]domain.QHValue)
		want   error
	}{
		{"missing supply diameter", func(s *domain.NetworkSection, _ *[]domain.QHValue) {
			s.SupplyOuterDiameter = nil
		}, domain.ErrQHValueNotFound},
		{"unknown supply diameter", func(s *domain.NetworkSection, _ *[]domain.QHValue) {
			s.SupplyOuterDiameter = number(999)
		}, domain.ErrQHValueNotFound},
		{"q50 belongs to return pipe diameter", func(_ *domain.NetworkSection, v *[]domain.QHValue) {
			(*v)[0].OuterDiameterMM = number(89)
		}, domain.ErrQHValueNotFound},
		{"missing q50", func(_ *domain.NetworkSection, v *[]domain.QHValue) {
			*v = (*v)[1:]
		}, domain.ErrQHValueNotFound},
		{"missing q90", func(_ *domain.NetworkSection, v *[]domain.QHValue) {
			*v = (*v)[:1]
		}, domain.ErrQHValueNotFound},
		{"q50 from another table", func(_ *domain.NetworkSection, v *[]domain.QHValue) {
			(*v)[0].QHTableID = 8
		}, domain.ErrQHValueNotFound},
		{"wrong anchor temperature", func(_ *domain.NetworkSection, v *[]domain.QHValue) {
			(*v)[0].ReturnTemperatureC = number(60)
		}, domain.ErrQHValueNotFound},
		{"missing anchor temperature", func(_ *domain.NetworkSection, v *[]domain.QHValue) {
			(*v)[1].SupplyTemperatureC = nil
		}, domain.ErrQHValueNotFound},
		{"different channel height", func(_ *domain.NetworkSection, v *[]domain.QHValue) {
			(*v)[0].ChannelHeightM = number(0.6)
		}, domain.ErrQHValueNotFound},
		{"different channel width", func(_ *domain.NetworkSection, v *[]domain.QHValue) {
			(*v)[0].ChannelWidthM = number(1.5)
		}, domain.ErrQHValueNotFound},
		{"different thermal resistance", func(_ *domain.NetworkSection, v *[]domain.QHValue) {
			(*v)[0].ThermalResistance = number(7)
		}, domain.ErrQHValueNotFound},
		{"duplicate q50", func(_ *domain.NetworkSection, v *[]domain.QHValue) {
			*v = append(*v, (*v)[0])
		}, domain.ErrAmbiguousQHValue},
		{"duplicate q90", func(_ *domain.NetworkSection, v *[]domain.QHValue) {
			*v = append(*v, (*v)[1])
		}, domain.ErrAmbiguousQHValue},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			section := domain.NetworkSection{
				QHTableID: 7, SupplyOuterDiameter: number(57), ReturnOuterDiameter: number(89),
			}
			values := b15Values(57, 10, 20.5)
			test.change(&section, &values)
			_, _, err := selectB15Supply(section, values, 95)
			if !errors.Is(err, test.want) {
				t.Fatalf("error = %v, want %v", err, test.want)
			}
		})
	}
}

func TestEremichiSupply95ServicePaths(t *testing.T) {
	t.Parallel()

	for _, storedTemperature := range []*float64{nil, number(90), number(95)} {
		t.Run(fmt.Sprint(storedTemperature), func(t *testing.T) {
			section := domain.NetworkSection{
				ID: 42, HeatNetworkID: 1, QHTableID: 7, QHTableCode: "Б.15",
				SupplyOuterDiameter: number(159), ReturnOuterDiameter: number(159),
				SupplyTemperature: storedTemperature, ReturnTemperature: number(70),
				Beta: number(1), LengthM: number(100),
			}
			stub := &repositoryStub{
				network: eremichiNetwork(95, 50),
				section: section, sections: []domain.NetworkSection{section},
				values: b15Values(159, 16.5, 35.1),
			}
			service := New(stub)
			match, err := service.GetQHValue(context.Background(), 42)
			if err != nil {
				t.Fatalf("GetQHValue() error = %v", err)
			}
			// Supply increases by 2.325; return remains 16.5.
			if math.Abs(match.QHValue.Value-53.925) > 1e-9 {
				t.Errorf("GetQHValue() = %g, want 53.925", match.QHValue.Value)
			}
			result, err := service.ListNetworkSections(context.Background(), 1)
			if err != nil {
				t.Fatalf("ListNetworkSections() error = %v", err)
			}
			got := result.Sections[0]
			if got.QHValue == nil || math.Abs(got.QHValue.Value-53.925) > 1e-9 {
				t.Errorf("ListNetworkSections() qh = %#v, want 53.925; error = %v", got.QHValue, got.QHError)
			}
			if got.Section.SupplyTemperature == nil || *got.Section.SupplyTemperature != 95 {
				t.Errorf("displayed supply temperature = %v, want 95", got.Section.SupplyTemperature)
			}
			if got.Section.ReturnTemperature == nil || *got.Section.ReturnTemperature != 50 {
				t.Error("displayed return temperature must come from HeatNetwork")
			}
			total, reason, err := service.TotalNormalizedHeatLossPerHour(context.Background(), 1)
			if err != nil || reason != nil || math.Abs(total-19413) > 1e-9 {
				t.Errorf("total = %g, reason = %v, error = %v; want 19413", total, reason, err)
			}
			if !reflect.DeepEqual(stub.section, section) ||
				!reflect.DeepEqual(stub.values, b15Values(159, 16.5, 35.1)) {
				t.Error("stored section or normative values were modified")
			}
		})
	}
}

func TestEremichiSupply95PreservesOtherNetworksAndTables(t *testing.T) {
	t.Parallel()

	for _, test := range []struct{ name, code string }{
		{"Другая теплосеть", "Б.15"},
		{"Еремичи-2", "Б.15"},
		{"Еремичи", "Б.14"},
	} {
		t.Run(test.name+test.code, func(t *testing.T) {
			section := domain.NetworkSection{
				QHTableID: 7, QHTableCode: test.code,
				SupplyOuterDiameter: number(159), ReturnOuterDiameter: number(159),
				SupplyTemperature: number(90), ReturnTemperature: number(50),
			}
			stub := &repositoryStub{
				network: domain.HeatNetwork{ID: 3, Name: test.name,
					ProjectSupplyTemperature: number(95), ProjectReturnTemperature: number(70)},
				section: section, sections: []domain.NetworkSection{section},
				values: b15Values(159, 16.5, 35.1),
			}
			match, err := New(stub).GetQHValue(context.Background(), 1)
			if err != nil || math.Abs(match.QHValue.Value-51.6) > 1e-9 {
				t.Fatalf("GetQHValue() = %#v, error = %v; want 51.6", match, err)
			}
			result, err := New(stub).ListNetworkSections(context.Background(), 1)
			if err != nil {
				t.Fatal(err)
			}
			got := result.Sections[0]
			if got.QHValue == nil || math.Abs(got.QHValue.Value-51.6) > 1e-9 ||
				*got.Section.SupplyTemperature != 90 {
				t.Errorf("unrelated network/table changed: %#v", got)
			}
		})
	}
}

func TestEremichiSupply95PreservesReturnSelection(t *testing.T) {
	t.Parallel()

	section := domain.NetworkSection{
		QHTableID: 7, QHTableCode: "Б.15",
		SupplyOuterDiameter: number(159), ReturnOuterDiameter: number(57),
		SupplyTemperature: number(90), ReturnTemperature: number(50),
		ReturnWallThickness: number(3.5),
	}
	values := b15Values(159, 16.5, 35.1)
	// The existing matcher selects this more specific return-pipe row.
	returnValue := domain.QHValue{
		ID: 4, QHTableID: 7, OuterDiameterMM: number(57),
		PipelineRole: text("RETURN"), ReturnTemperatureC: number(50),
		PressurePipeWallThicknessMM: number(3.5), Value: 10,
	}
	values = append(values, returnValue)
	got, _, err := selectNetworkSectionValue(eremichiNetwork(95, 50), section, values)
	if err != nil || !reflect.DeepEqual(got, returnValue) {
		t.Errorf("return result = %#v, error = %v; want unchanged %#v", got, err, returnValue)
	}
}

func TestEremichiSupply95UsesSupplyDiameterWithDifferentReturn(t *testing.T) {
	t.Parallel()

	section := domain.NetworkSection{
		QHTableID: 7, QHTableCode: "Б.15",
		SupplyOuterDiameter: number(159), ReturnOuterDiameter: number(57),
		SupplyTemperature: number(90), ReturnTemperature: number(70),
	}
	values := b15Values(159, 16.5, 35.1)
	otherDiameterValues := b15Values(57, 10, 20.5)
	for index := range otherDiameterValues {
		otherDiameterValues[index].ID += 3
	}
	values = append(values, otherDiameterValues...)
	got, _, err := selectB15Supply(section, values, 95)
	if err != nil || math.Abs(got.Value-37.425) > 1e-9 ||
		got.PipelineRole == nil || *got.PipelineRole != "SUPPLY" {
		t.Errorf("supply result = %#v, error = %v; want 37.425", got, err)
	}
}

func TestEremichiSupply95PreservesTabulatedTotalRounding(t *testing.T) {
	t.Parallel()

	section := domain.NetworkSection{
		QHTableID: 7, QHTableCode: "Б.15",
		SupplyOuterDiameter: number(57), ReturnOuterDiameter: number(57),
		SupplyTemperature: number(90), ReturnTemperature: number(50),
	}
	values := b15Values(57, 10, 20.5)
	values[2].Value = 30.6 // B.15 total differs from its rounded component sum, 30.5.
	got, _, err := selectNetworkSectionValue(eremichiNetwork(95, 50), section, values)
	if err != nil || math.Abs(got.Value-31.9125) > 1e-9 {
		t.Errorf("total result = %#v, error = %v; want 31.9125", got, err)
	}
}

func b15Values(diameter, q50, q90 float64) []domain.QHValue {
	row := domain.QHValue{
		QHTableID: 7, OuterDiameterMM: number(diameter),
		ChannelHeightM: number(0.45), ChannelWidthM: number(0.9),
		ThermalResistance: number(3.82284),
	}
	qReturn, qSupply, qTotal := row, row, row
	qReturn.ID, qReturn.Value = 1, q50
	qReturn.PipelineRole, qReturn.ReturnTemperatureC = text("RETURN"), number(50)
	qSupply.ID, qSupply.Value = 2, q90
	qSupply.PipelineRole, qSupply.SupplyTemperatureC = text("SUPPLY"), number(90)
	qTotal.ID, qTotal.Value = 3, q50+q90
	qTotal.PipelineRole = text("TWO_PIPE_TOTAL")
	qTotal.SupplyTemperatureC, qTotal.ReturnTemperatureC = number(90), number(50)
	return []domain.QHValue{qReturn, qSupply, qTotal}
}

func eremichiNetwork(supply, returnTemperature float64) domain.HeatNetwork {
	return domain.HeatNetwork{
		ID: 1, Name: "Еремичи",
		ProjectSupplyTemperature: number(supply),
		ProjectReturnTemperature: number(returnTemperature),
	}
}
