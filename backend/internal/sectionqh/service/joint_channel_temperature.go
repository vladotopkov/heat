package service

import (
	"fmt"
	"math"

	"lostHeat/internal/sectionqh/domain"
)

const jointChannelQ2NForAirTemperature = 0.0

// calculateJointChannelAirTemperatures applies formula 6.6 once per physical
// channel. It consumes the intermediate results already calculated for that
// channel and does not query qh_values again.
func calculateJointChannelAirTemperatures(
	network domain.HeatNetwork,
	qhNorms map[int64]jointChannelQHNorms,
	thermalResistances map[int64]jointChannelThermalResistance,
) (map[int64]float64, error) {
	if len(qhNorms) == 0 && len(thermalResistances) == 0 {
		return map[int64]float64{}, nil
	}
	if network.ProjectGroundTemperature == nil ||
		math.IsNaN(*network.ProjectGroundTemperature) ||
		math.IsInf(*network.ProjectGroundTemperature, 0) {
		return nil, fmt.Errorf(
			"HeatNetwork.project_ground_temperature_c must be non-null and finite",
		)
	}

	result := make(map[int64]float64, len(qhNorms))
	for channelID, norms := range qhNorms {
		resistance, exists := thermalResistances[channelID]
		if !exists {
			return nil, fmt.Errorf(
				"joint_channel_id=%d has no calculated Rkan",
				channelID,
			)
		}

		for name, value := range map[string]float64{
			"q1n": norms.q1n,
			"q3n": norms.q3n,
			"q4n": norms.q4n,
		} {
			if math.IsNaN(value) || math.IsInf(value, 0) || value < 0 {
				return nil, fmt.Errorf(
					"joint_channel_id=%d: %s=%g must be finite and non-negative",
					channelID,
					name,
					value,
				)
			}
		}
		if math.IsNaN(resistance.total) || math.IsInf(resistance.total, 0) ||
			resistance.total <= 0 {
			return nil, fmt.Errorf(
				"joint_channel_id=%d: Rkan=%g must be finite and greater than zero",
				channelID,
				resistance.total,
			)
		}

		totalNorm := norms.q1n + jointChannelQ2NForAirTemperature + norms.q3n + norms.q4n
		temperature := *network.ProjectGroundTemperature + totalNorm*resistance.total
		if math.IsNaN(temperature) || math.IsInf(temperature, 0) {
			return nil, fmt.Errorf(
				"joint_channel_id=%d: calculated tau_channel must be finite",
				channelID,
			)
		}
		result[channelID] = temperature
	}

	for channelID := range thermalResistances {
		if _, exists := qhNorms[channelID]; !exists {
			return nil, fmt.Errorf(
				"joint_channel_id=%d has no calculated q1n, q3n and q4n",
				channelID,
			)
		}
	}

	return result, nil
}
