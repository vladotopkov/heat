package service

import (
	"context"
	"errors"
	"fmt"

	"lostHeat/internal/sectionqh/domain"
)

type Repository interface {
	ListHeatNetworks(
		ctx context.Context,
	) ([]domain.HeatNetwork, error)

	GetHeatNetwork(
		ctx context.Context,
		id int64,
	) (domain.HeatNetwork, error)

	GetNetworkSection(
		ctx context.Context,
		id int64,
	) (domain.NetworkSection, error)

	ListNetworkSectionsByHeatNetworkID(
		ctx context.Context,
		heatNetworkID int64,
	) ([]domain.NetworkSection, error)

	ListBetaValues(
		ctx context.Context,
	) ([]domain.BetaValue, error)

	SaveNetworkSectionBeta(
		ctx context.Context,
		networkSectionID int64,
		beta float64,
	) error

	ListQHValuesByTableID(
		ctx context.Context,
		qhTableID int64,
	) ([]domain.QHValue, error)
}

type Service struct {
	repository Repository
}

func New(repository Repository) *Service {
	return &Service{
		repository: repository,
	}
}

func (s *Service) ListHeatNetworks(
	ctx context.Context,
) ([]domain.HeatNetwork, error) {
	networks, err := s.repository.ListHeatNetworks(ctx)
	if err != nil {
		return nil, fmt.Errorf("list heat networks: %w", err)
	}

	return networks, nil
}

func (s *Service) ListNetworkSections(
	ctx context.Context,
	heatNetworkID int64,
) (domain.HeatNetworkSections, error) {
	network, err := s.repository.GetHeatNetwork(ctx, heatNetworkID)
	if err != nil {
		return domain.HeatNetworkSections{}, err
	}

	sections, err := s.repository.ListNetworkSectionsByHeatNetworkID(
		ctx,
		heatNetworkID,
	)
	if err != nil {
		return domain.HeatNetworkSections{}, fmt.Errorf(
			"list sections for heat network id=%d: %w",
			heatNetworkID,
			err,
		)
	}

	result := domain.HeatNetworkSections{
		HeatNetwork: network,
		Sections: make(
			[]domain.NetworkSectionWithQH,
			0,
			len(sections),
		),
	}
	betaValues := make([]domain.BetaValue, 0)
	needsBetaLookup := false
	for _, section := range sections {
		if section.Beta == nil {
			needsBetaLookup = true
			break
		}
	}
	if needsBetaLookup {
		betaValues, err = s.repository.ListBetaValues(ctx)
		if err != nil {
			return domain.HeatNetworkSections{}, fmt.Errorf(
				"list beta values: %w",
				err,
			)
		}
	}
	valuesByTableID := make(map[int64][]domain.QHValue)

	for _, section := range sections {
		values, loaded := valuesByTableID[section.QHTableID]
		if !loaded {
			values, err = s.repository.ListQHValuesByTableID(
				ctx,
				section.QHTableID,
			)
			if err != nil {
				return domain.HeatNetworkSections{}, err
			}

			valuesByTableID[section.QHTableID] = values
		}

		section = withNetworkProjectTemperatures(network, section)
		value, _, selectionErr := selectNetworkSectionValue(network, section, values)
		sectionResult := domain.NetworkSectionWithQH{
			Section: section,
		}
		var selectedQHValue *domain.QHValue

		switch {
		case selectionErr == nil:
			sectionResult.QHValue = &value
			selectedQHValue = &value

		case errors.Is(selectionErr, domain.ErrQHValueNotFound),
			errors.Is(selectionErr, domain.ErrAmbiguousQHValue):
			message := selectionErr.Error()
			sectionResult.QHError = &message

		default:
			return domain.HeatNetworkSections{}, selectionErr
		}

		if section.Beta != nil {
			sectionResult.Beta = &domain.BetaValue{
				Value: *section.Beta,
			}
			result.Sections = append(result.Sections, sectionResult)
			continue
		}

		beta, betaErr := selectBetaValue(section, selectedQHValue, betaValues)
		switch {
		case betaErr == nil:
			if err := s.repository.SaveNetworkSectionBeta(
				ctx,
				section.ID,
				beta.Value,
			); err != nil {
				return domain.HeatNetworkSections{}, fmt.Errorf(
					"save beta for network section id=%d: %w",
					section.ID,
					err,
				)
			}
			sectionResult.Beta = &beta

		case errors.Is(betaErr, domain.ErrBetaValueNotFound),
			errors.Is(betaErr, domain.ErrAmbiguousBetaValue):
			message := betaErr.Error()
			sectionResult.BetaError = &message

		default:
			return domain.HeatNetworkSections{}, betaErr
		}

		result.Sections = append(result.Sections, sectionResult)
	}

	return result, nil
}

func (s *Service) TotalNormalizedHeatLossPerHour(
	ctx context.Context,
	heatNetworkID int64,
) (float64, *string, error) {
	result, err := s.ListNetworkSections(ctx, heatNetworkID)
	if err != nil {
		return 0, nil, err
	}

	var total float64
	for _, section := range result.Sections {
		switch {
		case section.Section.LengthM == nil:
			reason := fmt.Sprintf(
				"для участка ID %d не заполнена длина",
				section.Section.ID,
			)
			return 0, &reason, nil

		case section.QHValue == nil:
			reason := fmt.Sprintf(
				"для участка ID %d не найден qh",
				section.Section.ID,
			)
			return 0, &reason, nil

		case section.Beta == nil:
			reason := fmt.Sprintf(
				"для участка ID %d не найден коэффициент β",
				section.Section.ID,
			)
			return 0, &reason, nil
		}

		total += 3.6 *
			section.QHValue.Value *
			section.Beta.Value *
			*section.Section.LengthM
	}

	return total, nil, nil
}

func (s *Service) GetQHValue(
	ctx context.Context,
	networkSectionID int64,
) (domain.Match, error) {
	section, err := s.repository.GetNetworkSection(
		ctx,
		networkSectionID,
	)
	if err != nil {
		return domain.Match{}, err
	}

	// This query is intentionally scoped by the table selected on the section.
	values, err := s.repository.ListQHValuesByTableID(
		ctx,
		section.QHTableID,
	)
	if err != nil {
		return domain.Match{}, err
	}

	network, err := s.repository.GetHeatNetwork(ctx, section.HeatNetworkID)
	if err != nil {
		return domain.Match{}, err
	}

	value, matchedFields, err := selectNetworkSectionValue(
		network,
		section,
		values,
	)
	if err != nil {
		return domain.Match{}, fmt.Errorf(
			"network section id=%d, qh_table_id=%d: %w",
			section.ID,
			section.QHTableID,
			err,
		)
	}

	return domain.Match{
		NetworkSectionID: section.ID,
		QHTableID:        section.QHTableID,
		QHValue:          value,
		MatchedFields:    matchedFields,
	}, nil
}
