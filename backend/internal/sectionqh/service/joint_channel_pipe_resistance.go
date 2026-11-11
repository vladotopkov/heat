package service

import (
	"fmt"
	"math"

	"lostHeat/internal/sectionqh/domain"
)

const jointChannelNormativeCoefficient = 1.0

type jointChannelNormalizedPipeResistances struct {
	r1 float64
	r2 float64
	r3 float64
	r4 float64
}

// calculateJointChannelNormalizedPipeResistances applies 6.2.1.6 once per
// physical channel. It consumes request-local results from 6.2.1.4 and 6.2.1.5
// and neither queries reference tables nor persists its result.
func calculateJointChannelNormalizedPipeResistances(
	network domain.HeatNetwork,
	qhNorms map[int64]jointChannelQHNorms,
	channelTemperatures map[int64]float64,
) (map[int64]jointChannelNormalizedPipeResistances, error) {
	if len(qhNorms) == 0 && len(channelTemperatures) == 0 {
		return map[int64]jointChannelNormalizedPipeResistances{}, nil
	}

	temperatures := []struct {
		name  string
		value *float64
	}{
		{name: "HeatNetwork.project_supply_temperature_c", value: network.ProjectSupplyTemperature},
		{name: "HeatNetwork.gvs_project_supply_temperature_c", value: network.GVSProjectSupplyTemperature},
		{name: "HeatNetwork.gvs_project_circulation_temperature_c", value: network.GVSProjectCirculationTemperature},
	}
	for _, field := range temperatures {
		if field.value == nil || math.IsNaN(*field.value) || math.IsInf(*field.value, 0) {
			return nil, fmt.Errorf("%s must be non-null and finite", field.name)
		}
	}

	result := make(map[int64]jointChannelNormalizedPipeResistances, len(qhNorms))
	for channelID, norms := range qhNorms {
		tauChannel, exists := channelTemperatures[channelID]
		if !exists {
			return nil, fmt.Errorf(
				"joint_channel_id=%d has no calculated tau_channel",
				channelID,
			)
		}
		if math.IsNaN(tauChannel) || math.IsInf(tauChannel, 0) {
			return nil, fmt.Errorf(
				"joint_channel_id=%d: tau_channel=%g must be finite",
				channelID,
				tauChannel,
			)
		}

		for name, value := range map[string]float64{
			"q1n": norms.q1n,
			"q3n": norms.q3n,
			"q4n": norms.q4n,
		} {
			if math.IsNaN(value) || math.IsInf(value, 0) || value <= 0 {
				return nil, fmt.Errorf(
					"joint_channel_id=%d: %s=%g must be finite and greater than zero",
					channelID,
					name,
					value,
				)
			}
		}

		r1 := (*network.ProjectSupplyTemperature - tauChannel) /
			(jointChannelNormativeCoefficient * norms.q1n)
		r2 := r1
		r3 := (*network.GVSProjectSupplyTemperature - tauChannel) /
			(jointChannelNormativeCoefficient * norms.q3n)
		r4 := (*network.GVSProjectCirculationTemperature - tauChannel) /
			(jointChannelNormativeCoefficient * norms.q4n)

		resistances := jointChannelNormalizedPipeResistances{
			r1: r1,
			r2: r2,
			r3: r3,
			r4: r4,
		}
		for name, value := range map[string]float64{
			"R1_norm": resistances.r1,
			"R2_norm": resistances.r2,
			"R3_norm": resistances.r3,
			"R4_norm": resistances.r4,
		} {
			if math.IsNaN(value) || math.IsInf(value, 0) || value <= 0 {
				return nil, fmt.Errorf(
					"joint_channel_id=%d: calculated %s=%g must be finite and greater than zero",
					channelID,
					name,
					value,
				)
			}
		}
		result[channelID] = resistances
	}

	for channelID := range channelTemperatures {
		if _, exists := qhNorms[channelID]; !exists {
			return nil, fmt.Errorf(
				"joint_channel_id=%d has tau_channel but no calculated q1n, q3n and q4n",
				channelID,
			)
		}
	}

	return result, nil
}
