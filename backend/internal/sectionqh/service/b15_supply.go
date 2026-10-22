package service

import (
	"fmt"
	"math"

	"lostHeat/internal/sectionqh/domain"
)

const eremichiHeatNetworkID = 1

// Use the same project regime for calculation and the section's API response.
// Stored NetworkSection temperatures are left untouched.
func withNetworkProjectTemperatures(network domain.HeatNetwork, section domain.NetworkSection) domain.NetworkSection {
	if network.ID == eremichiHeatNetworkID {
		section.SupplyTemperature = network.ProjectSupplyTemperature
		section.ReturnTemperature = network.ProjectReturnTemperature
	}
	if network.ID == militaryTownHeatNetworkID {
		switch section.NetworkType {
		case "HEATING":
			section.SupplyTemperature = network.ProjectSupplyTemperature
			section.ReturnTemperature = network.ProjectReturnTemperature
		case "GVS":
			section.SupplyTemperature = network.GVSProjectSupplyTemperature
			section.ReturnTemperature = network.GVSProjectCirculationTemperature
		default:
			section.SupplyTemperature, section.ReturnTemperature = nil, nil
		}
	}
	return section
}

func selectNetworkSectionValue(
	network domain.HeatNetwork,
	section domain.NetworkSection,
	values []domain.QHValue,
) (domain.QHValue, []string, error) {
	section = withNetworkProjectTemperatures(network, section)
	if network.ID == militaryTownHeatNetworkID {
		return selectMilitaryTownSeparateValue(section, values)
	}
	if network.ID != eremichiHeatNetworkID {
		return selectMostSpecificValue(section, values)
	}
	if section.SupplyTemperature == nil || section.ReturnTemperature == nil ||
		math.IsNaN(*section.SupplyTemperature) || math.IsInf(*section.SupplyTemperature, 0) ||
		math.IsNaN(*section.ReturnTemperature) || math.IsInf(*section.ReturnTemperature, 0) {
		return domain.QHValue{}, nil, fmt.Errorf(
			"%w: у теплосети id=%d не заполнены корректные проектные температуры подачи и обратки в HeatNetwork",
			domain.ErrQHValueNotFound, network.ID,
		)
	}
	if normalizeCode(section.QHTableCode) != "Б.15" {
		return selectMostSpecificValue(section, values)
	}
	// The existing B.15 method adjusts only supply. Reject an unsupported
	// return regime rather than silently selecting a supply-only table row.
	if !numbersEqual(*section.ReturnTemperature, 50) {
		return domain.QHValue{}, nil, fmt.Errorf(
			"%w: Б.15: пересчёт обратки на проектную температуру %g °C не реализован; табличная температура — 50 °C",
			domain.ErrQHValueNotFound, *section.ReturnTemperature,
		)
	}

	supply, _, err := selectB15Supply(section, values, *section.SupplyTemperature)
	if err != nil {
		return domain.QHValue{}, nil, err
	}

	// Keep the existing selector and return-pipe rules. Replace only the
	// supply contribution in a private copy; the shared reference table and
	// its tabulated rounding of TWO_PIPE_TOTAL remain intact.
	adjusted := append([]domain.QHValue(nil), values...)
	var supply90 float64
	for _, value := range values {
		if value.ID == supply.ID {
			supply90 = value.Value
			break
		}
	}
	for index, value := range adjusted {
		if value.ID == supply.ID {
			adjusted[index] = supply
			continue
		}
		if value.QHTableID != section.QHTableID ||
			value.PipelineRole == nil || normalizeCode(*value.PipelineRole) != "TWO_PIPE_TOTAL" ||
			value.OuterDiameterMM == nil || !numbersEqual(*value.OuterDiameterMM, *section.SupplyOuterDiameter) ||
			value.SupplyTemperatureC == nil || !numbersEqual(*value.SupplyTemperatureC, 90) ||
			!sameB15Row(value, supply) {
			continue
		}
		adjusted[index].Value += supply.Value - supply90
		adjusted[index].SupplyTemperatureC = supply.SupplyTemperatureC
		note := *supply.Note + "; сумма двух труб: изменена только составляющая подачи"
		adjusted[index].Note = &note
	}
	return selectMostSpecificValue(section, adjusted)
}

