package heatsourcehttp

import (
	"net/http"

	"lostHeat/internal/heatsource/domain"
)

type CalculationOperationResponse struct {
	ID   string `json:"id"`
	Code   string `json:"code"`
	Name string `json:"name"`
}

type ListCalculationOperationsResponse struct {
	Items []CalculationOperationResponse `json:"items"`
}

func (handler *Handler) ListCalculationOperations(
	w http.ResponseWriter,
	r *http.Request,
) {
	calculationOperations, err :=
		handler.service.ListCalculationOperations(r.Context())

	if err != nil {
		handler.logger.Error(
			"failed to list calculation operations",
			"error",
			err,
		)

		writeError(
			w,
			http.StatusInternalServerError,
			"internal_error",
			"Failed to get calculation operations",
		)
		return
	}

	items := make(
		[]CalculationOperationResponse,
		0,
		len(calculationOperations),
	)

	for _, calculationOperation := range calculationOperations {
		items = append(
			items,
			newCalculationOperationResponse(
				calculationOperation,
			),
		)
	}

	writeJSON(
		w,
		http.StatusOK,
		ListCalculationOperationsResponse{
			Items: items,
		},
	)
}

func newCalculationOperationResponse(
	calculationOperation domain.CalculationOperation,
) CalculationOperationResponse {
	return CalculationOperationResponse{
		ID:   calculationOperation.ID,
		Name: calculationOperation.Name,
	}
}
