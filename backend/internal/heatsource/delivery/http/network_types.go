package heatsourcehttp

import (
	"net/http"

	"lostHeat/internal/heatsource/domain"
)

type NetworkTypeResponse struct {
	ID          string `json:"id"`
	Code        string `json:"code"`
	Name        string `json:"name"`
	Description string `json:"description"`
	IsActive    bool   `json:"isActive"`
}

type ListNetworkTypesResponse struct {
	Items []NetworkTypeResponse `json:"items"`
}

func (handler *Handler) ListNetworkTypes(
	w http.ResponseWriter,
	r *http.Request,
) {
	networkTypes, err :=
		handler.service.ListNetworkTypes(r.Context())

	if err != nil {
		handler.logger.Error(
			"failed to list network types",
			"error",
			err,
		)

		writeError(
			w,
			http.StatusInternalServerError,
			"internal_error",
			"Failed to get network types",
		)
		return
	}

	items := make(
		[]NetworkTypeResponse,
		0,
		len(networkTypes),
	)

	for _, networkType := range networkTypes {
		items = append(
			items,
			newNetworkTypeResponse(networkType),
		)
	}

	writeJSON(
		w,
		http.StatusOK,
		ListNetworkTypesResponse{
			Items: items,
		},
	)
}

func newNetworkTypeResponse(
	networkType domain.NetworkType,
) NetworkTypeResponse {
	return NetworkTypeResponse{
		ID:          networkType.ID,
		Code:        networkType.Code,
		Name:        networkType.Name,
		Description: networkType.Description,
		IsActive:    networkType.IsActive,
	}
}
