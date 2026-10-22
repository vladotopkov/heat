package monthlytemperaturehttp

import (
	"time"

	"lostHeat/internal/monthlytemperature/domain"
)

type temperatureResponse struct {
	ID              *int64   `json:"id"`
	HeatNetworkID   int64    `json:"heat_network_id"`
	HeatNetworkName string   `json:"heat_network_name"`
	Month           string   `json:"month"`
	Supply          *float64 `json:"supply_t"`
	Return          *float64 `json:"return_t"`
	Ground          *float64 `json:"ground_t"`
	GVSSupply       *float64 `json:"gvs_supply_t"`
	GVSReturn       *float64 `json:"gvs_return_t"`
}

type listResponse struct {
	Month        string                `json:"month"`
	Temperatures []temperatureResponse `json:"temperatures"`
}

type errorResponse struct {
	Error string `json:"error"`
}

func newListResponse(
	month time.Time,
	rows []domain.NetworkTemperature,
) listResponse {
	response := listResponse{
		Month:        month.Format("2006-01"),
		Temperatures: make([]temperatureResponse, 0, len(rows)),
	}

	for _, row := range rows {
		response.Temperatures = append(
			response.Temperatures,
			newTemperatureResponse(row),
		)
	}

	return response
}

func newTemperatureResponse(
	row domain.NetworkTemperature,
) temperatureResponse {
	return temperatureResponse{
		ID:              row.ID,
		HeatNetworkID:   row.HeatNetworkID,
		HeatNetworkName: row.HeatNetworkName,
		Month:           row.Month.Format("2006-01"),
		Supply:          row.Supply,
		Return:          row.Return,
		Ground:          row.Ground,
		GVSSupply:       row.GVSSupply,
		GVSReturn:       row.GVSReturn,
	}
}
