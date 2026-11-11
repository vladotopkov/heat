package service

import (
	"context"
	"fmt"
	"math"
	"time"

	"lostHeat/internal/sectionqh/domain"
)

type jointChannelMonthlyNormalizedHeatFlows struct {
	q1 float64
	q2 float64
	q3 float64
	q4 float64
}

// calculateJointChannelMonthlyNormalizedHeatFlows runs formulas 6.11 and 6.13
// for one selected month using a single temperatures query. The final values
// remain request-local and are not persisted.
func (s *Service) calculateJointChannelMonthlyNormalizedHeatFlows(
	ctx context.Context,
	heatNetworkID int64,
	month time.Time,
	sections []domain.NetworkSection,
	pipeResistances map[int64]jointChannelNormalizedPipeResistances,
	thermalResistances map[int64]jointChannelThermalResistance,
) (map[int64]jointChannelMonthlyNormalizedHeatFlows, error) {
	inputs, err := s.loadJointChannelMonthlyCalculationInputs(
		ctx,
		heatNetworkID,
		month,
		sections,
	)
	if err != nil {
		return nil, err
	}
	channelTemperatures, err := calculateJointChannelMonthlyAirTemperatureValues(
		inputs.channelIDs,
		inputs.temperatures,
		pipeResistances,
		thermalResistances,
	)
	if err != nil {
		return nil, err
	}

	return calculateJointChannelMonthlyNormalizedHeatFlowValues(
		inputs.channelIDs,
		inputs.temperatures,
		channelTemperatures,
		pipeResistances,
	)
}

func calculateJointChannelMonthlyNormalizedHeatFlowValues(
	channelIDs map[int64]struct{},
	temperatures jointChannelMonthlyTemperatures,
	channelTemperatures map[int64]float64,
	pipeResistances map[int64]jointChannelNormalizedPipeResistances,
) (map[int64]jointChannelMonthlyNormalizedHeatFlows, error) {
	for name, value := range map[string]float64{
		"t1_month": temperatures.t1Avg,
		"t2_month": temperatures.t2Avg,
		"t3_month": temperatures.t3Avg,
		"t4_month": temperatures.t4Avg,
	} {
		if math.IsNaN(value) || math.IsInf(value, 0) {
			return nil, fmt.Errorf("%s must be finite", name)
		}
	}

	result := make(map[int64]jointChannelMonthlyNormalizedHeatFlows, len(channelIDs))
	for channelID := range channelIDs {
		tauChannelPeriod, exists := channelTemperatures[channelID]
		if !exists {
			return nil, fmt.Errorf(
				"joint_channel_id=%d has no calculated tau_channel_period",
				channelID,
			)
		}
		if math.IsNaN(tauChannelPeriod) || math.IsInf(tauChannelPeriod, 0) {
			return nil, fmt.Errorf(
				"joint_channel_id=%d: tau_channel_period=%g must be finite",
				channelID,
				tauChannelPeriod,
			)
		}

		pipe, exists := pipeResistances[channelID]
		if !exists {
			return nil, fmt.Errorf(
				"joint_channel_id=%d has no calculated R1_norm, R2_norm, R3_norm and R4_norm",
				channelID,
			)
		}
		for name, value := range map[string]float64{
			"R1_norm": pipe.r1,
			"R2_norm": pipe.r2,
			"R3_norm": pipe.r3,
			"R4_norm": pipe.r4,
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

		flows := jointChannelMonthlyNormalizedHeatFlows{
			q1: (temperatures.t1Avg - tauChannelPeriod) / pipe.r1,
			q2: (temperatures.t2Avg - tauChannelPeriod) / pipe.r2,
			q3: (temperatures.t3Avg - tauChannelPeriod) / pipe.r3,
			q4: (temperatures.t4Avg - tauChannelPeriod) / pipe.r4,
		}
		for name, value := range map[string]float64{
			"q1_norm_period": flows.q1,
			"q2_norm_period": flows.q2,
			"q3_norm_period": flows.q3,
			"q4_norm_period": flows.q4,
		} {
			if math.IsNaN(value) || math.IsInf(value, 0) {
				return nil, fmt.Errorf(
					"joint_channel_id=%d: calculated %s must be finite",
					channelID,
					name,
				)
			}
		}
		result[channelID] = flows
	}

	return result, nil
}
