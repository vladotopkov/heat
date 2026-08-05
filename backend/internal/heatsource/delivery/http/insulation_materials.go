package heatsourcehttp

import (
	"net/http"

	"lostHeat/internal/heatsource/domain"
)

type InsulationMaterialResponse struct {
	ID          string `json:"id"`
	Code        string `json:"code"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

type ListInsulationMaterialsResponse struct {
	Items []InsulationMaterialResponse `json:"items"`
}

func (handler *Handler) ListInsulationMaterials(
	w http.ResponseWriter,
	r *http.Request,
) {
	insulationMaterials, err :=
		handler.service.ListInsulationMaterials(r.Context())

	if err != nil {
		handler.logger.Error(
			"failed to list insulation materials",
			"error",
			err,
		)

		writeError(
			w,
			http.StatusInternalServerError,
			"internal_error",
			"Failed to get insulation materials",
		)
		return
	}

	items := make(
		[]InsulationMaterialResponse,
		0,
		len(insulationMaterials),
	)

	for _, insulationMaterial := range insulationMaterials {
		items = append(
			items,
			newInsulationMaterialResponse(insulationMaterial),
		)
	}

	writeJSON(
		w,
		http.StatusOK,
		ListInsulationMaterialsResponse{
			Items: items,
		},
	)
}

func newInsulationMaterialResponse(
	insulationMaterial domain.InsulationMaterial,
) InsulationMaterialResponse {
	return InsulationMaterialResponse{
		ID:          insulationMaterial.ID,
		Code:        insulationMaterial.Code,
		Name:        insulationMaterial.Name,
		Description: insulationMaterial.Description,
	}
}
