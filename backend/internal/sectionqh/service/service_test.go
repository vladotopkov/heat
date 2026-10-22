package service

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"lostHeat/internal/sectionqh/domain"
)

type repositoryStub struct {
	section          domain.NetworkSection
	values           []domain.QHValue
	network          domain.HeatNetwork
	networks         []domain.HeatNetwork
	sections         []domain.NetworkSection
	valuesByTable    map[int64][]domain.QHValue
	betaValues       []domain.BetaValue
	betaListRequests int
	savedBetas       map[int64]float64
	saveBetaErr      error
	requestedSection int64
	requestedTable   int64
	tableRequests    map[int64]int
}

func (stub *repositoryStub) ListBetaValues(
	_ context.Context,
) ([]domain.BetaValue, error) {
	stub.betaListRequests++
	return stub.betaValues, nil
}

func (stub *repositoryStub) SaveNetworkSectionBeta(
	_ context.Context,
	networkSectionID int64,
	beta float64,
) error {
	if stub.saveBetaErr != nil {
		return stub.saveBetaErr
	}
	if stub.savedBetas == nil {
		stub.savedBetas = make(map[int64]float64)
	}
	stub.savedBetas[networkSectionID] = beta

	return nil
}

func (stub *repositoryStub) ListHeatNetworks(
	_ context.Context,
) ([]domain.HeatNetwork, error) {
	return stub.networks, nil
}

func (stub *repositoryStub) GetHeatNetwork(
	_ context.Context,
	_ int64,
) (domain.HeatNetwork, error) {
	return stub.network, nil
}

func (stub *repositoryStub) ListNetworkSectionsByHeatNetworkID(
	_ context.Context,
	_ int64,
) ([]domain.NetworkSection, error) {
	return stub.sections, nil
}

func (stub *repositoryStub) GetNetworkSection(
	_ context.Context,
	id int64,
) (domain.NetworkSection, error) {
	stub.requestedSection = id
	return stub.section, nil
}

func (stub *repositoryStub) ListQHValuesByTableID(
	_ context.Context,
	qhTableID int64,
) ([]domain.QHValue, error) {
	stub.requestedTable = qhTableID
	if stub.tableRequests != nil {
		stub.tableRequests[qhTableID]++
	}
	if stub.valuesByTable != nil {
		return stub.valuesByTable[qhTableID], nil
	}

	return stub.values, nil
}

func TestListNetworkSectionsLoadsQHValuesOncePerTable(t *testing.T) {
	t.Parallel()

	stub := &repositoryStub{
		network: eremichiNetwork(95, 50),
		sections: []domain.NetworkSection{
			{
				ID:                  1,
				HeatNetworkID:       1,
				QHTableID:           7,
				SupplyOuterDiameter: number(57),
				ReturnOuterDiameter: number(57),
			},
			{
				ID:                  2,
				HeatNetworkID:       1,
				QHTableID:           7,
				SupplyOuterDiameter: number(89),
				ReturnOuterDiameter: number(89),
			},
		},
		valuesByTable: map[int64][]domain.QHValue{
			7: {
				{
					ID:              10,
					QHTableID:       7,
					OuterDiameterMM: number(57),
					PipelineRole:    text("TWO_PIPE_TOTAL"),
					Value:           30.6,
				},
				{
					ID:              11,
					QHTableID:       7,
					OuterDiameterMM: number(89),
					PipelineRole:    text("TWO_PIPE_TOTAL"),
					Value:           39.9,
				},
			},
		},
		tableRequests: make(map[int64]int),
	}

	result, err := New(stub).ListNetworkSections(context.Background(), 1)
	if err != nil {
		t.Fatalf("ListNetworkSections() error = %v", err)
	}

	if len(result.Sections) != 2 {
		t.Fatalf("sections count = %d, want 2", len(result.Sections))
	}
	if stub.tableRequests[7] != 1 {
		t.Errorf(
			"qh_table_id=7 load count = %d, want 1",
			stub.tableRequests[7],
		)
	}
	if result.Sections[0].QHValue == nil ||
		result.Sections[0].QHValue.Value != 30.6 {
		t.Errorf("first section qh_value = %#v, want 30.6", result.Sections[0].QHValue)
	}
	if result.Sections[1].QHValue == nil ||
		result.Sections[1].QHValue.Value != 39.9 {
		t.Errorf("second section qh_value = %#v, want 39.9", result.Sections[1].QHValue)
	}
}

