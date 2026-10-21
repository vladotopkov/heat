package service

import (
	"fmt"
	"math"
	"strings"

	"lostHeat/internal/sectionqh/domain"
)

const numericTolerance = 1e-6

type availableNumber struct {
	name  string
	value *float64
}

type candidateMatch struct {
	value         domain.QHValue
	matchedFields []string
}

func selectMostSpecificValue(
	section domain.NetworkSection,
	values []domain.QHValue,
) (domain.QHValue, []string, error) {
	var best *candidateMatch
	bestCount := 0
	ambiguousIDs := make([]int64, 0)

	for _, value := range values {
		matchedFields, matches := matchValue(section, value)
		if !matches || len(matchedFields) == 0 {
			continue
		}

		count := len(matchedFields)
		if count < bestCount {
			continue
		}

		if count == bestCount && best != nil {
			ambiguousIDs = append(ambiguousIDs, value.ID)
			continue
		}

		best = &candidateMatch{
			value:         value,
			matchedFields: matchedFields,
		}
		bestCount = count
		ambiguousIDs = ambiguousIDs[:0]
	}

	if best == nil {
		return domain.QHValue{}, nil, fmt.Errorf(
			"%w: no row matches the section's available characteristics",
			domain.ErrQHValueNotFound,
		)
	}

	if len(ambiguousIDs) > 0 {
		ids := append([]int64{best.value.ID}, ambiguousIDs...)

		return domain.QHValue{}, nil, fmt.Errorf(
			"%w: candidate ids=%v each match %d fields",
			domain.ErrAmbiguousQHValue,
			ids,
			bestCount,
		)
	}

	return best.value, best.matchedFields, nil
}

func matchValue(
	section domain.NetworkSection,
	value domain.QHValue,
) ([]string, bool) {
	matchedFields := make([]string, 0, 12)

	checks := []struct {
		qhField  string
		expected *float64
		actuals  []availableNumber
	}{
		{
			qhField:  "outer_diameter_mm",
			expected: value.OuterDiameterMM,
			actuals: pipeValues(
				value.PipelineRole,
				section.SupplyOuterDiameter,
				section.ReturnOuterDiameter,
				"supply_outer_diameter_mm",
				"return_outer_diameter_mm",
			),
		},
		{
			qhField:  "pressure_pipe_inner_diameter_mm",
			expected: value.PressurePipeInnerDiameterMM,
			actuals: pipeValues(
				value.PipelineRole,
				innerDiameter(
					section.SupplyOuterDiameter,
					section.SupplyWallThickness,
				),
				innerDiameter(
					section.ReturnOuterDiameter,
					section.ReturnWallThickness,
				),
				"supply_inner_diameter_mm",
				"return_inner_diameter_mm",
			),
		},
		{
			qhField:  "pressure_pipe_outer_diameter_mm",
			expected: value.PressurePipeOuterDiameterMM,
			actuals: pipeValues(
				value.PipelineRole,
				section.SupplyOuterDiameter,
				section.ReturnOuterDiameter,
				"supply_outer_diameter_mm",
				"return_outer_diameter_mm",
			),
		},
		{
			qhField:  "pressure_pipe_wall_thickness_mm",
			expected: value.PressurePipeWallThicknessMM,
			actuals: pipeValues(
				value.PipelineRole,
				section.SupplyWallThickness,
				section.ReturnWallThickness,
				"supply_wall_thickness_mm",
				"return_wall_thickness_mm",
			),
		},
		{
			qhField:  "shell_outer_diameter_mm",
			expected: value.ShellOuterDiameterMM,
			actuals: pipeValues(
				value.PipelineRole,
				section.SupplyShellOuterDiameter,
				section.ReturnShellOuterDiameter,
				"supply_shell_outer_diameter_mm",
				"return_shell_outer_diameter_mm",
			),
		},
		{
			qhField:  "burial_depth_m",
			expected: value.BurialDepthM,
			actuals: []availableNumber{{
				name:  "burial_depth_m",
				value: section.BurialDepthM,
			}},
		},
		{
			qhField:  "temperature_c",
			expected: value.TemperatureC,
			actuals: []availableNumber{{
				name:  "temperature_c",
				value: section.TemperatureC,
			}},
		},
		{
			qhField:  "supply_temperature_c",
			expected: value.SupplyTemperatureC,
			actuals: []availableNumber{{
				name:  "supply_temperature_c",
				value: section.SupplyTemperature,
			}},
		},
		{
			qhField:  "return_temperature_c",
			expected: value.ReturnTemperatureC,
			actuals: []availableNumber{{
				name:  "return_temperature_c",
				value: section.ReturnTemperature,
			}},
		},
	}

	for _, check := range checks {
		var matches bool

		matchedFields, matches = matchNumber(
			matchedFields,
			check.qhField,
			check.expected,
			check.actuals,
		)
		if !matches {
			return nil, false
		}
	}

	return matchedFields, true
}

func matchNumber(
	matchedFields []string,
	qhField string,
	expected *float64,
	actuals []availableNumber,
) ([]string, bool) {
	// NULL in qh_values means that this characteristic is not required by this
	// row. A missing section value is also ignored: it must never disqualify a
	// candidate merely because NetworkSection does not provide that property.
	if expected == nil {
		return matchedFields, true
	}

	for _, actual := range actuals {
		if actual.value == nil {
			continue
		}

		if !numbersEqual(*expected, *actual.value) {
			return nil, false
		}

		matchedFields = append(
			matchedFields,
			qhField+"="+actual.name,
		)
	}

	return matchedFields, true
}

func pipeValues(
	pipelineRole *string,
	supply *float64,
	returnValue *float64,
	supplyName string,
	returnName string,
) []availableNumber {
	role := ""
	if pipelineRole != nil {
		role = strings.ToUpper(strings.TrimSpace(*pipelineRole))
	}

	switch role {
	case "SUPPLY", "DHW_SUPPLY":
		return []availableNumber{{name: supplyName, value: supply}}

	case "RETURN", "DHW_CIRCULATION":
		return []availableNumber{{name: returnName, value: returnValue}}

	case "SINGLE":
		if supply != nil {
			return []availableNumber{{name: supplyName, value: supply}}
		}

		return []availableNumber{{name: returnName, value: returnValue}}

	default:
		// TWO_PIPE_TOTAL and generic table rows describe both pipes. Each
		// characteristic which is actually present on the section must match.
		return []availableNumber{
			{name: supplyName, value: supply},
			{name: returnName, value: returnValue},
		}
	}
}

func innerDiameter(
	outerDiameter *float64,
	wallThickness *float64,
) *float64 {
	if outerDiameter == nil || wallThickness == nil {
		return nil
	}

	value := *outerDiameter - 2*(*wallThickness)
	return &value
}

func numbersEqual(left float64, right float64) bool {
	difference := math.Abs(left - right)
	scale := math.Max(1, math.Max(math.Abs(left), math.Abs(right)))

	return difference <= numericTolerance*scale
}
