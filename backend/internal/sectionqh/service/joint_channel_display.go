package service

import (
	"context"
	"fmt"
	"sort"
	"time"

	"lostHeat/internal/sectionqh/domain"
)

func (s *Service) calculateJointChannelDisplayCalculations(
	ctx context.Context,
	network domain.HeatNetwork,
	sections []domain.NetworkSection,
	valuesByTableID map[int64][]domain.QHValue,
	month *time.Time,
) ([]domain.JointChannelCalculation, error) {
	sectionsByChannel := make(map[int64][]domain.NetworkSection)
	for _, section := range sections {
		if section.JointChannelID == nil {
			continue
		}
		channelID := *section.JointChannelID
		sectionsByChannel[channelID] = append(sectionsByChannel[channelID], section)
	}

	channelIDs := make([]int64, 0, len(sectionsByChannel))
	for channelID := range sectionsByChannel {
		channelIDs = append(channelIDs, channelID)
	}
	sort.Slice(channelIDs, func(i, j int) bool { return channelIDs[i] < channelIDs[j] })

	var monthlyTemperatures jointChannelMonthlyTemperatures
	var monthlyDataError error
	var uptimeHours *int
	var uptimeDataError error
	if month != nil && len(channelIDs) > 0 {
		rows, err := s.repository.ListTemperaturesForMonth(ctx, network.ID, *month)
		if err != nil {
			return nil, fmt.Errorf("list temperatures for month %s: %w", month.Format("2006-01"), err)
		}
		monthlyTemperatures, monthlyDataError = selectMonthlyTemperatures(network.ID, *month, rows)

		uptimeHours, err = s.repository.GetUptimeHoursForMonth(ctx, network.ID, *month)
		if err != nil {
			return nil, fmt.Errorf("get uptime for month %s: %w", month.Format("2006-01"), err)
		}
		if uptimeHours == nil {
			uptimeDataError = fmt.Errorf(
				"missing up_time for heat_network_id=%d month=%s",
				network.ID,
				month.Format("2006-01"),
			)
		}
	}

	calculations := make([]domain.JointChannelCalculation, 0, len(channelIDs))
	for _, channelID := range channelIDs {
		calculation := domain.JointChannelCalculation{ID: channelID}
		channelSections := sectionsByChannel[channelID]

		thermalResistances, err := calculateJointChannelThermalResistances(channelSections)
		if err != nil {
			setJointCalculationError(&calculation, err)
			calculations = append(calculations, calculation)
			continue
		}
		thermal := thermalResistances[channelID]
		calculation.Rkgr = float64Pointer(thermal.ground)
		calculation.RvK = float64Pointer(thermal.airToWall)
		calculation.Rkan = float64Pointer(thermal.total)

		qhNorms, err := calculateJointChannelQHNorms(network, channelSections, valuesByTableID)
		if err != nil {
			setJointCalculationError(&calculation, err)
			calculations = append(calculations, calculation)
			continue
		}
		norms := qhNorms[channelID]
		calculation.Q1N = float64Pointer(norms.q1n)
		calculation.Q2N = float64Pointer(norms.q2n)
		calculation.Q3N = float64Pointer(norms.q3n)
		calculation.Q4N = float64Pointer(norms.q4n)

		tauByChannel, err := calculateJointChannelAirTemperatures(
			network,
			qhNorms,
			thermalResistances,
		)
		if err != nil {
			setJointCalculationError(&calculation, err)
			calculations = append(calculations, calculation)
			continue
		}
		calculation.TauChannel = float64Pointer(tauByChannel[channelID])

		pipeResistances, err := calculateJointChannelNormalizedPipeResistances(
			network,
			qhNorms,
			tauByChannel,
		)
		if err != nil {
			setJointCalculationError(&calculation, err)
			calculations = append(calculations, calculation)
			continue
		}
		pipe := pipeResistances[channelID]
		calculation.R1Norm = float64Pointer(pipe.r1)
		calculation.R2Norm = float64Pointer(pipe.r2)
		calculation.R3Norm = float64Pointer(pipe.r3)
		calculation.R4Norm = float64Pointer(pipe.r4)

		if month == nil {
			calculations = append(calculations, calculation)
			continue
		}
		if monthlyDataError != nil {
			setJointCalculationError(&calculation, monthlyDataError)
			calculations = append(calculations, calculation)
			continue
		}

		onlyThisChannel := map[int64]struct{}{channelID: {}}
		tauPeriodByChannel, err := calculateJointChannelMonthlyAirTemperatureValues(
			onlyThisChannel,
			monthlyTemperatures,
			pipeResistances,
			thermalResistances,
		)
		if err != nil {
			setJointCalculationError(&calculation, err)
			calculations = append(calculations, calculation)
			continue
		}
		calculation.TauChannelPeriod = float64Pointer(tauPeriodByChannel[channelID])

		flowsByChannel, err := calculateJointChannelMonthlyNormalizedHeatFlowValues(
			onlyThisChannel,
			monthlyTemperatures,
			tauPeriodByChannel,
			pipeResistances,
		)
		if err != nil {
			setJointCalculationError(&calculation, err)
			calculations = append(calculations, calculation)
			continue
		}
		flows := flowsByChannel[channelID]
		calculation.Q1NormPeriod = float64Pointer(flows.q1)
		calculation.Q2NormPeriod = float64Pointer(flows.q2)
		calculation.Q3NormPeriod = float64Pointer(flows.q3)
		calculation.Q4NormPeriod = float64Pointer(flows.q4)
		if uptimeDataError != nil {
			setJointCalculationError(&calculation, uptimeDataError)
			calculations = append(calculations, calculation)
			continue
		}

		var heatingLengthM *float64
		var gvsLengthM *float64
		for index := range channelSections {
			section := &channelSections[index]
			switch section.NetworkType {
			case "HEATING":
				heatingLengthM = section.LengthM
			case "GVS":
				gvsLengthM = section.LengthM
			}
		}
		losses, err := calculateJointChannelMonthlyNormalizedLosses(
			flows,
			heatingLengthM,
			gvsLengthM,
			*uptimeHours,
		)
		if err != nil {
			setJointCalculationError(&calculation, err)
			calculations = append(calculations, calculation)
			continue
		}
		calculation.Q1HeatLossNormPeriod = float64Pointer(losses.q1)
		calculation.Q2HeatLossNormPeriod = float64Pointer(losses.q2)
		calculation.Q3HeatLossNormPeriod = float64Pointer(losses.q3)
		calculation.Q4HeatLossNormPeriod = float64Pointer(losses.q4)
		calculations = append(calculations, calculation)
	}

	return calculations, nil
}

func setJointCalculationError(calculation *domain.JointChannelCalculation, err error) {
	message := err.Error()
	calculation.CalculationError = &message
}

func float64Pointer(value float64) *float64 {
	return &value
}
