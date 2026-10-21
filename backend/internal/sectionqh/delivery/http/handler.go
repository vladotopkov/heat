package sectionqhhttp

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	nethttp "net/http"
	"strconv"

	"lostHeat/internal/sectionqh/domain"
)

type Service interface {
	ListHeatNetworks(
		ctx context.Context,
	) ([]domain.HeatNetwork, error)

	ListNetworkSections(
		ctx context.Context,
		heatNetworkID int64,
	) (domain.HeatNetworkSections, error)

	GetQHValue(
		ctx context.Context,
		networkSectionID int64,
	) (domain.Match, error)
}

func (h *Handler) ListHeatNetworks(
	w nethttp.ResponseWriter,
	r *nethttp.Request,
) {
	networks, err := h.service.ListHeatNetworks(r.Context())
	if err != nil {
		h.writeServiceError(w, err)
		return
	}

	writeJSON(
		w,
		nethttp.StatusOK,
		newHeatNetworksResponse(networks),
	)
}

func (h *Handler) ListNetworkSections(
	w nethttp.ResponseWriter,
	r *nethttp.Request,
) {
	id, valid := positivePathID(r, "heatNetworkID")
	if !valid {
		writeJSON(
			w,
			nethttp.StatusBadRequest,
			errorResponse{Error: "heat network id must be a positive integer"},
		)
		return
	}

	sections, err := h.service.ListNetworkSections(r.Context(), id)
	if err != nil {
		h.writeServiceError(w, err)
		return
	}

	writeJSON(
		w,
		nethttp.StatusOK,
		newNetworkSectionsResponse(sections),
	)
}

type Handler struct {
	service Service
	logger  *slog.Logger
}

func New(service Service, logger *slog.Logger) *Handler {
	return &Handler{
		service: service,
		logger:  logger,
	}
}

func (h *Handler) GetQHValue(
	w nethttp.ResponseWriter,
	r *nethttp.Request,
) {
	id, valid := positivePathID(r, "networkSectionID")
	if !valid {
		writeJSON(
			w,
			nethttp.StatusBadRequest,
			errorResponse{Error: "network section id must be a positive integer"},
		)
		return
	}

	match, err := h.service.GetQHValue(r.Context(), id)
	if err != nil {
		h.writeServiceError(w, err)
		return
	}

	writeJSON(w, nethttp.StatusOK, newQHValueResponse(match))
}

func (h *Handler) writeServiceError(
	w nethttp.ResponseWriter,
	err error,
) {
	switch {
	case errors.Is(err, domain.ErrHeatNetworkNotFound),
		errors.Is(err, domain.ErrNetworkSectionNotFound),
		errors.Is(err, domain.ErrQHValueNotFound):
		writeJSON(
			w,
			nethttp.StatusNotFound,
			errorResponse{Error: err.Error()},
		)

	case errors.Is(err, domain.ErrAmbiguousQHValue):
		writeJSON(
			w,
			nethttp.StatusConflict,
			errorResponse{Error: err.Error()},
		)

	default:
		h.logger.Error(
			"section qh request failed",
			"error",
			err,
		)
		writeJSON(
			w,
			nethttp.StatusInternalServerError,
			errorResponse{Error: "failed to get qh_value"},
		)
	}
}

func positivePathID(
	r *nethttp.Request,
	name string,
) (int64, bool) {
	id, err := strconv.ParseInt(r.PathValue(name), 10, 64)

	return id, err == nil && id > 0
}

func writeJSON(
	w nethttp.ResponseWriter,
	status int,
	value any,
) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(value); err != nil {
		slog.Error("encode HTTP response", "error", err)
	}
}
