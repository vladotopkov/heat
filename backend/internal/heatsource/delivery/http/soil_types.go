package heatsourcehttp

import (
	"net/http"

	"lostHeat/internal/heatsource/domain"
)

type SoilTypeResponse struct {
	ID          string `json:"id"`
	Code        string `json:"code"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

type ListSoilTypesResponse struct {
	Items []SoilTypeResponse `json:"items"`
}

func (handler *Handler) ListSoilTypes(
	w http.ResponseWriter,
	r *http.Request,
) {
	soilTypes, err :=
		handler.service.ListSoilTypes(r.Context())

	if err != nil {
		handler.logger.Error(
			"failed to list soil types",
			"error",
			err,
		)

		writeError(
			w,
			http.StatusInternalServerError,
			"internal_error",
			"Failed to get soil types",
		)
		return
	}

	items := make(
		[]SoilTypeResponse,
		0,
		len(soilTypes),
	)

	for _, soilType := range soilTypes {
		items = append(
			items,
			newSoilTypeResponse(soilType),
		)
	}

	writeJSON(
		w,
		http.StatusOK,
		ListSoilTypesResponse{
			Items: items,
		},
	)
}

func newSoilTypeResponse(
	soilType domain.SoilType,
) SoilTypeResponse {
	return SoilTypeResponse{
		ID:          soilType.ID,
		Code:        soilType.Code,
		Name:        soilType.Name,
		Description: soilType.Description,
	}
}
