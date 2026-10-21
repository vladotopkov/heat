package sectionqhhttp

import "lostHeat/internal/sectionqh/domain"

type heatNetworkResponse struct {
	ID   int64  `json:"id"`
	Name string `json:"name"`
}

type heatNetworksResponse struct {
	HeatNetworks []heatNetworkResponse `json:"heat_networks"`
}

type networkSectionResponse struct {
	ID                    int64    `json:"id"`
	SupplyOuterDiameterMM *float64 `json:"supply_outer_diameter_mm"`
	LayingType            *string  `json:"laying_type"`
	UndergroundLayingType *string  `json:"underground_laying_type"`
	SupplyTemperatureC    *float64 `json:"supply_temperature_c"`
	ReturnTemperatureC    *float64 `json:"return_temperature_c"`
	LengthM               *float64 `json:"length_m"`
	ProjectDate           *string  `json:"project_date"`
	QHValue               *float64 `json:"qh_value"`
	QHError               *string  `json:"qh_error,omitempty"`
	Beta                  *float64 `json:"beta"`
	BetaError             *string  `json:"beta_error,omitempty"`
}

type networkSectionsResponse struct {
	HeatNetwork heatNetworkResponse      `json:"heat_network"`
	Sections    []networkSectionResponse `json:"sections"`
}

type qhValueResponse struct {
	NetworkSectionID   int64    `json:"network_section_id"`
	QHTableID          int64    `json:"qh_table_id"`
	QHValueID          int64    `json:"qh_value_id"`
	QHValue            float64  `json:"qh_value"`
	PipelineRole       *string  `json:"pipeline_role,omitempty"`
	SourceInterpolated bool     `json:"source_interpolated"`
	Note               *string  `json:"note,omitempty"`
	MatchedFields      []string `json:"matched_fields"`
}

type errorResponse struct {
	Error string `json:"error"`
}

func newHeatNetworksResponse(
	networks []domain.HeatNetwork,
) heatNetworksResponse {
	response := heatNetworksResponse{
		HeatNetworks: make([]heatNetworkResponse, 0, len(networks)),
	}

	for _, network := range networks {
		response.HeatNetworks = append(
			response.HeatNetworks,
			newHeatNetworkResponse(network),
		)
	}

	return response
}

func newNetworkSectionsResponse(
	result domain.HeatNetworkSections,
) networkSectionsResponse {
	response := networkSectionsResponse{
		HeatNetwork: newHeatNetworkResponse(result.HeatNetwork),
		Sections: make(
			[]networkSectionResponse,
			0,
			len(result.Sections),
		),
	}

	for _, sectionResult := range result.Sections {
		section := sectionResult.Section
		sectionResponse := networkSectionResponse{
			ID:                    section.ID,
			SupplyOuterDiameterMM: section.SupplyOuterDiameter,
			LayingType:            section.LayingType,
			UndergroundLayingType: section.UndergroundLayingType,
			SupplyTemperatureC:    section.SupplyTemperature,
			ReturnTemperatureC:    section.ReturnTemperature,
			LengthM:               section.LengthM,
			QHError:               sectionResult.QHError,
			BetaError:             sectionResult.BetaError,
		}

		if section.ProjectDate != nil {
			value := section.ProjectDate.Format("2006-01-02")
			sectionResponse.ProjectDate = &value
		}

		if sectionResult.QHValue != nil {
			value := sectionResult.QHValue.Value
			sectionResponse.QHValue = &value
		}

		if sectionResult.Beta != nil {
			value := sectionResult.Beta.Value
			sectionResponse.Beta = &value
		}

		response.Sections = append(response.Sections, sectionResponse)
	}

	return response
}

func newHeatNetworkResponse(
	network domain.HeatNetwork,
) heatNetworkResponse {
	return heatNetworkResponse{
		ID:   network.ID,
		Name: network.Name,
	}
}

func newQHValueResponse(match domain.Match) qhValueResponse {
	return qhValueResponse{
		NetworkSectionID:   match.NetworkSectionID,
		QHTableID:          match.QHTableID,
		QHValueID:          match.QHValue.ID,
		QHValue:            match.QHValue.Value,
		PipelineRole:       match.QHValue.PipelineRole,
		SourceInterpolated: match.QHValue.SourceInterpolated,
		Note:               match.QHValue.Note,
		MatchedFields:      match.MatchedFields,
	}
}
