package service

import (
	"errors"
	"testing"
	"time"

	"lostHeat/internal/sectionqh/domain"
)

func TestSelectBetaValueForPIPipeline(t *testing.T) {
	t.Parallel()

	values := []domain.BetaValue{
		{
			ID:              11,
			ProjectDateFrom: datePointer(1990, time.January, 1),
			ProjectDateTo:   datePointer(2009, time.December, 31),
			PipeType:        text("PI"),
			ObjectKind:      text("PIPELINE"),
			Value:           1.15,
		},
		{
			ID:              19,
			ProjectDateFrom: datePointer(2010, time.January, 1),
			PipeType:        text("PI"),
			ObjectKind:      text("PIPELINE"),
			Value:           1,
		},
	}

	tests := []struct {
		name      string
		date      *time.Time
		wantID    int64
		wantValue float64
	}{
		{
			name:      "1990 through 2009",
			date:      datePointer(2005, time.June, 1),
			wantID:    11,
			wantValue: 1.15,
		},
		{
			name:      "from 2010",
			date:      datePointer(2014, time.June, 1),
			wantID:    19,
			wantValue: 1,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()

			value, err := selectBetaValue(
				domain.NetworkSection{
					ID:                    1,
					QHTableCode:           "Б.15",
					ProjectDate:           test.date,
					LayingType:            text("Подземный"),
					UndergroundLayingType: text("канальная"),
				},
				nil,
				values,
			)
			if err != nil {
				t.Fatalf("selectBetaValue() error = %v", err)
			}

			if value.ID != test.wantID || value.Value != test.wantValue {
				t.Errorf(
					"selectBetaValue() = id %d, beta %.2f; want id %d, beta %.2f",
					value.ID,
					value.Value,
					test.wantID,
					test.wantValue,
				)
			}
		})
	}
}

func TestSelectBetaValueUsesCommonLayingRuleBefore1990(t *testing.T) {
	t.Parallel()

	value, err := selectBetaValue(
		domain.NetworkSection{
			ID:                    1,
			QHTableCode:           "Б.15",
			ProjectDate:           datePointer(1988, time.January, 1),
			LayingType:            text("Подземный"),
			UndergroundLayingType: text("канальная"),
		},
		nil,
		[]domain.BetaValue{{
			ID:                    2,
			ProjectDateTo:         datePointer(1989, time.December, 31),
			LayingType:            text("UNDERGROUND"),
			UndergroundLayingType: text("CHANNEL"),
			ObjectKind:            text("PIPELINE"),
			Value:                 1.2,
		}},
	)
	if err != nil {
		t.Fatalf("selectBetaValue() error = %v", err)
	}
	if value.Value != 1.2 {
		t.Errorf("beta = %v, want 1.2", value.Value)
	}
}

func TestSelectBetaValueUsesSupportAndNominalBore(t *testing.T) {
	t.Parallel()

	values := []domain.BetaValue{
		{
			ID:              15,
			ProjectDateFrom: datePointer(2010, time.January, 1),
			SupportType:     text("MOVABLE"),
			NominalBoreToMM: number(150),
			ObjectKind:      text("PIPELINE"),
			Value:           1.2,
		},
		{
			ID:                16,
			ProjectDateFrom:   datePointer(2010, time.January, 1),
			SupportType:       text("MOVABLE"),
			NominalBoreFromMM: number(150),
			ObjectKind:        text("PIPELINE"),
			Value:             1.15,
		},
	}

	value, err := selectBetaValue(
		domain.NetworkSection{
			ID:            1,
			ProjectDate:   datePointer(2020, time.January, 1),
			SupportType:   text("подвижная"),
			NominalBoreMM: number(150),
		},
		nil,
		values,
	)
	if err != nil {
		t.Fatalf("selectBetaValue() error = %v", err)
	}
	if value.ID != 16 || value.Value != 1.15 {
		t.Errorf(
			"selectBetaValue() = id %d, beta %.2f; want id 16, beta 1.15",
			value.ID,
			value.Value,
		)
	}
}

func TestSelectBetaValueDoesNotGuessMissingSupportType(t *testing.T) {
	t.Parallel()

	_, err := selectBetaValue(
		domain.NetworkSection{
			ID:          1,
			ProjectDate: datePointer(2020, time.January, 1),
		},
		nil,
		[]domain.BetaValue{{
			ID:              15,
			ProjectDateFrom: datePointer(2010, time.January, 1),
			SupportType:     text("MOVABLE"),
			ObjectKind:      text("PIPELINE"),
			Value:           1.2,
		}},
	)
	if !errors.Is(err, domain.ErrBetaValueNotFound) {
		t.Fatalf("selectBetaValue() error = %v, want ErrBetaValueNotFound", err)
	}
}

func datePointer(year int, month time.Month, day int) *time.Time {
	value := time.Date(year, month, day, 0, 0, 0, 0, time.UTC)
	return &value
}
