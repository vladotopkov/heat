package service

import (
	"fmt"
	"math"

	"lostHeat/internal/sectionqh/domain"
)

const militaryTownHeatNetworkID = 2

// A separate section contains two pipes. Each pipe uses its own diameter and
// project temperature; a matching RETURN row alone is not a section total.
func selectMilitaryTownSeparateValue(
	section domain.NetworkSection,
	values []domain.QHValue,
) (domain.QHValue, []string, error) {
	if section.JointChannelID != nil {
		return domain.QHValue{}, nil, fmt.Errorf(
			"%w: совместная прокладка: расчёт участка id=%d пока не реализован",
			domain.ErrQHValueNotFound, section.ID,
		)
	}
	if section.NetworkType != "HEATING" && section.NetworkType != "GVS" {
		return domain.QHValue{}, nil, fmt.Errorf("%w: неизвестный network_type %q", domain.ErrQHValueNotFound, section.NetworkType)
	}
	if normalizeCode(section.QHTableCode) != "Б.15" {
		return domain.QHValue{}, nil, fmt.Errorf("%w: расчёт раздельной прокладки реализован только для Б.15", domain.ErrQHValueNotFound)
	}
	if !finiteTemperature(section.SupplyTemperature) || !finiteTemperature(section.ReturnTemperature) {
		return domain.QHValue{}, nil, fmt.Errorf(
			"%w: в HeatNetwork не заполнены корректные проектные температуры для %s",
			domain.ErrQHValueNotFound, section.NetworkType,
		)
	}
	supply, err := b15PipeValue(section.QHTableID, section.SupplyOuterDiameter, *section.SupplyTemperature, values)
	if err != nil {
		return domain.QHValue{}, nil, fmt.Errorf("подача участка id=%d: %w", section.ID, err)
	}
	returnPipe, err := b15PipeValue(section.QHTableID, section.ReturnOuterDiameter, *section.ReturnTemperature, values)
	if err != nil {
		return domain.QHValue{}, nil, fmt.Errorf("обратка/циркуляция участка id=%d: %w", section.ID, err)
	}
	role := "TWO_PIPE_TOTAL"
	note := fmt.Sprintf(
		"Б.15, раздельная прокладка %s; температуры из HeatNetwork; подача Ø%g при %g °C: %s; обратка/циркуляция Ø%g при %g °C: %s; qh=%g+%g=%g Вт/м",
		section.NetworkType, *section.SupplyOuterDiameter, *section.SupplyTemperature, supply.note,
		*section.ReturnOuterDiameter, *section.ReturnTemperature, returnPipe.note,
		supply.value, returnPipe.value, supply.value+returnPipe.value,
	)
	return domain.QHValue{
			// This sum has no single source row in qh_values.
			QHTableID: section.QHTableID, PipelineRole: &role,
			SupplyTemperatureC: section.SupplyTemperature, ReturnTemperatureC: section.ReturnTemperature,
			SupplyValue: &supply.value, ReturnValue: &returnPipe.value,
			Value:              supply.value + returnPipe.value,
			SourceInterpolated: supply.interpolated || returnPipe.interpolated,
			Note:               &note,
		}, []string{
			"joint_channel_id IS NULL",
			"outer_diameter_mm=supply_outer_diameter_mm",
			"outer_diameter_mm=return_outer_diameter_mm",
			"project_temperatures=HeatNetwork." + section.NetworkType,
		}, nil
}

type pipeQH struct {
	value        float64
	interpolated bool
	note         string
}

func finiteTemperature(value *float64) bool {
	return value != nil && !math.IsNaN(*value) && !math.IsInf(*value, 0)
}

func b15PipeValue(tableID int64, diameter *float64, temperature float64, values []domain.QHValue) (pipeQH, error) {
	if !finiteTemperature(diameter) || *diameter <= 0 {
		return pipeQH{}, fmt.Errorf("%w: не задан корректный наружный диаметр трубы", domain.ErrQHValueNotFound)
	}
	findAnchor := func(role string, anchorTemperature float64) (domain.QHValue, error) {
		var found *domain.QHValue
		for _, value := range values {
			if value.QHTableID != tableID || value.OuterDiameterMM == nil ||
				!numbersEqual(*value.OuterDiameterMM, *diameter) ||
				value.PipelineRole == nil || normalizeCode(*value.PipelineRole) != role {
				continue
			}
			actual := value.SupplyTemperatureC
			if role == "RETURN" {
				actual = value.ReturnTemperatureC
			}
			if actual == nil || !numbersEqual(*actual, anchorTemperature) {
				continue
			}
			if found != nil {
				return domain.QHValue{}, fmt.Errorf("%w: Б.15 Ø%g, %g °C: записи %d и %d", domain.ErrAmbiguousQHValue, *diameter, anchorTemperature, found.ID, value.ID)
			}
			found = &value
		}
		if found == nil {
			return domain.QHValue{}, fmt.Errorf("%w: Б.15 Ø%g: отсутствует q%g", domain.ErrQHValueNotFound, *diameter, anchorTemperature)
		}
		if math.IsNaN(found.Value) || math.IsInf(found.Value, 0) || found.Value < 0 {
			return domain.QHValue{}, fmt.Errorf("%w: некорректное значение qh id=%d", domain.ErrQHValueNotFound, found.ID)
		}
		return *found, nil
	}
	// At a tabulated temperature use the exact column. In particular, return
	// at 50 C does not need a 90 C anchor for that diameter.
	if temperature == 50 || temperature == 90 {
		role := "RETURN"
		if temperature == 90 {
			role = "SUPPLY"
		}
		anchor, err := findAnchor(role, temperature)
		if err != nil {
			return pipeQH{}, err
		}
		return pipeQH{value: anchor.Value, note: fmt.Sprintf("q%g=%g (id=%d)", temperature, anchor.Value, anchor.ID)}, nil
	}
	q50, err := findAnchor("RETURN", 50)
	if err != nil {
		return pipeQH{}, err
	}
	q90, err := findAnchor("SUPPLY", 90)
	if err != nil {
		return pipeQH{}, err
	}
	if !sameB15Row(q50, q90) {
		return pipeQH{}, fmt.Errorf("%w: Б.15 Ø%g: q50 и q90 имеют разные параметры строки", domain.ErrQHValueNotFound, *diameter)
	}
	value := q50.Value + (q90.Value-q50.Value)*(temperature-50)/(90-50)
	if math.IsNaN(value) || math.IsInf(value, 0) || value < 0 {
		return pipeQH{}, fmt.Errorf("%w: Б.15 Ø%g: некорректный qh при %g °C", domain.ErrQHValueNotFound, *diameter, temperature)
	}
	return pipeQH{value: value, interpolated: true, note: fmt.Sprintf(
		"q50=%g (id=%d), q90=%g (id=%d), q(T)=q50+(q90-q50)*(T-50)/40=%g",
		q50.Value, q50.ID, q90.Value, q90.ID, value,
	)}, nil
}
