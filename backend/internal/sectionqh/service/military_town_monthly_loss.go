package service

import (
	"context"
	"fmt"
	"math"
	"time"

	"lostHeat/internal/sectionqh/domain"
)

const gigajoulesPerKilojoule = 1e-6

// TotalHeatLossForMonth calculates the Military Town total without counting
// joint sections twice: separate NetworkSection rows plus one total per
// physical JointChannel.
func (s *Service) TotalHeatLossForMonth(
	ctx context.Context,
	heatNetworkID int64,
	month time.Time,
) (float64, *string, error) {
	if heatNetworkID != militaryTownHeatNetworkID {
		return 0, nil, fmt.Errorf(
			"monthly section/channel calculation is only supported for heat_network_id=%d",
			militaryTownHeatNetworkID,
		)
	}

	month, err := normalizeCalculationMonth(month)
	if err != nil {
		return 0, nil, err
	}
	result, err := s.ListNetworkSectionsForMonth(ctx, heatNetworkID, month)
	if err != nil {
		return 0, nil, err
	}

	rows, err := s.repository.ListTemperaturesForMonth(ctx, heatNetworkID, month)
	if err != nil {
		return 0, nil, err
	}
	temperatures, err := selectMonthlyTemperatures(heatNetworkID, month, rows)
	if err != nil {
		return 0, errorReason(err), nil
	}
	uptimeHours, err := s.repository.GetUptimeHoursForMonth(ctx, heatNetworkID, month)
	if err != nil {
		return 0, nil, err
	}
	if uptimeHours == nil {
		return 0, errorReason(fmt.Errorf(
			"missing up_time for heat_network_id=%d month=%s",
			heatNetworkID,
			month.Format("2006-01"),
		)), nil
	}
	if *uptimeHours < 0 {
		return 0, errorReason(fmt.Errorf(
			"up_time.hours_per_month=%d must be non-negative",
			*uptimeHours,
		)), nil
	}

	var separateTotal float64
	for _, section := range result.Sections {
		if section.Section.JointChannelID != nil {
			continue
		}
		loss, err := calculateMilitaryTownSeparateSectionMonthlyLoss(
			result.HeatNetwork,
			section,
			temperatures,
			*uptimeHours,
		)
		if err != nil {
			return 0, errorReason(fmt.Errorf(
				"NetworkSection id=%d: %w",
				section.Section.ID,
				err,
			)), nil
		}
		separateTotal += loss
	}

	var jointTotal float64
	for _, channel := range result.JointChannels {
		values := []*float64{
			channel.Q1HeatLossNormPeriod,
			channel.Q2HeatLossNormPeriod,
			channel.Q3HeatLossNormPeriod,
			channel.Q4HeatLossNormPeriod,
		}
		for index, value := range values {
			if value == nil {
				reason := "required monthly heat loss is missing"
				if channel.CalculationError != nil {
					reason = *channel.CalculationError
				}
				return 0, errorReason(fmt.Errorf(
					"JointChannel id=%d Q%d_norm_period: %s",
					channel.ID,
					index+1,
					reason,
				)), nil
			}
			if math.IsNaN(*value) || math.IsInf(*value, 0) {
				return 0, errorReason(fmt.Errorf(
					"JointChannel id=%d Q%d_norm_period must be finite",
					channel.ID,
					index+1,
				)), nil
			}
			jointTotal += *value
		}
	}

	total := separateTotal + jointTotal
	if math.IsNaN(total) || math.IsInf(total, 0) {
		return 0, errorReason(fmt.Errorf("calculated monthly network loss must be finite")), nil
	}
	return total, nil, nil
}

func calculateMilitaryTownSeparateSectionMonthlyLoss(
	network domain.HeatNetwork,
	section domain.NetworkSectionWithQH,
	temperatures jointChannelMonthlyTemperatures,
	uptimeHours int,
) (float64, error) {
	if section.QHValue == nil {
		return 0, fmt.Errorf("qh is missing")
	}
	if section.Beta == nil {
		return 0, fmt.Errorf("beta is missing")
	}
	if !positiveFiniteNumber(section.Section.LengthM) {
		return 0, fmt.Errorf("length_m must be non-null, finite and greater than zero")
	}
	if uptimeHours < 0 {
		return 0, fmt.Errorf("up_time.hours_per_month must be non-negative")
	}

	var projectSupply, projectReturn *float64
	var actualSupply, actualReturn float64
	switch section.Section.NetworkType {
	case "HEATING":
		projectSupply = network.ProjectSupplyTemperature
		projectReturn = network.ProjectReturnTemperature
		actualSupply = temperatures.t1Avg
		actualReturn = temperatures.t2Avg
	case "GVS":
		projectSupply = network.GVSProjectSupplyTemperature
		projectReturn = network.GVSProjectCirculationTemperature
		actualSupply = temperatures.t3Avg
		actualReturn = temperatures.t4Avg
	default:
		return 0, fmt.Errorf("unsupported network_type=%q", section.Section.NetworkType)
	}
	if projectSupply == nil || projectReturn == nil || network.ProjectGroundTemperature == nil {
		return 0, fmt.Errorf("project temperatures are missing")
	}

	projectDifference := *projectSupply + *projectReturn - 2**network.ProjectGroundTemperature
	if math.IsNaN(projectDifference) || math.IsInf(projectDifference, 0) ||
		math.Abs(projectDifference) < 1e-9 {
		return 0, fmt.Errorf("project temperature difference is invalid")
	}
	actualDifference := actualSupply + actualReturn - 2*temperatures.groundAvg

	normalizedPerHour := 3.6 * section.QHValue.Value *
		section.Beta.Value * *section.Section.LengthM
	loss := normalizedPerHour * actualDifference / projectDifference *
		float64(uptimeHours) * gigajoulesPerKilojoule
	if math.IsNaN(loss) || math.IsInf(loss, 0) {
		return 0, fmt.Errorf("calculated monthly loss must be finite")
	}
	return loss, nil
}

func errorReason(err error) *string {
	message := err.Error()
	return &message
}
