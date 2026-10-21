package http

import (
	nethttp "net/http"

	monthlylosshttp "lostHeat/internal/monthlyloss/delivery/http"
	monthlytemperaturehttp "lostHeat/internal/monthlytemperature/delivery/http"
	monthlyuptimehttp "lostHeat/internal/monthlyuptime/delivery/http"
	sectionqhhttp "lostHeat/internal/sectionqh/delivery/http"
)

func NewRouter(
	sectionQHHandler *sectionqhhttp.Handler,
	monthlyTemperatureHandler *monthlytemperaturehttp.Handler,
	monthlyUptimeHandler *monthlyuptimehttp.Handler,
	monthlyLossHandler *monthlylosshttp.Handler,
) nethttp.Handler {
	mux := nethttp.NewServeMux()

	mux.HandleFunc(
		"GET /api/v1/heat-networks",
		sectionQHHandler.ListHeatNetworks,
	)

	mux.HandleFunc(
		"GET /api/v1/heat-networks/{heatNetworkID}/sections",
		sectionQHHandler.ListNetworkSections,
	)

	mux.HandleFunc(
		"GET /api/v1/network-sections/{networkSectionID}/qh-value",
		sectionQHHandler.GetQHValue,
	)

	mux.HandleFunc(
		"GET /api/v1/temperatures",
		monthlyTemperatureHandler.List,
	)

	mux.HandleFunc(
		"PUT /api/v1/heat-networks/{heatNetworkID}/temperatures/{month}",
		monthlyTemperatureHandler.Save,
	)

	mux.HandleFunc(
		"GET /api/v1/uptime",
		monthlyUptimeHandler.List,
	)

	mux.HandleFunc(
		"PUT /api/v1/heat-networks/{heatNetworkID}/uptime/{month}",
		monthlyUptimeHandler.Save,
	)

	mux.HandleFunc(
		"GET /api/v1/losses",
		monthlyLossHandler.List,
	)

	return mux
}
