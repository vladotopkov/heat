package service

import (
	"fmt"
	"strings"
	"time"
	"unicode"

	"lostHeat/internal/sectionqh/domain"
)

const pipelineObjectKind = "PIPELINE"

type betaCandidate struct {
	value       domain.BetaValue
	specificity int
}

func selectBetaValue(
	section domain.NetworkSection,
	qhValue *domain.QHValue,
	values []domain.BetaValue,
) (domain.BetaValue, error) {
	if section.ProjectDate == nil {
		return domain.BetaValue{}, fmt.Errorf(
			"%w: network section id=%d has no project_date",
			domain.ErrBetaValueNotFound,
			section.ID,
		)
	}

	pipeType := inferPipeType(section.QHTableCode, section.QHTableName)
	// The special PI/GPI/GSI rules start in 1990. Older insulated pipes use
	// the common pipeline rules based on their laying characteristics.
	if section.ProjectDate.Year() < 1990 {
		pipeType = ""
	}

	nominalBoreMM := section.NominalBoreMM
	if nominalBoreMM == nil && qhValue != nil {
		nominalBoreMM = qhValue.NominalBoreMM
	}

	characteristics := betaCharacteristics{
		projectDate: dateOnly(*section.ProjectDate),
		layingType:  normalizeLayingType(section.LayingType),
		undergroundLaying: normalizeUndergroundLayingType(
			section.UndergroundLayingType,
		),
		supportType:   normalizeSupportType(section.SupportType),
		nominalBoreMM: nominalBoreMM,
		pipeType:      pipeType,
		objectKind:    pipelineObjectKind,
	}

	var best *betaCandidate
	ambiguousIDs := make([]int64, 0)

	for _, value := range values {
		specificity, matches := matchBetaValue(characteristics, value)
		if !matches {
			continue
		}

		if best != nil && specificity < best.specificity {
			continue
		}

		if best != nil && specificity == best.specificity {
			ambiguousIDs = append(ambiguousIDs, value.ID)
			continue
		}

		best = &betaCandidate{
			value:       value,
			specificity: specificity,
		}
		ambiguousIDs = ambiguousIDs[:0]
	}

	if best == nil {
		return domain.BetaValue{}, fmt.Errorf(
			"%w: network section id=%d, qh_table=%q, project_date=%s",
			domain.ErrBetaValueNotFound,
			section.ID,
			section.QHTableCode,
			section.ProjectDate.Format("2006-01-02"),
		)
	}

	if len(ambiguousIDs) > 0 {
		ids := append([]int64{best.value.ID}, ambiguousIDs...)

		return domain.BetaValue{}, fmt.Errorf(
			"%w: network section id=%d, candidate ids=%v",
			domain.ErrAmbiguousBetaValue,
			section.ID,
			ids,
		)
	}

	return best.value, nil
}

type betaCharacteristics struct {
	projectDate       time.Time
	layingType        string
	undergroundLaying string
	supportType       string
	nominalBoreMM     *float64
	pipeType          string
	objectKind        string
}

