package service

import (
	"errors"
	"math"
	"strings"
	"testing"

	"lostHeat/internal/sectionqh/domain"
)

func TestJointChannelQHNormsForMilitaryTown(t *testing.T) {
	t.Parallel()
	sections := jointB15Sections(57, 57, 57, 57)
	values := b15Values(57, 10, 20.5)
	values[2].Value = 30.6
	for index := range values {
		// The joint-channel lookup is intentionally based only on table,
		// outer diameter and pipeline role.
		values[index].NominalBoreMM = number(999)
		values[index].SupplyTemperatureC = nil
		values[index].ReturnTemperatureC = nil
	}

	result, err := calculateJointChannelQHNorms(
		militaryTownNetwork(),
		sections,
		map[int64][]domain.QHValue{7: values},
	)
	if err != nil {
		t.Fatal(err)
	}
	if len(result) != 1 {
		t.Fatalf("calculated %d channel norms, want 1", len(result))
	}

	norms := result[17]
	assertClose(t, "q1n", norms.q1n, 17.875)
	assertClose(t, "qn", norms.qn, 30.6)
	assertClose(t, "q2n", norms.q2n, 12.725)
	assertClose(t, "q3n", norms.q3n, 12.625)
	assertClose(t, "q4n", norms.q4n, 10)
}

func TestJointChannelQHNormsUseHeatNetworkTemperatures(t *testing.T) {
	t.Parallel()
	network := militaryTownNetwork()
	network.ProjectSupplyTemperature = number(70)
	network.GVSProjectSupplyTemperature = number(65)
	values := b15Values(57, 10, 20.5)
	values[2].Value = 30.6

	result, err := calculateJointChannelQHNorms(
		network,
		jointB15Sections(57, 57, 57, 57),
		map[int64][]domain.QHValue{7: values},
	)
	if err != nil {
		t.Fatal(err)
	}

	norms := result[17]
	assertClose(t, "q1n", norms.q1n, 15.25)
	assertClose(t, "q2n", norms.q2n, 15.35)
	assertClose(t, "q3n", norms.q3n, 13.9375)
	assertClose(t, "q4n", norms.q4n, 10)
}

func TestJointChannelQHNormsRequireEqualHeatingDiameters(t *testing.T) {
	t.Parallel()
	sections := jointB15Sections(57, 76, 57, 57)
	_, err := calculateJointChannelQHNorms(
		militaryTownNetwork(),
		sections,
		map[int64][]domain.QHValue{7: b15Values(57, 10, 20.5)},
	)
	if err == nil || !strings.Contains(err.Error(), "different supply_outer_diameter_mm") {
		t.Fatalf("error = %v, want unequal HEATING diameter error", err)
	}
}

func TestJointChannelQHNormsRejectMissingExactB15Diameter(t *testing.T) {
	t.Parallel()
	sections := jointB15Sections(57, 57, 57, 76)
	_, err := calculateJointChannelQHNorms(
		militaryTownNetwork(),
		sections,
		map[int64][]domain.QHValue{7: b15Values(57, 10, 20.5)},
	)
	if !errors.Is(err, domain.ErrQHValueNotFound) ||
		!strings.Contains(err.Error(), "outer_diameter_mm=76") {
		t.Fatalf("error = %v, want missing exact diameter error", err)
	}
}

func TestJointChannelQHNormsRequireHeatingAndGVS(t *testing.T) {
	t.Parallel()
	sections := jointB15Sections(57, 57, 57, 57)
	values := map[int64][]domain.QHValue{7: b15Values(57, 10, 20.5)}

	if _, err := calculateJointChannelQHNorms(
		militaryTownNetwork(),
		sections[:1],
		values,
	); err == nil || !strings.Contains(err.Error(), "has no GVS section") {
		t.Fatalf("missing GVS error = %v", err)
	}

	duplicate := append([]domain.NetworkSection(nil), sections...)
	duplicate = append(duplicate, sections[0])
	duplicate[2].ID = 3
	if _, err := calculateJointChannelQHNorms(
		militaryTownNetwork(),
		duplicate,
		values,
	); err == nil || !strings.Contains(err.Error(), "more than one HEATING") {
		t.Fatalf("duplicate HEATING error = %v", err)
	}
}

func TestJointChannelQHNormsRequireB15AndFiftyDegreeReturns(t *testing.T) {
	t.Parallel()
	values := map[int64][]domain.QHValue{7: b15Values(57, 10, 20.5)}

	sections := jointB15Sections(57, 57, 57, 57)
	sections[1].QHTableCode = "Б.14"
	if _, err := calculateJointChannelQHNorms(
		militaryTownNetwork(),
		sections,
		values,
	); err == nil || !strings.Contains(err.Error(), "table_code=Б.15") {
		t.Fatalf("wrong table error = %v", err)
	}

	network := militaryTownNetwork()
	network.ProjectReturnTemperature = number(60)
	if _, err := calculateJointChannelQHNorms(
		network,
		jointB15Sections(57, 57, 57, 57),
		values,
	); err == nil || !strings.Contains(err.Error(), "project_return_temperature_c") {
		t.Fatalf("wrong heating return temperature error = %v", err)
	}

	network = militaryTownNetwork()
	network.GVSProjectCirculationTemperature = number(55)
	if _, err := calculateJointChannelQHNorms(
		network,
		jointB15Sections(57, 57, 57, 57),
		values,
	); err == nil || !strings.Contains(err.Error(), "gvs_project_circulation_temperature_c") {
		t.Fatalf("wrong GVS circulation temperature error = %v", err)
	}
}

func jointB15Sections(
	heatingSupply,
	heatingReturn,
	gvsSupply,
	gvsReturn float64,
) []domain.NetworkSection {
	channelID := int64(17)
	return []domain.NetworkSection{
		{
			ID: 1, HeatNetworkID: 2, NetworkType: "HEATING",
			JointChannelID: &channelID, QHTableID: 7, QHTableCode: "Б.15",
			NominalBoreMM:       number(1),
			SupplyOuterDiameter: number(heatingSupply),
			ReturnOuterDiameter: number(heatingReturn),
		},
		{
			ID: 2, HeatNetworkID: 2, NetworkType: "GVS",
			JointChannelID: &channelID, QHTableID: 7, QHTableCode: "Б.15",
			NominalBoreMM:       number(2),
			SupplyOuterDiameter: number(gvsSupply),
			ReturnOuterDiameter: number(gvsReturn),
		},
	}
}

func assertClose(t *testing.T, name string, actual, expected float64) {
	t.Helper()
	if math.Abs(actual-expected) > 1e-12 {
		t.Fatalf("%s = %.15f, want %.15f", name, actual, expected)
	}
}