// B.15 stores each diameter row as RETURN at 50 C, SUPPLY at 90 C and
// TWO_PIPE_TOTAL. Both extrapolation anchors belong to the supply diameter's
// normative row; the actual return pipe diameter/temperature are not inputs.
func selectB15Supply(
	section domain.NetworkSection,
	values []domain.QHValue,
	temperature float64,
) (domain.QHValue, []string, error) {
	if section.SupplyOuterDiameter == nil {
		return domain.QHValue{}, nil, fmt.Errorf(
			"%w: Б.15: у участка id=%d не задан supply_outer_diameter_mm",
			domain.ErrQHValueNotFound, section.ID,
		)
	}

	findAnchor := func(role string, temperature float64) (domain.QHValue, error) {
		var anchor *domain.QHValue
		for _, value := range values {
			if value.QHTableID != section.QHTableID ||
				value.OuterDiameterMM == nil ||
				!numbersEqual(*value.OuterDiameterMM, *section.SupplyOuterDiameter) ||
				value.PipelineRole == nil || normalizeCode(*value.PipelineRole) != role {
				continue
			}
			actualTemperature := value.SupplyTemperatureC
			if role == "RETURN" {
				actualTemperature = value.ReturnTemperatureC
			}
			if actualTemperature == nil || !numbersEqual(*actualTemperature, temperature) {
				continue
			}
			if anchor != nil {
				return domain.QHValue{}, fmt.Errorf(
					"%w: Б.15: диаметр подачи %g мм, %g °C, записи id=%d и id=%d",
					domain.ErrAmbiguousQHValue, *section.SupplyOuterDiameter,
					temperature, anchor.ID, value.ID,
				)
			}
			anchor = &value
		}
		if anchor == nil {
			return domain.QHValue{}, fmt.Errorf(
				"%w: Б.15: для диаметра подачи %g мм отсутствует q%g (%s)",
				domain.ErrQHValueNotFound, *section.SupplyOuterDiameter, temperature, role,
			)
		}
		return *anchor, nil
	}

	q50, err := findAnchor("RETURN", 50)
	if err != nil {
		return domain.QHValue{}, nil, err
	}
	q90, err := findAnchor("SUPPLY", 90)
	if err != nil {
		return domain.QHValue{}, nil, err
	}
	if !sameB15Row(q50, q90) {
		return domain.QHValue{}, nil, fmt.Errorf(
			"%w: Б.15: q50 id=%d и q90 id=%d имеют разные параметры строки",
			domain.ErrQHValueNotFound, q50.ID, q90.ID,
		)
	}

	result := q90
	result.Value = q90.Value + (q90.Value-q50.Value)*((temperature-90)/(90-50))
	result.SupplyTemperatureC = &temperature
	note := fmt.Sprintf(
		"Б.15: подача %g °C из HeatNetwork, диаметр %g мм; q50=%g (id=%d), q90=%g (id=%d); q(T)=q90+(q90-q50)*(T-90)/(90-50)",
		temperature, *section.SupplyOuterDiameter, q50.Value, q50.ID, q90.Value, q90.ID,
	)
	result.Note = &note

	return result, []string{"outer_diameter_mm=supply_outer_diameter_mm"}, nil
}

func sameB15Row(left, right domain.QHValue) bool {
	// These are the shared row characteristics in the B.15 import.
	return sameOptionalNumber(left.ChannelHeightM, right.ChannelHeightM) &&
		sameOptionalNumber(left.ChannelWidthM, right.ChannelWidthM) &&
		sameOptionalNumber(left.ThermalResistance, right.ThermalResistance)
}

func sameOptionalNumber(left, right *float64) bool {
	if left == nil || right == nil {
		return left == nil && right == nil
	}
	return numbersEqual(*left, *right)
}
