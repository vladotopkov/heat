package monthlytemperaturehttp

type saveRequest struct {
	Supply *float64 `json:"supply_t"`
	Return *float64 `json:"return_t"`
	Ground *float64 `json:"ground_t"`
}
