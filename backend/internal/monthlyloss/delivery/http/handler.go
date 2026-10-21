package monthlylosshttp

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	nethttp "net/http"
	"time"

	"lostHeat/internal/monthlyloss/domain"
)

type Service interface {
	ListForMonth(
		ctx context.Context,
		month time.Time,
	) ([]domain.NetworkLoss, error)
}

type Handler struct {
	service Service
	logger  *slog.Logger
}

func New(service Service, logger *slog.Logger) *Handler {
	return &Handler{service: service, logger: logger}
}

func (h *Handler) List(
	w nethttp.ResponseWriter,
	r *nethttp.Request,
) {
	month, valid := parseMonth(r.URL.Query().Get("month"))
	if !valid {
		writeJSON(
			w,
			nethttp.StatusBadRequest,
			errorResponse{Error: "month must have YYYY-MM format"},
		)
		return
	}

	rows, err := h.service.ListForMonth(r.Context(), month)
	if err != nil {
		h.writeServiceError(w, err)
		return
	}

	writeJSON(w, nethttp.StatusOK, newListResponse(month, rows))
}

func (h *Handler) writeServiceError(
	w nethttp.ResponseWriter,
	err error,
) {
	if errors.Is(err, domain.ErrInvalidMonth) {
		writeJSON(w, nethttp.StatusBadRequest, errorResponse{Error: err.Error()})
		return
	}

	h.logger.Error("monthly loss request failed", "error", err)
	writeJSON(
		w,
		nethttp.StatusInternalServerError,
		errorResponse{Error: "failed to calculate monthly losses"},
	)
}

func parseMonth(value string) (time.Time, bool) {
	if len(value) != len("2006-01") {
		return time.Time{}, false
	}

	month, err := time.Parse("2006-01", value)
	return month, err == nil && month.Format("2006-01") == value
}

func writeJSON(
	w nethttp.ResponseWriter,
	status int,
	value any,
) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(value); err != nil {
		slog.Error("encode monthly loss response", "error", err)
	}
}
