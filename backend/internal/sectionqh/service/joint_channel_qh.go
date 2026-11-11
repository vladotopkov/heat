package service

import (
	"fmt"
	"math"

	"lostHeat/internal/sectionqh/domain"
)

const b15TableCode = "Б.15"

type jointChannelQHNorms struct {
	q1n float64
	qn  float64
	q2n float64
	q3n float64
	q4n float64
}

type jointChannelSectionPair struct {
	heating *domain.NetworkSection
	gvs     *domain.NetworkSection
}

// calculateJointChannelQHNorms calculates the five intermediate B.15 norms
// once per physical channel. The result is request-local and is not persisted
// in the database.
func calculateJointChannelQHNorms(
	network domain.HeatNetwork,
	sections []domain.NetworkSection,
	valuesByTableID map[int64][]domain.QHValue,
) (map[int64]jointChannelQHNorms, error) {
	pairs := make(map[int64]jointChannelSectionPair)
	for index := range sections {
		section := &sections[index]
		if section.JointChannelID == nil {
			continue
		}

		channelID := *section.JointChannelID
		pair := pairs[channelID]
		switch section.NetworkType {
		case "HEATING":
			if pair.heating != nil {
				return nil, fmt.Errorf(
					"joint_channel_id=%d has more than one HEATING section",
					channelID,
				)
			}
			pair.heating = section
		case "GVS":
			if pair.gvs != nil {
				return nil, fmt.Errorf(
					"joint_channel_id=%d has more than one GVS section",
					channelID,
				)
			}
			pair.gvs = section
		default:
			return nil, fmt.Errorf(
				"joint_channel_id=%d has unsupported network_type=%q",
				channelID,
				section.NetworkType,
			)
		}
		pairs[channelID] = pair
	}

	result := make(map[int64]jointChannelQHNorms, len(pairs))
	if len(pairs) == 0 {
		return result, nil
	}

	if err := validateJointChannelProjectTemperatures(network); err != nil {
		return nil, err
	}

	for channelID, pair := range pairs {
		if pair.heating == nil || pair.gvs == nil {
			missingType := "HEATING"
			if pair.heating != nil {
				missingType = "GVS"
			}
			return nil, fmt.Errorf(
				"joint_channel_id=%d has no %s section",
				channelID,
				missingType,
			)
		}

		norms, err := calculateJointChannelPairQHNorms(
			network,
			*pair.heating,
			*pair.gvs,
			valuesByTableID,
		)
		if err != nil {
			return nil, fmt.Errorf("joint_channel_id=%d: %w", channelID, err)
		}
		result[channelID] = norms
	}

	return result, nil
}

func calculateJointChannelPairQHNorms(
	network domain.HeatNetwork,
	heating domain.NetworkSection,
	gvs domain.NetworkSection,
	valuesByTableID map[int64][]domain.QHValue,
) (jointChannelQHNorms, error) {
	for _, section := range []domain.NetworkSection{heating, gvs} {
		if normalizeCode(section.QHTableCode) != normalizeCode(b15TableCode) {
			return jointChannelQHNorms{}, fmt.Errorf(
				"section id=%d qh_table_id=%d must reference qh_tables.table_code=%s",
				section.ID,
				section.QHTableID,
				b15TableCode,
			)
		}
		if _, exists := valuesByTableID[section.QHTableID]; !exists {
			return jointChannelQHNorms{}, fmt.Errorf(
				"qh_values for qh_table_id=%d were not loaded",
				section.QHTableID,
			)
		}
	}

	if !positiveFiniteNumber(heating.SupplyOuterDiameter) ||
		!positiveFiniteNumber(heating.ReturnOuterDiameter) {
		return jointChannelQHNorms{}, fmt.Errorf(
			"HEATING section id=%d must have positive finite supply and return outer diameters",
			heating.ID,
		)
	}
	if !numbersEqual(*heating.SupplyOuterDiameter, *heating.ReturnOuterDiameter) {
		return jointChannelQHNorms{}, fmt.Errorf(
			"HEATING section id=%d has different supply_outer_diameter_mm=%g and return_outer_diameter_mm=%g",
			heating.ID,
			*heating.SupplyOuterDiameter,
			*heating.ReturnOuterDiameter,
		)
	}

	heatingValues := valuesByTableID[heating.QHTableID]
	heatingQ50, err := findExactB15QHValue(
		heating.QHTableID,
		heating.SupplyOuterDiameter,
		"RETURN",
		heatingValues,
	)
	if err != nil {
		return jointChannelQHNorms{}, fmt.Errorf("HEATING q50: %w", err)
	}
	heatingQ90, err := findExactB15QHValue(
		heating.QHTableID,
		heating.SupplyOuterDiameter,
		"SUPPLY",
		heatingValues,
	)
	if err != nil {
		return jointChannelQHNorms{}, fmt.Errorf("HEATING q90: %w", err)
	}
	qn, err := findExactB15QHValue(
		heating.QHTableID,
		heating.SupplyOuterDiameter,
		"TWO_PIPE_TOTAL",
		heatingValues,
	)
	if err != nil {
		return jointChannelQHNorms{}, fmt.Errorf("HEATING qn: %w", err)
	}

	q1n := heatingQ50 + (heatingQ90-heatingQ50)*
		(*network.ProjectSupplyTemperature-50)/(90-50)
	q2n := qn - q1n

	gvsValues := valuesByTableID[gvs.QHTableID]
	gvsQ50, err := findExactB15QHValue(
		gvs.QHTableID,
		gvs.SupplyOuterDiameter,
		"RETURN",
		gvsValues,
	)
	if err != nil {
		return jointChannelQHNorms{}, fmt.Errorf("GVS supply q50: %w", err)
	}
	gvsQ90, err := findExactB15QHValue(
		gvs.QHTableID,
		gvs.SupplyOuterDiameter,
		"SUPPLY",
		gvsValues,
	)
	if err != nil {
		return jointChannelQHNorms{}, fmt.Errorf("GVS supply q90: %w", err)
	}
	q65 := gvsQ50 + (gvsQ90-gvsQ50)*(65-50)/(90-50)
	q3n := gvsQ50 + (q65-gvsQ50)*
		(*network.GVSProjectSupplyTemperature-50)/(65-50)

	q4n, err := findExactB15QHValue(
		gvs.QHTableID,
		gvs.ReturnOuterDiameter,
		"RETURN",
		gvsValues,
	)
	if err != nil {
		return jointChannelQHNorms{}, fmt.Errorf("GVS circulation q50: %w", err)
	}

	norms := jointChannelQHNorms{q1n: q1n, qn: qn, q2n: q2n, q3n: q3n, q4n: q4n}
	for name, value := range map[string]float64{
		"q1n": norms.q1n,
		"qn":  norms.qn,
		"q2n": norms.q2n,
		"q3n": norms.q3n,
		"q4n": norms.q4n,
	} {
		if math.IsNaN(value) || math.IsInf(value, 0) || value < 0 {
			return jointChannelQHNorms{}, fmt.Errorf(
				"calculated %s=%g must be finite and non-negative",
				name,
				value,
			)
		}
	}

	return norms, nil
}

