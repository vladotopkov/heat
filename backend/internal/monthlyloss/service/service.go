package service

import (
	"context"
	"fmt"
	"math"
	"time"

	"lostHeat/internal/monthlyloss/domain"
)

const kilojoulesToGigajoules = 1e-6

type Repository interface {
	ListInputsForMonth(
		ctx context.Context,
		month time.Time,
	) ([]domain.CalculationInput, error)
}

type NormalizedHeatLossProvider interface {
	TotalNormalizedHeatLossPerHour(
		ctx context.Context,
		heatNetworkID int64,
	) (total float64, unavailableReason *string, err error)
}

type Service struct {
	repository                 Repository
	normalizedHeatLossProvider NormalizedHeatLossProvider
}

func New(
	repository Repository,
	normalizedHeatLossProvider NormalizedHeatLossProvider,
) *Service {
	return &Service{
		repository:                 repository,
		normalizedHeatLossProvider: normalizedHeatLossProvider,
	}
}

func (s *Service) ListForMonth(
	ctx context.Context,
	month time.Time,
) ([]domain.NetworkLoss, error) {
	month, err := normalizeMonth(month)
	if err != nil {
		return nil, err
	}

	inputs, err := s.repository.ListInputsForMonth(ctx, month)
	if err != nil {
		return nil, fmt.Errorf(
			"list loss inputs for month=%s: %w",
			month.Format("2006-01"),
			err,
		)
	}

	result := make([]domain.NetworkLoss, 0, len(inputs))
	for _, input := range inputs {
		loss, err := s.calculateNetworkLoss(ctx, input)
		if err != nil {
			return nil, fmt.Errorf(
				"calculate loss for heat_network_id=%d: %w",
				input.HeatNetworkID,
				err,
			)
		}

		result = append(result, loss)
	}

	return result, nil
}

func (s *Service) calculateNetworkLoss(
	ctx context.Context,
	input domain.CalculationInput,
) (domain.NetworkLoss, error) {
	result := domain.NetworkLoss{
		HeatNetworkID:   input.HeatNetworkID,
		HeatNetworkName: input.HeatNetworkName,
		Month:           input.Month,
	}

	if input.ActualSupply == nil ||
		input.ActualReturn == nil ||
		input.ActualGround == nil {
		return unavailable(result, "не заполнены температуры за выбранный месяц"), nil
	}

	if input.Hours == nil {
		return unavailable(result, "не заполнены часы работы за выбранный месяц"), nil
	}

	if input.ProjectSupply == nil ||
		input.ProjectReturn == nil ||
		input.ProjectGround == nil {
		return unavailable(result, "не заполнены проектные температуры теплосети"), nil
	}

	total, totalUnavailableReason, err :=
		s.normalizedHeatLossProvider.TotalNormalizedHeatLossPerHour(
			ctx,
			input.HeatNetworkID,
		)
	if err != nil {
		return domain.NetworkLoss{}, err
	}
	if totalUnavailableReason != nil {
		return unavailable(
			result,
			"ΣQнорм/ч не рассчитана: "+*totalUnavailableReason,
		), nil
	}
	result.TotalNormalizedHeatLossPerHour = floatPointer(total)

	projectTemperatureDifference :=
		*input.ProjectSupply +
			*input.ProjectReturn -
			2**input.ProjectGround
	if math.Abs(projectTemperatureDifference) < 1e-9 {
		return unavailable(
			result,
			"расчётная разность температур равна нулю",
		), nil
	}

	actualTemperatureDifference :=
		*input.ActualSupply +
			*input.ActualReturn -
			2**input.ActualGround
	lossGJ := total *
		actualTemperatureDifference /
		projectTemperatureDifference *
		kilojoulesToGigajoules *
		float64(*input.Hours)

	if math.IsNaN(lossGJ) || math.IsInf(lossGJ, 0) {
		return unavailable(result, "результат расчёта не является конечным числом"), nil
	}

	result.LossGJ = floatPointer(lossGJ)
	return result, nil
}

func normalizeMonth(month time.Time) (time.Time, error) {
	if month.IsZero() {
		return time.Time{}, domain.ErrInvalidMonth
	}

	return time.Date(
		month.Year(),
		month.Month(),
		1,
		0,
		0,
		0,
		0,
		time.UTC,
	), nil
}

func unavailable(
	result domain.NetworkLoss,
	reason string,
) domain.NetworkLoss {
	result.CalculationError = &reason
	return result
}

func floatPointer(value float64) *float64 {
	return &value
}
