package service

import (
	"context"
	"fmt"
	"math"
	"time"

	"lostHeat/internal/sectionqh/domain"
)

type jointChannelMonthlyTemperatures struct {
	t1Avg     float64
	t2Avg     float64
	t3Avg     float64
	t4Avg     float64
	groundAvg float64
}

type jointChannelMonthlyCalculationInputs struct {
	channelIDs   map[int64]struct{}
	temperatures jointChannelMonthlyTemperatures
}

// calculateJointChannelMonthlyAirTemperatures applies formula 6.11 for one
// explicitly selected calendar month. The monthly result is request-local and
// is not persisted.
func (s *Service) calculateJointChannelMonthlyAirTemperatures(
	ctx context.Context,
	heatNetworkID int64,
	month time.Time,
	sections []domain.NetworkSection,
	pipeResistances map[int64]jointChannelNormalizedPipeResistances,
	thermalResistances map[int64]jointChannelThermalResistance,
) (map[int64]float64, error) {
	inputs, err := s.loadJointChannelMonthlyCalculationInputs(
		ctx,
		heatNetworkID,
		month,
		sections,
	)
	if err != nil {
		return nil, err
	}

	return calculateJointChannelMonthlyAirTemperatureValues(
		inputs.channelIDs,
		inputs.temperatures,
		pipeResistances,
		thermalResistances,
	)
}

func (s *Service) loadJointChannelMonthlyCalculationInputs(
	ctx context.Context,
	heatNetworkID int64,
	month time.Time,
	sections []domain.NetworkSection,
) (jointChannelMonthlyCalculationInputs, error) {
	channelIDs, err := jointChannelIDsForHeatNetwork(heatNetworkID, sections)
	if err != nil {
		return jointChannelMonthlyCalculationInputs{}, err
	}
	if len(channelIDs) == 0 {
		return jointChannelMonthlyCalculationInputs{channelIDs: channelIDs}, nil
	}

	month, err = normalizeCalculationMonth(month)
	if err != nil {
		return jointChannelMonthlyCalculationInputs{}, err
	}
	rows, err := s.repository.ListTemperaturesForMonth(ctx, heatNetworkID, month)
	if err != nil {
		return jointChannelMonthlyCalculationInputs{}, err
	}
	temperatures, err := selectMonthlyTemperatures(heatNetworkID, month, rows)
	if err != nil {
		return jointChannelMonthlyCalculationInputs{}, err
	}

	return jointChannelMonthlyCalculationInputs{
		channelIDs:   channelIDs,
		temperatures: temperatures,
	}, nil
}

func normalizeCalculationMonth(month time.Time) (time.Time, error) {
	if month.IsZero() {
		return time.Time{}, fmt.Errorf("calculation month is required")
	}
	return time.Date(month.Year(), month.Month(), 1, 0, 0, 0, 0, time.UTC), nil
}

func selectMonthlyTemperatures(
	heatNetworkID int64,
	month time.Time,
	rows []domain.MonthlyTemperature,
) (jointChannelMonthlyTemperatures, error) {
	var heating *domain.MonthlyTemperature
	var gvs *domain.MonthlyTemperature
	for index := range rows {
		row := &rows[index]
		rowMonth := time.Date(row.Month.Year(), row.Month.Month(), 1, 0, 0, 0, 0, time.UTC)
		if row.HeatNetworkID != heatNetworkID {
			return jointChannelMonthlyTemperatures{}, fmt.Errorf(
				"temperature row for month=%s belongs to heat_network_id=%d, want %d",
				rowMonth.Format("2006-01"),
				row.HeatNetworkID,
				heatNetworkID,
			)
		}
		if !rowMonth.Equal(month) {
			return jointChannelMonthlyTemperatures{}, fmt.Errorf(
				"temperature row month=%s differs from calculation month=%s",
				rowMonth.Format("2006-01"),
				month.Format("2006-01"),
			)
		}

		switch row.NetworkType {
		case "HEATING":
			if heating != nil {
				return jointChannelMonthlyTemperatures{}, fmt.Errorf(
					"duplicate temperatures for month=%s network_type=HEATING",
					month.Format("2006-01"),
				)
			}
			heating = row
		case "GVS":
			if gvs != nil {
				return jointChannelMonthlyTemperatures{}, fmt.Errorf(
					"duplicate temperatures for month=%s network_type=GVS",
					month.Format("2006-01"),
				)
			}
			gvs = row
		default:
			return jointChannelMonthlyTemperatures{}, fmt.Errorf(
				"temperature row month=%s has unsupported network_type=%q",
				month.Format("2006-01"),
				row.NetworkType,
			)
		}
	}

	if heating == nil {
		return jointChannelMonthlyTemperatures{}, missingMonthlyTemperatureError(
			heatNetworkID,
			month,
			"HEATING",
		)
	}
	if gvs == nil {
		return jointChannelMonthlyTemperatures{}, missingMonthlyTemperatureError(
			heatNetworkID,
			month,
			"GVS",
		)
	}

	t1, err := requiredMonthlyTemperature(heating.Supply, month, "HEATING", "supply_t")
	if err != nil {
		return jointChannelMonthlyTemperatures{}, err
	}
	t2, err := requiredMonthlyTemperature(heating.Return, month, "HEATING", "return_t")
	if err != nil {
		return jointChannelMonthlyTemperatures{}, err
	}
	ground, err := requiredMonthlyTemperature(heating.Ground, month, "HEATING", "ground_t")
	if err != nil {
		return jointChannelMonthlyTemperatures{}, err
	}
	t3, err := requiredMonthlyTemperature(gvs.Supply, month, "GVS", "supply_t")
	if err != nil {
		return jointChannelMonthlyTemperatures{}, err
	}
	t4, err := requiredMonthlyTemperature(gvs.Return, month, "GVS", "return_t")
	if err != nil {
		return jointChannelMonthlyTemperatures{}, err
	}
	gvsGround, err := requiredMonthlyTemperature(gvs.Ground, month, "GVS", "ground_t")
	if err != nil {
		return jointChannelMonthlyTemperatures{}, err
	}
	if !numbersEqual(ground, gvsGround) {
		return jointChannelMonthlyTemperatures{}, fmt.Errorf(
			"ground_t differs for month=%s: HEATING=%g, GVS=%g",
			month.Format("2006-01"),
			ground,
			gvsGround,
		)
	}

	return jointChannelMonthlyTemperatures{
		t1Avg:     t1,
		t2Avg:     t2,
		t3Avg:     t3,
		t4Avg:     t4,
		groundAvg: ground,
	}, nil
}

