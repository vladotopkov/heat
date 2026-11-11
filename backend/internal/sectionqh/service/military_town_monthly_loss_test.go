package service

import (
	"context"
	"testing"
	"time"

	"lostHeat/internal/sectionqh/domain"
)

func TestMilitaryTownSeparateSectionUsesMonthlyTemperatureCorrection(t *testing.T) {
	t.Parallel()

	loss, err := calculateMilitaryTownSeparateSectionMonthlyLoss(
		militaryTownNetwork(),
		domain.NetworkSectionWithQH{
			Section: domain.NetworkSection{
				ID: 1, NetworkType: "HEATING", LengthM: number(100),
			},
			QHValue: &domain.QHValue{Value: 30},
			Beta:    &domain.BetaValue{Value: 1.2},
		},
		jointChannelMonthlyTemperatures{
			t1Avg: 70, t2Avg: 50, t3Avg: 58, t4Avg: 48, groundAvg: 6,
		},
		720,
	)
	if err != nil {
		t.Fatal(err)
	}
	assertClose(t, "separate HEATING monthly loss", loss, 8.39808)
}

func TestMilitaryTownMonthlyTotalAddsSeparateSectionsAndJointChannelsOnce(t *testing.T) {
	t.Parallel()

	month := time.Date(2026, time.October, 1, 0, 0, 0, 0, time.UTC)
	sections := jointB15Sections(57, 57, 57, 57)
	for index := range sections {
		sections[index].JointChannelHeightM = number(0.45)
		sections[index].JointChannelWidthM = number(0.9)
		sections[index].JointChannelCoverThicknessM = number(0.1)
		sections[index].JointChannelGroundLambda = number(1.5)
		sections[index].Beta = number(1)
	}
	sections[0].BurialDepthM = number(0.8)
	sections[0].LengthM = number(100)
	sections[1].LengthM = number(80)

	separate := separateSection("HEATING", 57, 57)
	separate.ID = 3
	sections = append(sections, separate)

	values := b15Values(57, 10, 20.5)
	values[2].Value = 30.6
	hours := 720
	stub := &repositoryStub{
		network:       militaryTownNetwork(),
		sections:      sections,
		valuesByTable: map[int64][]domain.QHValue{7: values},
		monthlyTemperatures: []domain.MonthlyTemperature{
			monthlyTemperature(2, 2026, time.October, "HEATING", 70, 50, 6),
			monthlyTemperature(2, 2026, time.October, "GVS", 58, 48, 6),
		},
		uptimeHours: &hours,
	}
	service := New(stub)

	listed, err := service.ListNetworkSectionsForMonth(context.Background(), 2, month)
	if err != nil {
		t.Fatal(err)
	}
	var expected float64
	for _, channel := range listed.JointChannels {
		for _, value := range []*float64{
			channel.Q1HeatLossNormPeriod,
			channel.Q2HeatLossNormPeriod,
			channel.Q3HeatLossNormPeriod,
			channel.Q4HeatLossNormPeriod,
		} {
			if value == nil {
				t.Fatalf("joint channel result is incomplete: %#v", channel)
			}
			expected += *value
		}
	}
	for _, section := range listed.Sections {
		if section.Section.JointChannelID != nil {
			continue
		}
		value, calculationErr := calculateMilitaryTownSeparateSectionMonthlyLoss(
			listed.HeatNetwork,
			section,
			jointChannelMonthlyTemperatures{
				t1Avg: 70, t2Avg: 50, t3Avg: 58, t4Avg: 48, groundAvg: 6,
			},
			hours,
		)
		if calculationErr != nil {
			t.Fatal(calculationErr)
		}
		expected += value
	}

	actual, reason, err := service.TotalHeatLossForMonth(context.Background(), 2, month)
	if err != nil || reason != nil {
		t.Fatalf("TotalHeatLossForMonth() value=%g reason=%v error=%v", actual, reason, err)
	}
	assertClose(t, "network monthly total", actual, expected)
}
