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
	NetworkType           string   `json:"network_type"`
	JointChannelID        *int64   `json:"joint_channel_id"`
	SectionName           *string  `json:"section_name"`
	SupplyOuterDiameterMM *float64 `json:"supply_outer_diameter_mm"`
	LayingType            *string  `json:"laying_type"`
	UndergroundLayingType *string  `json:"underground_laying_type"`
	SupplyTemperatureC    *float64 `json:"supply_temperature_c"`
	ReturnTemperatureC    *float64 `json:"return_temperature_c"`
	LengthM               *float64 `json:"length_m"`
	ProjectDate           *string  `json:"project_date"`
	QHValue               *float64 `json:"qh_value"`
	QHSupply              *float64 `json:"qh_supply"`
	QHReturn              *float64 `json:"qh_return"`
	QHError               *string  `json:"qh_error,omitempty"`
	Beta                  *float64 `json:"beta"`
	BetaError             *string  `json:"beta_error,omitempty"`
	Q1N                   *float64 `json:"q1n"`
	Q2N                   *float64 `json:"q2n"`
	Q3N                   *float64 `json:"q3n"`
	Q4N                   *float64 `json:"q4n"`
	R1Norm                *float64 `json:"r1_norm"`
	R2Norm                *float64 `json:"r2_norm"`
	R3Norm                *float64 `json:"r3_norm"`
	R4Norm                *float64 `json:"r4_norm"`
	Q1NormPeriod          *float64 `json:"q1_norm_period"`
	Q2NormPeriod          *float64 `json:"q2_norm_period"`
	Q3NormPeriod          *float64 `json:"q3_norm_period"`
	Q4NormPeriod          *float64 `json:"q4_norm_period"`
	QSupplyNormPeriod     *float64 `json:"Q_supply_norm_period"`
	QReturnNormPeriod     *float64 `json:"Q_return_norm_period"`
	JointCalculationError *string  `json:"joint_calculation_error,omitempty"`
}

type networkSectionsResponse struct {
	HeatNetwork      heatNetworkResponse      `json:"heat_network"`
	CalculationMonth *string                  `json:"calculation_month"`
	JointChannels    []jointChannelResponse   `json:"joint_channels"`
	Sections         []networkSectionResponse `json:"sections"`
}

type jointChannelResponse struct {
	ID               int64    `json:"id"`
	Rkgr             *float64 `json:"rkgr"`
	RvK              *float64 `json:"rv_k"`
	Rkan             *float64 `json:"rkan"`
	TauChannel       *float64 `json:"tau_channel"`
	TauChannelPeriod *float64 `json:"tau_channel_period"`
	CalculationError *string  `json:"calculation_error,omitempty"`
}

type qhValueResponse struct {
	NetworkSectionID   int64    `json:"network_section_id"`
	QHTableID          int64    `json:"qh_table_id"`
	QHValueID          *int64   `json:"qh_value_id"`
	QHValue            float64  `json:"qh_value"`
	QHSupply           *float64 `json:"qh_supply"`
	QHReturn           *float64 `json:"qh_return"`
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
		JointChannels: make(
			[]jointChannelResponse,
			0,
			len(result.JointChannels),
		),
		Sections: make(
			[]networkSectionResponse,
			0,
			len(result.Sections),
		),
	}
	if result.CalculationMonth != nil {
		value := result.CalculationMonth.Format("2006-01")
		response.CalculationMonth = &value
	}
	for _, calculation := range result.JointChannels {
		response.JointChannels = append(response.JointChannels, jointChannelResponse{
			ID:               calculation.ID,
			Rkgr:             calculation.Rkgr,
			RvK:              calculation.RvK,
			Rkan:             calculation.Rkan,
			TauChannel:       calculation.TauChannel,
			TauChannelPeriod: calculation.TauChannelPeriod,
			CalculationError: calculation.CalculationError,
		})
	}

	for _, sectionResult := range result.Sections {
		section := sectionResult.Section
		sectionResponse := networkSectionResponse{
			ID:                    section.ID,
			NetworkType:           section.NetworkType,
			JointChannelID:        section.JointChannelID,
			SectionName:           section.SectionName,
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
			sectionResponse.QHSupply = sectionResult.QHValue.SupplyValue
			sectionResponse.QHReturn = sectionResult.QHValue.ReturnValue
		}

		if sectionResult.Beta != nil {
			value := sectionResult.Beta.Value
			sectionResponse.Beta = &value
		}
		if calculation := sectionResult.JointCalculation; calculation != nil {
			sectionResponse.Q1N = calculation.Q1N
			sectionResponse.Q2N = calculation.Q2N
			sectionResponse.Q3N = calculation.Q3N
			sectionResponse.Q4N = calculation.Q4N
			sectionResponse.R1Norm = calculation.R1Norm
			sectionResponse.R2Norm = calculation.R2Norm
			sectionResponse.R3Norm = calculation.R3Norm
			sectionResponse.R4Norm = calculation.R4Norm
			sectionResponse.Q1NormPeriod = calculation.Q1NormPeriod
			sectionResponse.Q2NormPeriod = calculation.Q2NormPeriod
			sectionResponse.Q3NormPeriod = calculation.Q3NormPeriod
			sectionResponse.Q4NormPeriod = calculation.Q4NormPeriod
			switch section.NetworkType {
			case "HEATING":
				sectionResponse.QSupplyNormPeriod = calculation.Q1HeatLossNormPeriod
				sectionResponse.QReturnNormPeriod = calculation.Q2HeatLossNormPeriod
			case "GVS":
				sectionResponse.QSupplyNormPeriod = calculation.Q3HeatLossNormPeriod
				sectionResponse.QReturnNormPeriod = calculation.Q4HeatLossNormPeriod
			}
			sectionResponse.JointCalculationError = calculation.CalculationError
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
	var sourceID *int64
	if match.QHValue.ID != 0 {
		sourceID = &match.QHValue.ID
	}
	return qhValueResponse{
		NetworkSectionID:   match.NetworkSectionID,
		QHTableID:          match.QHTableID,
		QHValueID:          sourceID,
		QHValue:            match.QHValue.Value,
		QHSupply:           match.QHValue.SupplyValue,
		QHReturn:           match.QHValue.ReturnValue,
		PipelineRole:       match.QHValue.PipelineRole,
		SourceInterpolated: match.QHValue.SourceInterpolated,
		Note:               match.QHValue.Note,
		MatchedFields:      match.MatchedFields,
	}
}
