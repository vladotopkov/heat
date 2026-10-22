package monthlytemperaturehttp

type saveRequest struct {
	Supply    *float64 `json:"supply_t"`
	Return    *float64 `json:"return_t"`
	Ground    *float64 `json:"ground_t"`
	GVSSupply *float64 `json:"gvs_supply_t"`
	GVSReturn *float64 `json:"gvs_return_t"`
}