func missingMonthlyTemperatureError(
	heatNetworkID int64,
	month time.Time,
	networkType string,
) error {
	return fmt.Errorf(
		"missing temperatures for heat_network_id=%d month=%s network_type=%s",
		heatNetworkID,
		month.Format("2006-01"),
		networkType,
	)
}

func requiredMonthlyTemperature(
	value *float64,
	month time.Time,
	networkType string,
	field string,
) (float64, error) {
	if value == nil || math.IsNaN(*value) || math.IsInf(*value, 0) {
		return 0, fmt.Errorf(
			"missing or invalid %s for month=%s network_type=%s",
			field,
			month.Format("2006-01"),
			networkType,
		)
	}
	return *value, nil
}

func jointChannelIDsForHeatNetwork(
	heatNetworkID int64,
	sections []domain.NetworkSection,
) (map[int64]struct{}, error) {
	pairs := make(map[int64]jointChannelSectionPair)
	for index := range sections {
		section := &sections[index]
		if section.JointChannelID == nil {
			continue
		}
		if section.HeatNetworkID != heatNetworkID {
			return nil, fmt.Errorf(
				"joint_channel_id=%d section id=%d belongs to heat_network_id=%d, want %d",
				*section.JointChannelID,
				section.ID,
				section.HeatNetworkID,
				heatNetworkID,
			)
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

	channelIDs := make(map[int64]struct{}, len(pairs))
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
		if pair.heating.HeatNetworkID != pair.gvs.HeatNetworkID {
			return nil, fmt.Errorf(
				"joint_channel_id=%d HEATING heat_network_id=%d differs from GVS heat_network_id=%d",
				channelID,
				pair.heating.HeatNetworkID,
				pair.gvs.HeatNetworkID,
			)
		}
		channelIDs[channelID] = struct{}{}
	}

	return channelIDs, nil
}

func calculateJointChannelMonthlyAirTemperatureValues(
	channelIDs map[int64]struct{},
	temperatures jointChannelMonthlyTemperatures,
	pipeResistances map[int64]jointChannelNormalizedPipeResistances,
	thermalResistances map[int64]jointChannelThermalResistance,
) (map[int64]float64, error) {
	for name, value := range map[string]float64{
		"t1_avg":     temperatures.t1Avg,
		"t2_avg":     temperatures.t2Avg,
		"t3_avg":     temperatures.t3Avg,
		"t4_avg":     temperatures.t4Avg,
		"ground_avg": temperatures.groundAvg,
	} {
		if math.IsNaN(value) || math.IsInf(value, 0) {
			return nil, fmt.Errorf("%s must be finite", name)
		}
	}

	result := make(map[int64]float64, len(channelIDs))
	for channelID := range channelIDs {
		pipe, exists := pipeResistances[channelID]
		if !exists {
			return nil, fmt.Errorf(
				"joint_channel_id=%d has no calculated R1_norm, R2_norm, R3_norm and R4_norm",
				channelID,
			)
		}
		channel, exists := thermalResistances[channelID]
		if !exists {
			return nil, fmt.Errorf(
				"joint_channel_id=%d has no calculated Rkan",
				channelID,
			)
		}

		for name, value := range map[string]float64{
			"R1_norm": pipe.r1,
			"R2_norm": pipe.r2,
			"R3_norm": pipe.r3,
			"R4_norm": pipe.r4,
			"Rkan":    channel.total,
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

		numerator := temperatures.t1Avg/pipe.r1 +
			temperatures.t2Avg/pipe.r2 +
			temperatures.t3Avg/pipe.r3 +
			temperatures.t4Avg/pipe.r4 +
			temperatures.groundAvg/channel.total
		denominator := 1/pipe.r1 +
			1/pipe.r2 +
			1/pipe.r3 +
			1/pipe.r4 +
			1/channel.total
		if math.IsNaN(numerator) || math.IsInf(numerator, 0) ||
			math.IsNaN(denominator) || math.IsInf(denominator, 0) || denominator <= 0 {
			return nil, fmt.Errorf(
				"joint_channel_id=%d: formula 6.11 numerator or denominator is invalid",
				channelID,
			)
		}

		temperature := numerator / denominator
		if math.IsNaN(temperature) || math.IsInf(temperature, 0) {
			return nil, fmt.Errorf(
				"joint_channel_id=%d: calculated tau_channel_period must be finite",
				channelID,
			)
		}
		result[channelID] = temperature
	}

	return result, nil
}
