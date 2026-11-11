package service

import (
	"fmt"
	"math"

	"lostHeat/internal/sectionqh/domain"
)

const (
	groundSurfaceHeatTransferCoefficient = 17.0
	channelAirHeatTransferCoefficient    = 11.0
)

type jointChannelGroundInput struct {
	burialDepthM   *float64
	heightM        *float64
	widthM         *float64
	coverThickness *float64
	groundLambda   *float64
}

type jointChannelThermalResistance struct {
	ground    float64
	airToWall float64
	total     float64
}

// calculateJointChannelThermalResistances calculates Rkgr, Rv.k and Rkan once
// for every physical channel. The returned values live only during the current
// request and are never persisted.
func calculateJointChannelThermalResistances(
	sections []domain.NetworkSection,
) (map[int64]jointChannelThermalResistance, error) {
	inputs := make(map[int64]jointChannelGroundInput)

	for _, section := range sections {
		if section.JointChannelID == nil {
			continue
		}

		channelID := *section.JointChannelID
		input, exists := inputs[channelID]
		if !exists {
			input = jointChannelGroundInput{
				heightM:        section.JointChannelHeightM,
				widthM:         section.JointChannelWidthM,
				coverThickness: section.JointChannelCoverThicknessM,
				groundLambda:   section.JointChannelGroundLambda,
			}
		}
		if section.NetworkType == "HEATING" {
			if input.burialDepthM != nil {
				return nil, fmt.Errorf(
					"joint_channel_id=%d has more than one HEATING section",
					channelID,
				)
			}
			input.burialDepthM = section.BurialDepthM
		}
		inputs[channelID] = input
	}

	result := make(map[int64]jointChannelThermalResistance, len(inputs))
	for channelID, input := range inputs {
		ground, err := calculateJointChannelGroundResistance(input)
		if err != nil {
			return nil, fmt.Errorf("joint_channel_id=%d: %w", channelID, err)
		}
		airToWall, err := calculateJointChannelAirToWallResistance(input.widthM, input.heightM)
		if err != nil {
			return nil, fmt.Errorf("joint_channel_id=%d: %w", channelID, err)
		}
		total := ground + airToWall
		if math.IsNaN(total) || math.IsInf(total, 0) || total <= 0 {
			return nil, fmt.Errorf(
				"joint_channel_id=%d: calculated Rkan must be finite and greater than zero",
				channelID,
			)
		}
		result[channelID] = jointChannelThermalResistance{
			ground:    ground,
			airToWall: airToWall,
			total:     total,
		}
	}

	return result, nil
}

func calculateJointChannelAirToWallResistance(widthM, heightM *float64) (float64, error) {
	values := []struct {
		name  string
		value *float64
	}{
		{name: "JointChannel.width_m", value: widthM},
		{name: "JointChannel.height_m", value: heightM},
	}
	for _, field := range values {
		if field.value == nil || math.IsNaN(*field.value) ||
			math.IsInf(*field.value, 0) || *field.value <= 0 {
			return 0, fmt.Errorf("%s must be non-null, finite and greater than zero", field.name)
		}
	}

	width := *widthM
	height := *heightM
	equivalentSize := 2 * width * height / (width + height)
	resistance := 1 / (math.Pi * channelAirHeatTransferCoefficient * equivalentSize)
	if math.IsNaN(resistance) || math.IsInf(resistance, 0) || resistance <= 0 {
		return 0, fmt.Errorf("calculated Rv.k must be finite and greater than zero")
	}

	return resistance, nil
}

func calculateJointChannelGroundResistance(
	input jointChannelGroundInput,
) (float64, error) {
	values := []struct {
		name  string
		value *float64
	}{
		{name: "NetworkSection.burial_depth_m", value: input.burialDepthM},
		{name: "JointChannel.height_m", value: input.heightM},
		{name: "JointChannel.width_m", value: input.widthM},
		{name: "JointChannel.cover_thickness_m", value: input.coverThickness},
		{name: "JointChannel.ground_lambda", value: input.groundLambda},
	}
	for _, field := range values {
		if field.value == nil || math.IsNaN(*field.value) ||
			math.IsInf(*field.value, 0) || *field.value <= 0 {
			return 0, fmt.Errorf("%s must be non-null, finite and greater than zero", field.name)
		}
	}

	burialDepth := *input.burialDepthM
	height := *input.heightM
	width := *input.widthM
	groundLambda := *input.groundLambda

	calculationDepth := burialDepth + *input.coverThickness + height/2
	if burialDepth <= 0.7 {
		calculationDepth += groundLambda / groundSurfaceHeatTransferCoefficient
	}

	logArgument := 3.5 * calculationDepth / height * math.Pow(height/width, 0.25)
	denominator := (5.7 + 0.5*width/height) * groundLambda
	if logArgument <= 0 || denominator <= 0 {
		return 0, fmt.Errorf("Rkgr formula domain is invalid")
	}

	resistance := math.Log(logArgument) / denominator
	if math.IsNaN(resistance) || math.IsInf(resistance, 0) || resistance <= 0 {
		return 0, fmt.Errorf("calculated Rkgr must be finite and greater than zero")
	}

	return resistance, nil
}
