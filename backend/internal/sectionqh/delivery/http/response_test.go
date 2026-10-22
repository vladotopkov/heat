package sectionqhhttp

import (
	"encoding/json"
	"strings"
	"testing"

	"lostHeat/internal/sectionqh/domain"
)

func TestCalculatedTwoPipeResponseHasComponentsAndNoSourceRowID(t *testing.T) {
	supply, returnQH := 12.625, 10.0
	qh := domain.QHValue{Value: 22.625, SupplyValue: &supply, ReturnValue: &returnQH,
		PipelineRole: textPointer("TWO_PIPE_TOTAL"), SourceInterpolated: true}
	response := newQHValueResponse(domain.Match{NetworkSectionID: 120, QHTableID: 1, QHValue: qh})
	body, err := json.Marshal(response)
	if err != nil {
		t.Fatal(err)
	}
	for _, expected := range []string{`"qh_value_id":null`, `"qh_value":22.625`, `"qh_supply":12.625`, `"qh_return":10`, `"pipeline_role":"TWO_PIPE_TOTAL"`} {
		if !strings.Contains(string(body), expected) {
			t.Fatalf("response %s missing %s", body, expected)
		}
	}
	jointID := int64(7)
	reason := "совместная прокладка"
	list := newNetworkSectionsResponse(domain.HeatNetworkSections{
		HeatNetwork: domain.HeatNetwork{ID: 2},
		Sections: []domain.NetworkSectionWithQH{
			{Section: domain.NetworkSection{ID: 120, NetworkType: "GVS"}, QHValue: &qh},
			{Section: domain.NetworkSection{ID: 121, NetworkType: "HEATING", JointChannelID: &jointID}, QHError: &reason},
		},
	})
	if list.Sections[0].QHSupply == nil || *list.Sections[0].QHSupply != supply ||
		list.Sections[0].QHReturn == nil || *list.Sections[0].QHReturn != returnQH ||
		list.Sections[0].NetworkType != "GVS" || list.Sections[0].JointChannelID != nil {
		t.Fatalf("separate section response: %#v", list.Sections[0])
	}
	if list.Sections[1].QHValue != nil || list.Sections[1].JointChannelID == nil || list.Sections[1].QHError == nil {
		t.Fatalf("joint section must be marked as unavailable: %#v", list.Sections[1])
	}
}