func TestListNetworkSectionsUsesStoredBetaWithoutLookup(t *testing.T) {
	t.Parallel()

	stub := &repositoryStub{
		network: domain.HeatNetwork{ID: 1, Name: "Test network"},
		sections: []domain.NetworkSection{{
			ID:                  4,
			HeatNetworkID:       1,
			QHTableID:           7,
			Beta:                number(1.15),
			SupplyOuterDiameter: number(57),
		}},
		valuesByTable: map[int64][]domain.QHValue{
			7: {{
				ID:              10,
				QHTableID:       7,
				OuterDiameterMM: number(57),
				PipelineRole:    text("SUPPLY"),
				Value:           30.6,
			}},
		},
	}

	result, err := New(stub).ListNetworkSections(context.Background(), 1)
	if err != nil {
		t.Fatalf("ListNetworkSections() error = %v", err)
	}

	if stub.betaListRequests != 0 {
		t.Errorf("beta lookup count = %d, want 0", stub.betaListRequests)
	}
	if len(stub.savedBetas) != 0 {
		t.Errorf("saved betas = %#v, want none", stub.savedBetas)
	}
	if result.Sections[0].Beta == nil || result.Sections[0].Beta.Value != 1.15 {
		t.Errorf("beta = %#v, want stored value 1.15", result.Sections[0].Beta)
	}
}

func TestListNetworkSectionsFindsAndStoresMissingBeta(t *testing.T) {
	t.Parallel()

	stub := &repositoryStub{
		network: domain.HeatNetwork{ID: 1, Name: "Test network"},
		sections: []domain.NetworkSection{{
			ID:                  4,
			HeatNetworkID:       1,
			QHTableID:           7,
			QHTableName:         "PI-PIPELINE",
			ProjectDate:         date(2022, time.January, 1),
			SupplyOuterDiameter: number(57),
		}},
		valuesByTable: map[int64][]domain.QHValue{
			7: {{
				ID:              10,
				QHTableID:       7,
				OuterDiameterMM: number(57),
				PipelineRole:    text("SUPPLY"),
				Value:           30.6,
			}},
		},
		betaValues: []domain.BetaValue{{
			ID:              19,
			ProjectDateFrom: date(2010, time.January, 1),
			PipeType:        text("PI"),
			ObjectKind:      text("PIPELINE"),
			Value:           1,
		}},
	}

	result, err := New(stub).ListNetworkSections(context.Background(), 1)
	if err != nil {
		t.Fatalf("ListNetworkSections() error = %v", err)
	}

	if stub.betaListRequests != 1 {
		t.Errorf("beta lookup count = %d, want 1", stub.betaListRequests)
	}
	if stub.savedBetas[4] != 1 {
		t.Errorf("saved beta = %v, want 1", stub.savedBetas[4])
	}
	if result.Sections[0].Beta == nil || result.Sections[0].Beta.Value != 1 {
		t.Errorf("beta = %#v, want calculated value 1", result.Sections[0].Beta)
	}
}