func validateJointChannelProjectTemperatures(network domain.HeatNetwork) error {
	values := []struct {
		name  string
		value *float64
	}{
		{name: "HeatNetwork.project_supply_temperature_c", value: network.ProjectSupplyTemperature},
		{name: "HeatNetwork.project_return_temperature_c", value: network.ProjectReturnTemperature},
		{name: "HeatNetwork.gvs_project_supply_temperature_c", value: network.GVSProjectSupplyTemperature},
		{name: "HeatNetwork.gvs_project_circulation_temperature_c", value: network.GVSProjectCirculationTemperature},
	}
	for _, field := range values {
		if field.value == nil || math.IsNaN(*field.value) || math.IsInf(*field.value, 0) {
			return fmt.Errorf("%s must be non-null and finite", field.name)
		}
	}

	if *network.ProjectSupplyTemperature < 50 || *network.ProjectSupplyTemperature > 90 {
		return fmt.Errorf(
			"HeatNetwork.project_supply_temperature_c=%g must be between 50 and 90 for B.15 interpolation",
			*network.ProjectSupplyTemperature,
		)
	}
	if !numbersEqual(*network.ProjectReturnTemperature, 50) {
		return fmt.Errorf(
			"HeatNetwork.project_return_temperature_c=%g must equal 50 for the q2n=qn-q1n method",
			*network.ProjectReturnTemperature,
		)
	}
	if *network.GVSProjectSupplyTemperature < 50 || *network.GVSProjectSupplyTemperature > 65 {
		return fmt.Errorf(
			"HeatNetwork.gvs_project_supply_temperature_c=%g must be between 50 and 65 for B.15 interpolation",
			*network.GVSProjectSupplyTemperature,
		)
	}
	if !numbersEqual(*network.GVSProjectCirculationTemperature, 50) {
		return fmt.Errorf(
			"HeatNetwork.gvs_project_circulation_temperature_c=%g must equal 50 for q4n",
			*network.GVSProjectCirculationTemperature,
		)
	}

	return nil
}

func findExactB15QHValue(
	tableID int64,
	diameter *float64,
	role string,
	values []domain.QHValue,
) (float64, error) {
	if !positiveFiniteNumber(diameter) {
		return 0, fmt.Errorf(
			"%w: qh_table_id=%d role=%s requires a positive finite outer diameter",
			domain.ErrQHValueNotFound,
			tableID,
			role,
		)
	}

	var found *domain.QHValue
	for index := range values {
		value := &values[index]
		if value.QHTableID != tableID ||
			value.OuterDiameterMM == nil ||
			!numbersEqual(*value.OuterDiameterMM, *diameter) ||
			value.PipelineRole == nil ||
			normalizeCode(*value.PipelineRole) != role {
			continue
		}
		if found != nil {
			return 0, fmt.Errorf(
				"%w: qh_table_id=%d outer_diameter_mm=%g pipeline_role=%s, rows id=%d and id=%d",
				domain.ErrAmbiguousQHValue,
				tableID,
				*diameter,
				role,
				found.ID,
				value.ID,
			)
		}
		found = value
	}
	if found == nil {
		return 0, fmt.Errorf(
			"%w: qh_table_id=%d outer_diameter_mm=%g pipeline_role=%s",
			domain.ErrQHValueNotFound,
			tableID,
			*diameter,
			role,
		)
	}
	if math.IsNaN(found.Value) || math.IsInf(found.Value, 0) || found.Value < 0 {
		return 0, fmt.Errorf(
			"qh_value id=%d must be finite and non-negative",
			found.ID,
		)
	}

	return found.Value, nil
}

func positiveFiniteNumber(value *float64) bool {
	return value != nil && !math.IsNaN(*value) && !math.IsInf(*value, 0) && *value > 0
}
