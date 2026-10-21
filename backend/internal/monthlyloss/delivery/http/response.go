package monthlylosshttp

import (
	"time"

	"lostHeat/internal/monthlyloss/domain"
)

type lossResponse struct {
	HeatNetworkID                  int64    `json:"heat_network_id"`
	HeatNetworkName                string   `json:"heat_network_name"`
	Month                          string   `json:"month"`
	TotalNormalizedHeatLossPerHour *float64 `json:"total_normalized_heat_loss_per_hour"`
	LossGJ                         *float64 `json:"loss_gj"`
	CalculationError               *string  `json:"calculation_error,omitempty"`
}

type listResponse struct {
	Month  string         `json:"month"`
	Losses []lossResponse `json:"losses"`
}

type errorResponse struct {
	Error string `json:"error"`
}

func newListResponse(
	month time.Time,
	rows []domain.NetworkLoss,
) listResponse {
	response := listResponse{
		Month:  month.Format("2006-01"),
		Losses: make([]lossResponse, 0, len(rows)),
	}

	for _, row := range rows {
		response.Losses = append(response.Losses, lossResponse{
			HeatNetworkID:                  row.HeatNetworkID,
			HeatNetworkName:                row.HeatNetworkName,
			Month:                          row.Month.Format("2006-01"),
			TotalNormalizedHeatLossPerHour: row.TotalNormalizedHeatLossPerHour,
			LossGJ:                         row.LossGJ,
			CalculationError:               row.CalculationError,
		})
	}

	return response
}
