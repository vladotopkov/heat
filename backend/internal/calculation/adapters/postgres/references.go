package postgres

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"

	"lostHeat/internal/calculation/domain"
)

var ErrReferencesNotFound = errors.New(
	"calculation references not found",
)

func (r *Repository) LoadReferences(
	ctx context.Context,
	ids domain.CalculationReferenceIDs,
) (domain.CalculationReferences, error) {
	const query = `
		SELECT
			operation.code,
			laying_method.code,

			insulation_material
				.thermal_resistance_mk_per_w
				::DOUBLE PRECISION,

			soil_type
				.thermal_resistance_mk_per_w
				::DOUBLE PRECISION

		FROM calculation_operations AS operation

		JOIN boiler_houses AS boiler_house
			ON boiler_house.id = $2::UUID

		JOIN network_types AS network_type
			ON network_type.id = $3::UUID

		JOIN laying_methods AS laying_method
			ON laying_method.id = $4::UUID

		JOIN insulation_materials AS insulation_material
			ON insulation_material.id = $5::UUID

		LEFT JOIN soil_types AS soil_type
			ON soil_type.id = $6::UUID

		WHERE operation.id = $1::UUID
	`

	var references domain.CalculationReferences

	err := r.db.QueryRow(
		ctx,
		query,
		ids.OperationID,
		ids.BoilerHouseID,
		ids.NetworkTypeID,
		ids.LayingMethodID,
		ids.InsulationMaterialID,
		ids.SoilTypeID,
	).Scan(
		&references.OperationCode,
		&references.LayingMethodCode,
		&references.InsulationResistanceMKPerW,
		&references.SoilResistanceMKPerW,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return domain.CalculationReferences{},
			ErrReferencesNotFound
	}

	if err != nil {
		return domain.CalculationReferences{},
			fmt.Errorf(
				"query calculation references: %w",
				err,
			)
	}

	return references, nil
}