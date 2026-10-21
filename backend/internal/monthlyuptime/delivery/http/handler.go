package monthlyuptimehttp

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	nethttp "net/http"
	"strconv"
	"time"

	"lostHeat/internal/monthlyuptime/domain"
)

type Service interface {
	ListForMonth(
		ctx context.Context,
		month time.Time,
	) ([]domain.NetworkUptime, error)

	Save(
		ctx context.Context,
		heatNetworkID int64,
		month time.Time,
		hoursPerMonth int,
	) (domain.NetworkUptime, error)
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

func (h *Handler) Save(
	w nethttp.ResponseWriter,
	r *nethttp.Request,
) {
	heatNetworkID, err := strconv.ParseInt(
		r.PathValue("heatNetworkID"),
		10,
		64,
	)
	if err != nil || heatNetworkID <= 0 {
		writeJSON(
			w,
			nethttp.StatusBadRequest,
			errorResponse{Error: "heat network id must be a positive integer"},
		)
		return
	}

	month, valid := parseMonth(r.PathValue("month"))
	if !valid {
		writeJSON(
			w,
			nethttp.StatusBadRequest,
			errorResponse{Error: "month must have YYYY-MM format"},
		)
		return
	}

	request, valid := decodeSaveRequest(w, r)
	if !valid {
		return
	}

	row, err := h.service.Save(
		r.Context(),
		heatNetworkID,
		month,
		*request.HoursPerMonth,
	)
	if err != nil {
		h.writeServiceError(w, err)
		return
	}

	writeJSON(w, nethttp.StatusOK, newUptimeResponse(row))
}

func decodeSaveRequest(
	w nethttp.ResponseWriter,
	r *nethttp.Request,
) (saveRequest, bool) {
	r.Body = nethttp.MaxBytesReader(w, r.Body, 1<<20)
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()

	var request saveRequest
	if err := decoder.Decode(&request); err != nil {
		writeJSON(
			w,
			nethttp.StatusBadRequest,
			errorResponse{Error: "request body must contain integer hours_per_month"},
		)
		return saveRequest{}, false
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeJSON(
			w,
			nethttp.StatusBadRequest,
			errorResponse{Error: "request body must contain one JSON object"},
		)
		return saveRequest{}, false
	}
	if request.HoursPerMonth == nil {
		writeJSON(
			w,
			nethttp.StatusBadRequest,
			errorResponse{Error: "hours_per_month is required"},
		)
		return saveRequest{}, false
	}

	return request, true
}

func (h *Handler) writeServiceError(
	w nethttp.ResponseWriter,
	err error,
) {
	switch {
	case errors.Is(err, domain.ErrInvalidMonth),
		errors.Is(err, domain.ErrInvalidHours):
		writeJSON(w, nethttp.StatusBadRequest, errorResponse{Error: err.Error()})

	case errors.Is(err, domain.ErrHeatNetworkNotFound):
		writeJSON(w, nethttp.StatusNotFound, errorResponse{Error: err.Error()})

	default:
		h.logger.Error("monthly uptime request failed", "error", err)
		writeJSON(
			w,
			nethttp.StatusInternalServerError,
			errorResponse{Error: "failed to process monthly uptime"},
		)
	}
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
		slog.Error("encode monthly uptime response", "error", err)
	}
}
