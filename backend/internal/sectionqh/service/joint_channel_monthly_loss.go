package service

import (
	"fmt"
	"math"
)

const (
	jointChannelLocalLossCoefficient = 1.0
	kilojouleToGigajoule             = 1e-6
)

type jointChannelMonthlyNormalizedLosses struct {
	q1 float64
	q2 float64
	q3 float64
	q4 float64
}

// calculateJointChannelMonthlyNormalizedLosses applies formula 6.14 to each
// pipeline separately. The returned values are GJ for the selected month.
func calculateJointChannelMonthlyNormalizedLosses(
	flows jointChannelMonthlyNormalizedHeatFlows,
	heatingLengthM *float64,
	gvsLengthM *float64,
	uptimeHours int,
) (jointChannelMonthlyNormalizedLosses, error) {
	if !positiveFiniteNumber(heatingLengthM) {
		return jointChannelMonthlyNormalizedLosses{}, fmt.Errorf(
			"HEATING NetworkSection.length_m must be non-null, finite and greater than zero",
		)
	}
	if !positiveFiniteNumber(gvsLengthM) {
		return jointChannelMonthlyNormalizedLosses{}, fmt.Errorf(
			"GVS NetworkSection.length_m must be non-null, finite and greater than zero",
		)
	}
	if uptimeHours < 0 {
		return jointChannelMonthlyNormalizedLosses{}, fmt.Errorf(
			"up_time.hours_per_month=%d must be non-negative",
			uptimeHours,
		)
	}

	for name, value := range map[string]float64{
		"q1_norm_period": flows.q1,
		"q2_norm_period": flows.q2,
		"q3_norm_period": flows.q3,
		"q4_norm_period": flows.q4,
	} {
		if math.IsNaN(value) || math.IsInf(value, 0) {
			return jointChannelMonthlyNormalizedLosses{}, fmt.Errorf(
				"%s must be finite",
				name,
			)
		}
	}

	calculate := func(linearLoss, lengthM float64) float64 {
		return 3.6 * linearLoss * jointChannelLocalLossCoefficient *
			lengthM * float64(uptimeHours) * kilojouleToGigajoule
	}
	losses := jointChannelMonthlyNormalizedLosses{
		q1: calculate(flows.q1, *heatingLengthM),
		q2: calculate(flows.q2, *heatingLengthM),
		q3: calculate(flows.q3, *gvsLengthM),
		q4: calculate(flows.q4, *gvsLengthM),
	}
	for name, value := range map[string]float64{
		"Q1_norm_period": losses.q1,
		"Q2_norm_period": losses.q2,
		"Q3_norm_period": losses.q3,
		"Q4_norm_period": losses.q4,
	} {
		if math.IsNaN(value) || math.IsInf(value, 0) {
			return jointChannelMonthlyNormalizedLosses{}, fmt.Errorf(
				"calculated %s must be finite",
				name,
			)
		}
	}

	return losses, nil
}
