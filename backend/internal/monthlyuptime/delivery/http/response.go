package monthlyuptimehttp

import (
	"time"

	"lostHeat/internal/monthlyuptime/domain"
)

type uptimeResponse struct {
	ID              *int64 `json:"id"`
	HeatNetworkID   int64  `json:"heat_network_id"`
	HeatNetworkName string `json:"heat_network_name"`
	Month           string `json:"month"`
	HoursPerMonth   *int   `json:"hours_per_month"`
}

type listResponse struct {
	Month  string           `json:"month"`
	Uptime []uptimeResponse `json:"uptime"`
}

type errorResponse struct {
	Error string `json:"error"`
}

func newListResponse(
	month time.Time,
	rows []domain.NetworkUptime,
) listResponse {
	response := listResponse{
		Month:  month.Format("2006-01"),
		Uptime: make([]uptimeResponse, 0, len(rows)),
	}

	for _, row := range rows {
		response.Uptime = append(response.Uptime, newUptimeResponse(row))
	}

	return response
}

func newUptimeResponse(row domain.NetworkUptime) uptimeResponse {
	return uptimeResponse{
		ID:              row.ID,
		HeatNetworkID:   row.HeatNetworkID,
		HeatNetworkName: row.HeatNetworkName,
		Month:           row.Month.Format("2006-01"),
		HoursPerMonth:   row.HoursPerMonth,
	}
}
