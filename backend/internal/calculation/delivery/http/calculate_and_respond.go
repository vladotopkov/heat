package calculationhttp

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"

	"lostHeat/internal/calculation/service"
)

const maxRequestBodySize = 1 << 20 // 1 MiB

func (h *Handler) Calculate(
	w http.ResponseWriter,
	r *http.Request,
) {
	var request calculateRequest

	decoder := json.NewDecoder(
		http.MaxBytesReader(
			w,
			r.Body,
			maxRequestBodySize,
		),
	)

	decoder.DisallowUnknownFields()

	if err := decoder.Decode(&request); err != nil {
		writeError(
			w,
			http.StatusBadRequest,
			"invalid_json",
			"Некорректное тело запроса",
		)
		return
	}

	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeError(
			w,
			http.StatusBadRequest,
			"invalid_json",
			"Тело запроса должно содержать один JSON-объект",
		)
		return
	}

	requestData, err := request.toRequestData()
	if err != nil {
		writeError(
			w,
			http.StatusUnprocessableEntity,
			"invalid_calculation_period",
			"Даты должны иметь формат YYYY-MM-DD",
		)
		return
	}

	result, err := h.service.Calculate(
		r.Context(),
		requestData,
	)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrInvalidInput):
			writeError(
				w,
				http.StatusUnprocessableEntity,
				"invalid_calculation_input",
				err.Error(),
			)

		case errors.Is(err, service.ErrNotFound):
			writeError(
				w,
				http.StatusNotFound,
				"reference_not_found",
				"Один из выбранных справочников не найден",
			)

		default:
			h.logger.Error(
				"calculation failed",
				"error",
				err,
			)

			writeError(
				w,
				http.StatusInternalServerError,
				"internal_error",
				"Не удалось выполнить расчёт",
			)
		}

		return
	}

	writeJSON(
		w,
		http.StatusOK,
		newCalculateResponse(result),
	)
}