package heatsourcehttp

import (
	"net/http"

	"lostHeat/internal/heatsource/domain"
)

type LayingMethodResponse struct {
	ID          string `json:"id"`
	Code        string `json:"code"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

type ListLayingMethodsResponse struct {
	Items []LayingMethodResponse `json:"items"`
}

func (handler *Handler) ListLayingMethods(
	w http.ResponseWriter,
	r *http.Request,
) {
	layingMethods, err :=
		handler.service.ListLayingMethods(r.Context())

	if err != nil {
		handler.logger.Error(
			"failed to list laying methods",
			"error",
			err,
		)

		writeError(
			w,
			http.StatusInternalServerError,
			"internal_error",
			"Failed to get laying methods",
		)
		return
	}

	items := make(
		[]LayingMethodResponse,
		0,
		len(layingMethods),
	)

	for _, layingMethod := range layingMethods {
		items = append(
			items,
			newLayingMethodResponse(layingMethod),
		)
	}

	writeJSON(
		w,
		http.StatusOK,
		ListLayingMethodsResponse{
			Items: items,
		},
	)
}

func newLayingMethodResponse(
	layingMethod domain.LayingMethod,
) LayingMethodResponse {
	return LayingMethodResponse{
		ID:          layingMethod.ID,
		Code:        layingMethod.Code,
		Name:        layingMethod.Name,
		Description: layingMethod.Description,
	}
}
