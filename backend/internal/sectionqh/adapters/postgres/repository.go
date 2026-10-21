package postgres

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"lostHeat/internal/sectionqh/domain"
)

type Repository struct {
	pool *pgxpool.Pool
}

func New(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) ListHeatNetworks(
	ctx context.Context,
) ([]domain.HeatNetwork, error) {
	const query = `
		SELECT
			id,
			name
		FROM public."HeatNetwork"
		ORDER BY name, id
	`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("list heat networks: %w", err)
	}
	defer rows.Close()

	networks := make([]domain.HeatNetwork, 0)

	for rows.Next() {
		var network domain.HeatNetwork

		if err := rows.Scan(&network.ID, &network.Name); err != nil {
			return nil, fmt.Errorf("scan heat network: %w", err)
		}

		networks = append(networks, network)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate heat networks: %w", err)
	}

	return networks, nil
}

func (r *Repository) GetHeatNetwork(
	ctx context.Context,
	id int64,
) (domain.HeatNetwork, error) {
	const query = `
		SELECT
			id,
			name
		FROM public."HeatNetwork"
		WHERE id = $1
	`

	var network domain.HeatNetwork

	err := r.pool.QueryRow(ctx, query, id).Scan(
		&network.ID,
		&network.Name,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.HeatNetwork{}, fmt.Errorf(
			"%w: id=%d",
			domain.ErrHeatNetworkNotFound,
			id,
		)
	}
	if err != nil {
		return domain.HeatNetwork{}, fmt.Errorf(
			"get heat network id=%d: %w",
			id,
			err,
		)
	}

	return network, nil
}

func (r *Repository) GetNetworkSection(
	ctx context.Context,
	id int64,
) (domain.NetworkSection, error) {
	const query = `
		SELECT
			ns.id,
			ns.heat_network_id,
			ns.qh_table_id,
			qt.table_code,
			qt.table_name,
			ns.laying_type,
			ns.underground_laying_type,
			ns.burial_depth_m::double precision,
			ns.temperature_c::double precision,
			ns.supply_temperature_c::double precision,
			ns.return_temperature_c::double precision,
			ns.supply_outer_diameter_mm::double precision,
			ns.supply_wall_thickness_mm::double precision,
			ns.supply_shell_outer_diameter_mm::double precision,
			ns.return_outer_diameter_mm::double precision,
			ns.return_wall_thickness_mm::double precision,
			ns.return_shell_outer_diameter_mm::double precision,
			ns.length_m::double precision,
			ns.project_date,
			ns.beta::double precision
		FROM public."NetworkSection" AS ns
		JOIN public.qh_tables AS qt ON qt.id = ns.qh_table_id
		WHERE ns.id = $1
	`

	var section domain.NetworkSection

	err := scanNetworkSection(
		r.pool.QueryRow(ctx, query, id),
		&section,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.NetworkSection{}, fmt.Errorf(
			"%w: id=%d",
			domain.ErrNetworkSectionNotFound,
			id,
		)
	}
	if err != nil {
		return domain.NetworkSection{}, fmt.Errorf(
			"get network section id=%d: %w",
			id,
			err,
		)
	}

	return section, nil
}

func (r *Repository) ListNetworkSectionsByHeatNetworkID(
	ctx context.Context,
	heatNetworkID int64,
) ([]domain.NetworkSection, error) {
	const query = `
		SELECT
			ns.id,
			ns.heat_network_id,
			ns.qh_table_id,
			qt.table_code,
			qt.table_name,
			ns.laying_type,
			ns.underground_laying_type,
			ns.burial_depth_m::double precision,
			ns.temperature_c::double precision,
			ns.supply_temperature_c::double precision,
			ns.return_temperature_c::double precision,
			ns.supply_outer_diameter_mm::double precision,
			ns.supply_wall_thickness_mm::double precision,
			ns.supply_shell_outer_diameter_mm::double precision,
			ns.return_outer_diameter_mm::double precision,
			ns.return_wall_thickness_mm::double precision,
			ns.return_shell_outer_diameter_mm::double precision,
			ns.length_m::double precision,
			ns.project_date,
			ns.beta::double precision
		FROM public."NetworkSection" AS ns
		JOIN public.qh_tables AS qt ON qt.id = ns.qh_table_id
		WHERE ns.heat_network_id = $1
		ORDER BY ns.id
	`

	rows, err := r.pool.Query(ctx, query, heatNetworkID)
	if err != nil {
		return nil, fmt.Errorf(
			"list network sections for heat_network_id=%d: %w",
			heatNetworkID,
			err,
		)
	}
	defer rows.Close()

	sections := make([]domain.NetworkSection, 0)

	for rows.Next() {
		var section domain.NetworkSection

		if err := scanNetworkSection(rows, &section); err != nil {
			return nil, fmt.Errorf(
				"scan network section for heat_network_id=%d: %w",
				heatNetworkID,
				err,
			)
		}

		sections = append(sections, section)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate network sections for heat_network_id=%d: %w",
			heatNetworkID,
			err,
		)
	}

	return sections, nil
}

type rowScanner interface {
	Scan(dest ...any) error
}