func matchBetaValue(
	actual betaCharacteristics,
	rule domain.BetaValue,
) (int, bool) {
	if rule.ProjectDateFrom != nil &&
		actual.projectDate.Before(dateOnly(*rule.ProjectDateFrom)) {
		return 0, false
	}
	if rule.ProjectDateTo != nil &&
		actual.projectDate.After(dateOnly(*rule.ProjectDateTo)) {
		return 0, false
	}

	specificity := 0

	if !matchesTextRule(rule.ObjectKind, actual.objectKind) {
		return 0, false
	}
	if rule.ObjectKind != nil {
		specificity++
	}

	if rule.PipeType == nil {
		if actual.pipeType != "" {
			return 0, false
		}
	} else {
		if !matchesTextRule(rule.PipeType, actual.pipeType) {
			return 0, false
		}
		specificity++
	}

	if !matchesTextRule(rule.LayingType, actual.layingType) {
		return 0, false
	}
	if rule.LayingType != nil {
		specificity++
	}

	if !matchesTextRule(
		rule.UndergroundLayingType,
		actual.undergroundLaying,
	) {
		return 0, false
	}
	if rule.UndergroundLayingType != nil {
		specificity++
	}

	if !matchesTextRule(rule.SupportType, actual.supportType) {
		return 0, false
	}
	if rule.SupportType != nil {
		specificity++
	}

	if rule.NominalBoreFromMM != nil || rule.NominalBoreToMM != nil {
		if actual.nominalBoreMM == nil {
			return 0, false
		}

		if rule.NominalBoreFromMM != nil &&
			*actual.nominalBoreMM < *rule.NominalBoreFromMM {
			return 0, false
		}
		// The upper boundary is exclusive. The source notes define the pair
		// as DN < 150 and DN >= 150 even though both use the value 150.
		if rule.NominalBoreToMM != nil &&
			*actual.nominalBoreMM >= *rule.NominalBoreToMM {
			return 0, false
		}

		specificity++
	}

	if rule.ProjectDateFrom != nil {
		specificity++
	}
	if rule.ProjectDateTo != nil {
		specificity++
	}

	return specificity, true
}

func matchesTextRule(expected *string, actual string) bool {
	if expected == nil {
		return true
	}

	return actual != "" && normalizeCode(*expected) == actual
}

func inferPipeType(tableCode string, tableName string) string {
	code := normalizeCode(tableCode)
	name := normalizeCode(tableName)

	switch {
	case strings.Contains(name, "ГПИ"), strings.Contains(name, "GPI"):
		return "GPI"

	case strings.Contains(name, "ГСИ"), strings.Contains(name, "GSI"):
		return "GSI"

	case code == "Б.15",
		strings.Contains(name, "ПИ-ТРУБОПРОВОД"),
		strings.Contains(name, "PI-PIPELINE"):
		return "PI"

	default:
		return ""
	}
}

func normalizeLayingType(value *string) string {
	if value == nil {
		return ""
	}

	switch normalizeCode(*value) {
	case "UNDERGROUND", "ПОДЗЕМНЫЙ", "ПОДЗЕМНАЯ":
		return "UNDERGROUND"

	case "OPEN_AIR", "OPEN AIR", "НАДЗЕМНЫЙ", "НАДЗЕМНАЯ",
		"ОТКРЫТЫЙ ВОЗДУХ":
		return "OPEN_AIR"

	case "TUNNEL", "ТОННЕЛЬ":
		return "TUNNEL"

	case "ROOM", "ПОМЕЩЕНИЕ":
		return "ROOM"

	default:
		return normalizeCode(*value)
	}
}

func normalizeUndergroundLayingType(value *string) string {
	if value == nil {
		return ""
	}

	switch normalizeCode(*value) {
	case "CHANNEL", "КАНАЛЬНАЯ", "КАНАЛЬНЫЙ":
		return "CHANNEL"

	case "NON_CHANNEL", "NON CHANNEL", "БЕСКАНАЛЬНАЯ", "БЕСКАНАЛЬНЫЙ":
		return "NON_CHANNEL"

	default:
		return normalizeCode(*value)
	}
}

func normalizeSupportType(value *string) string {
	if value == nil {
		return ""
	}

	switch normalizeCode(*value) {
	case "MOVABLE", "ПОДВИЖНАЯ", "ПОДВИЖНЫЙ":
		return "MOVABLE"

	case "SUSPENDED", "ПОДВЕСНАЯ", "ПОДВЕСНОЙ":
		return "SUSPENDED"

	default:
		return normalizeCode(*value)
	}
}

func normalizeCode(value string) string {
	return strings.ToUpper(strings.TrimSpace(strings.Map(
		func(character rune) rune {
			if character == 'ё' || character == 'Ё' {
				return 'Е'
			}
			if unicode.IsSpace(character) {
				return ' '
			}

			return character
		},
		value,
	)))
}

func dateOnly(value time.Time) time.Time {
	return time.Date(
		value.Year(),
		value.Month(),
		value.Day(),
		0,
		0,
		0,
		0,
		time.UTC,
	)
}
