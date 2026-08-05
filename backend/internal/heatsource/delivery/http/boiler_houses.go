package heatsourcehttp

import (
	"net/http"

	"lostHeat/internal/heatsource/domain"
)

type BoilerHouseResponse struct {
	ID      string `json:"id"`
	Code    string `json:"code"`
	Name    string `json:"name"`
	City    string `json:"city"`
	Address string `json:"address"`
}

type ListBoilerHousesResponse struct {
	Items []BoilerHouseResponse `json:"items"`
}

func (handler *Handler) ListBoilerHouses(
	w http.ResponseWriter,
	r *http.Request,
) {
	boilerHouses, err :=
		handler.service.ListBoilerHouses(r.Context())

	if err != nil {
		handler.logger.Error(
			"failed to list boiler houses",
			"error",
			err,
		)

		writeError(
			w,
			http.StatusInternalServerError,
			"internal_error",
			"Failed to get boiler houses",
		)
		return
	}

	items := make(
		[]BoilerHouseResponse,
		0,
		len(boilerHouses),
	)

	for _, boilerHouse := range boilerHouses {
		items = append(
			items,
			newBoilerHouseResponse(boilerHouse),
		)
	}

	writeJSON(
		w,
		http.StatusOK,
		ListBoilerHousesResponse{
			Items: items,
		},
	)
}

func newBoilerHouseResponse(
	boilerHouse domain.BoilerHouse,
) BoilerHouseResponse {
	return BoilerHouseResponse{
		ID:      boilerHouse.ID,
		Code:    boilerHouse.Code,
		Name:    boilerHouse.Name,
		City:    boilerHouse.City,
		Address: boilerHouse.Address,
	}
}