func TestGetQHValueUsesSectionTableAndSelectsMostSpecificRow(t *testing.T) {
	t.Parallel()

	stub := &repositoryStub{
		section: domain.NetworkSection{
			ID:                  42,
			QHTableID:           7,
			SupplyOuterDiameter: number(159),
			ReturnOuterDiameter: number(159),
			SupplyTemperature:   number(90),
			ReturnTemperature:   number(50),
		},
		values: []domain.QHValue{
			{
				ID:                 1,
				QHTableID:          7,
				OuterDiameterMM:    number(159),
				PipelineRole:       text("RETURN"),
				ReturnTemperatureC: number(50),
				Value:              16.5,
			},
			{
				ID:                 2,
				QHTableID:          7,
				OuterDiameterMM:    number(159),
				PipelineRole:       text("SUPPLY"),
				SupplyTemperatureC: number(90),
				Value:              35.1,
			},
			{
				ID:                 3,
				QHTableID:          7,
				OuterDiameterMM:    number(159),
				PipelineRole:       text("TWO_PIPE_TOTAL"),
				SupplyTemperatureC: number(90),
				ReturnTemperatureC: number(50),
				Value:              51.6,
			},
		},
	}

	match, err := New(stub).GetQHValue(context.Background(), 42)
	if err != nil {
		t.Fatalf("GetQHValue() error = %v", err)
	}

	if stub.requestedSection != 42 {
		t.Errorf("requested section = %d, want 42", stub.requestedSection)
	}
	if stub.requestedTable != 7 {
		t.Errorf("requested qh table = %d, want 7", stub.requestedTable)
	}
	if match.QHValue.ID != 3 {
		t.Errorf("selected qh_value id = %d, want 3", match.QHValue.ID)
	}

	wantFields := []string{
		"outer_diameter_mm=supply_outer_diameter_mm",
		"outer_diameter_mm=return_outer_diameter_mm",
		"supply_temperature_c=supply_temperature_c",
		"return_temperature_c=return_temperature_c",
	}
	if !reflect.DeepEqual(match.MatchedFields, wantFields) {
		t.Errorf(
			"matched fields = %#v, want %#v",
			match.MatchedFields,
			wantFields,
		)
	}
}

func TestGetQHValueDoesNotRequireMissingSectionFields(t *testing.T) {
	t.Parallel()

	stub := &repositoryStub{
		section: domain.NetworkSection{
			ID:                  1,
			QHTableID:           1,
			SupplyOuterDiameter: number(57),
			// The section has no supply temperature. It must be ignored.
			SupplyTemperature: nil,
		},
		values: []domain.QHValue{{
			ID:                 19,
			QHTableID:          1,
			OuterDiameterMM:    number(57),
			PipelineRole:       text("SUPPLY"),
			SupplyTemperatureC: number(90),
			Value:              20.5,
		}},
	}

	match, err := New(stub).GetQHValue(context.Background(), 1)
	if err != nil {
		t.Fatalf("GetQHValue() error = %v", err)
	}

	if match.QHValue.ID != 19 {
		t.Errorf("selected qh_value id = %d, want 19", match.QHValue.ID)
	}
}

func TestGetQHValueReturnsNotFoundWhenCharacteristicsDiffer(t *testing.T) {
	t.Parallel()

	stub := &repositoryStub{
		section: domain.NetworkSection{
			ID:                  1,
			QHTableID:           1,
			SupplyOuterDiameter: number(57),
		},
		values: []domain.QHValue{{
			ID:              1,
			QHTableID:       1,
			OuterDiameterMM: number(89),
			PipelineRole:    text("SUPPLY"),
		}},
	}

	_, err := New(stub).GetQHValue(context.Background(), 1)
	if !errors.Is(err, domain.ErrQHValueNotFound) {
		t.Fatalf("GetQHValue() error = %v, want ErrQHValueNotFound", err)
	}
}

func TestGetQHValueReturnsConflictForEquallySpecificRows(t *testing.T) {
	t.Parallel()

	stub := &repositoryStub{
		section: domain.NetworkSection{
			ID:                  1,
			QHTableID:           1,
			SupplyOuterDiameter: number(57),
			ReturnOuterDiameter: number(89),
		},
		values: []domain.QHValue{
			{
				ID:              1,
				QHTableID:       1,
				OuterDiameterMM: number(57),
				PipelineRole:    text("SUPPLY"),
			},
			{
				ID:              2,
				QHTableID:       1,
				OuterDiameterMM: number(89),
				PipelineRole:    text("RETURN"),
			},
		},
	}

	_, err := New(stub).GetQHValue(context.Background(), 1)
	if !errors.Is(err, domain.ErrAmbiguousQHValue) {
		t.Fatalf("GetQHValue() error = %v, want ErrAmbiguousQHValue", err)
	}
}

func number(value float64) *float64 {
	return &value
}

func text(value string) *string {
	return &value
}

func date(year int, month time.Month, day int) *time.Time {
	value := time.Date(year, month, day, 0, 0, 0, 0, time.UTC)
	return &value
}