func scanNetworkSection(
	row rowScanner,
	section *domain.NetworkSection,
) error {
	return row.Scan(
		&section.ID,
		&section.HeatNetworkID,
		&section.QHTableID,
		&section.QHTableCode,
		&section.QHTableName,
		&section.LayingType,
		&section.UndergroundLayingType,
		&section.BurialDepthM,
		&section.TemperatureC,
		&section.SupplyTemperature,
		&section.ReturnTemperature,
		&section.SupplyOuterDiameter,
		&section.SupplyWallThickness,
		&section.SupplyShellOuterDiameter,
		&section.ReturnOuterDiameter,
		&section.ReturnWallThickness,
		&section.ReturnShellOuterDiameter,
		&section.LengthM,
		&section.ProjectDate,
		&section.Beta,
	)
}

func (r *Repository) SaveNetworkSectionBeta(
	ctx context.Context,
	networkSectionID int64,
	beta float64,
) error {
	const query = `
		UPDATE public."NetworkSection"
		SET beta = $2
		WHERE id = $1
			AND beta IS NULL
	`

	if _, err := r.pool.Exec(ctx, query, networkSectionID, beta); err != nil {
		return fmt.Errorf(
			"save beta for network section id=%d: %w",
			networkSectionID,
			err,
		)
	}

	return nil
}

func (r *Repository) ListBetaValues(
	ctx context.Context,
) ([]domain.BetaValue, error) {
	const query = `
		SELECT
			id,
			project_date_from,
			project_date_to,
			laying_type,
			underground_laying_type,
			support_type,
			nominal_bore_from_mm::double precision,
			nominal_bore_to_mm::double precision,
			pipe_type,
			object_kind,
			beta::double precision,
			note
		FROM public.beta_values
		ORDER BY id
	`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("list beta values: %w", err)
	}
	defer rows.Close()

	values := make([]domain.BetaValue, 0)

	for rows.Next() {
		var value domain.BetaValue

		if err := rows.Scan(
			&value.ID,
			&value.ProjectDateFrom,
			&value.ProjectDateTo,
			&value.LayingType,
			&value.UndergroundLayingType,
			&value.SupportType,
			&value.NominalBoreFromMM,
			&value.NominalBoreToMM,
			&value.PipeType,
			&value.ObjectKind,
			&value.Value,
			&value.Note,
		); err != nil {
			return nil, fmt.Errorf("scan beta value: %w", err)
		}

		values = append(values, value)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate beta values: %w", err)
	}

	return values, nil
}

func (r *Repository) ListQHValuesByTableID(
	ctx context.Context,
	qhTableID int64,
) ([]domain.QHValue, error) {
	const query = `
		SELECT
			id,
			qh_table_id,
			outer_diameter_mm::double precision,
			nominal_bore_mm::double precision,
			pipe_size,
			pressure_pipe_inner_diameter_mm::double precision,
			pressure_pipe_outer_diameter_mm::double precision,
			pressure_pipe_wall_thickness_mm::double precision,
			shell_outer_diameter_mm::double precision,
			shell_wall_thickness_mm::double precision,
			channel_height_m::double precision,
			channel_width_m::double precision,
			thermal_resistance::double precision,
			burial_depth_m::double precision,
			axis_distance_m::double precision,
			object_kind,
			placement_variant,
			pipeline_role,
			temperature_c::double precision,
			supply_temperature_c::double precision,
			return_temperature_c::double precision,
			qh_value::double precision,
			source_interpolated,
			note
		FROM public.qh_values
		WHERE qh_table_id = $1
		ORDER BY id
	`

	rows, err := r.pool.Query(ctx, query, qhTableID)
	if err != nil {
		return nil, fmt.Errorf(
			"list qh_values for qh_table_id=%d: %w",
			qhTableID,
			err,
		)
	}
	defer rows.Close()

	values := make([]domain.QHValue, 0)

	for rows.Next() {
		var value domain.QHValue

		if err := rows.Scan(
			&value.ID,
			&value.QHTableID,
			&value.OuterDiameterMM,
			&value.NominalBoreMM,
			&value.PipeSize,
			&value.PressurePipeInnerDiameterMM,
			&value.PressurePipeOuterDiameterMM,
			&value.PressurePipeWallThicknessMM,
			&value.ShellOuterDiameterMM,
			&value.ShellWallThicknessMM,
			&value.ChannelHeightM,
			&value.ChannelWidthM,
			&value.ThermalResistance,
			&value.BurialDepthM,
			&value.AxisDistanceM,
			&value.ObjectKind,
			&value.PlacementVariant,
			&value.PipelineRole,
			&value.TemperatureC,
			&value.SupplyTemperatureC,
			&value.ReturnTemperatureC,
			&value.Value,
			&value.SourceInterpolated,
			&value.Note,
		); err != nil {
			return nil, fmt.Errorf(
				"scan qh_value for qh_table_id=%d: %w",
				qhTableID,
				err,
			)
		}

		values = append(values, value)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterate qh_values for qh_table_id=%d: %w",
			qhTableID,
			err,
		)
	}

	return values, nil
}
