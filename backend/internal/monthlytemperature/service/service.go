package service

import (
	"context"
	"fmt"
	"math"
	"time"

	"lostHeat/internal/monthlytemperature/domain"
)

const maximumDatabaseTemperature = 9999.99

type Repository interface {
	ListForMonth(
		ctx context.Context,
		month time.Time,
	) ([]domain.NetworkTemperature, error)

	Upsert(
		ctx context.Context,
		heatNetworkID int64,
		month time.Time,
		values domain.Values,
	) (domain.NetworkTemperature, error)
}

type Service struct {
	repository Repository
}

func New(repository Repository) *Service {
	return &Service{repository: repository}
}

func (s *Service) ListForMonth(
	ctx context.Context,
	month time.Time,
) ([]domain.NetworkTemperature, error) {
	month, err := normalizeMonth(month)
	if err != nil {
		return nil, err
	}

	rows, err := s.repository.ListForMonth(ctx, month)
	if err != nil {
		return nil, fmt.Errorf(
			"list temperatures for month=%s: %w",
			month.Format("2006-01"),
			err,
		)
	}

	return rows, nil
}

func (s *Service) Save(
	ctx context.Context,
	heatNetworkID int64,
	month time.Time,
	values domain.Values,
) (domain.NetworkTemperature, error) {
	if heatNetworkID <= 0 {
		return domain.NetworkTemperature{}, fmt.Errorf(
			"%w: heat network id must be positive",
			domain.ErrHeatNetworkNotFound,
		)
	}

	month, err := normalizeMonth(month)
	if err != nil {
		return domain.NetworkTemperature{}, err
	}

	if (values.GVSSupply == nil) != (values.GVSReturn == nil) {
		return domain.NetworkTemperature{}, fmt.Errorf(
			"%w: gvs_supply_t and gvs_return_t must be provided together",
			domain.ErrInvalidTemperature,
		)
	}
	if values.GVSSupply != nil && heatNetworkID != 2 {
		return domain.NetworkTemperature{}, fmt.Errorf(
			"%w: GVS temperatures are only supported for heat network 2",
			domain.ErrInvalidTemperature,
		)
	}
	if err := validateValues(values); err != nil {
		return domain.NetworkTemperature{}, err
	}

	row, err := s.repository.Upsert(ctx, heatNetworkID, month, values)
	if err != nil {
		return domain.NetworkTemperature{}, fmt.Errorf(
			"save temperatures for heat_network_id=%d, month=%s: %w",
			heatNetworkID,
			month.Format("2006-01"),
			err,
		)
	}

	return row, nil
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

func validateValues(values domain.Values) error {
	fields := []struct {
		name  string
		value float64
	}{
		{name: "supply_t", value: values.Supply},
		{name: "return_t", value: values.Return},
		{name: "ground_t", value: values.Ground},
		{name: "gvs_supply_t", value: optionalTemperature(values.GVSSupply)},
		{name: "gvs_return_t", value: optionalTemperature(values.GVSReturn)},
	}

	for _, field := range fields {
		if math.IsNaN(field.value) || math.IsInf(field.value, 0) ||
			math.Abs(field.value) > maximumDatabaseTemperature {
			return fmt.Errorf(
				"%w: %s must be a finite number between -%.2f and %.2f",
				domain.ErrInvalidTemperature,
				field.name,
				maximumDatabaseTemperature,
				maximumDatabaseTemperature,
			)
		}
	}

	return nil
}

func optionalTemperature(value *float64) float64 {
	if value == nil {
		return 0
	}
	return *value
}
