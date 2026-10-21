package service

import (
	"context"
	"fmt"
	"time"

	"lostHeat/internal/monthlyuptime/domain"
)

const maximumHoursPerMonth = 744

type Repository interface {
	ListForMonth(
		ctx context.Context,
		month time.Time,
	) ([]domain.NetworkUptime, error)

	Upsert(
		ctx context.Context,
		heatNetworkID int64,
		month time.Time,
		hoursPerMonth int,
	) (domain.NetworkUptime, error)
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
) ([]domain.NetworkUptime, error) {
	month, err := normalizeMonth(month)
	if err != nil {
		return nil, err
	}

	rows, err := s.repository.ListForMonth(ctx, month)
	if err != nil {
		return nil, fmt.Errorf(
			"list uptime for month=%s: %w",
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
	hoursPerMonth int,
) (domain.NetworkUptime, error) {
	if heatNetworkID <= 0 {
		return domain.NetworkUptime{}, fmt.Errorf(
			"%w: heat network id must be positive",
			domain.ErrHeatNetworkNotFound,
		)
	}

	month, err := normalizeMonth(month)
	if err != nil {
		return domain.NetworkUptime{}, err
	}

	if hoursPerMonth < 0 || hoursPerMonth > maximumHoursPerMonth {
		return domain.NetworkUptime{}, fmt.Errorf(
			"%w: value must be between 0 and %d",
			domain.ErrInvalidHours,
			maximumHoursPerMonth,
		)
	}

	row, err := s.repository.Upsert(
		ctx,
		heatNetworkID,
		month,
		hoursPerMonth,
	)
	if err != nil {
		return domain.NetworkUptime{}, fmt.Errorf(
			"save uptime for heat_network_id=%d, month=%s: %w",
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
