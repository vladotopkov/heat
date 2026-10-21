package sectionqhhttp

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"lostHeat/internal/sectionqh/domain"
)

type serviceStub struct {
	match domain.Match
	err   error
}

func (stub serviceStub) ListHeatNetworks(
	_ context.Context,
) ([]domain.HeatNetwork, error) {
	return nil, stub.err
}

func (stub serviceStub) ListNetworkSections(
	_ context.Context,
	_ int64,
) (domain.HeatNetworkSections, error) {
	return domain.HeatNetworkSections{}, stub.err
}

func (stub serviceStub) GetQHValue(
	_ context.Context,
	_ int64,
) (domain.Match, error) {
	return stub.match, stub.err
}

func TestGetQHValueResponse(t *testing.T) {
	t.Parallel()

	handler := New(
		serviceStub{match: domain.Match{
			NetworkSectionID: 1,
			QHTableID:        1,
			QHValue: domain.QHValue{
				ID:           51,
				Value:        51.6,
				PipelineRole: textPointer("TWO_PIPE_TOTAL"),
			},
			MatchedFields: []string{"outer_diameter_mm=supply_outer_diameter_mm"},
		}},
		discardLogger(),
	)

	request := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/network-sections/1/qh-value",
		nil,
	)
	request.SetPathValue("networkSectionID", "1")
	response := httptest.NewRecorder()

	handler.GetQHValue(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	if !strings.Contains(response.Body.String(), `"qh_value":51.6`) {
		t.Errorf("body = %s, want qh_value 51.6", response.Body.String())
	}
}

func TestGetQHValueErrorStatuses(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		err        error
		wantStatus int
	}{
		{
			name:       "not found",
			err:        domain.ErrQHValueNotFound,
			wantStatus: http.StatusNotFound,
		},
		{
			name:       "ambiguous",
			err:        domain.ErrAmbiguousQHValue,
			wantStatus: http.StatusConflict,
		},
		{
			name:       "internal",
			err:        errors.New("database unavailable"),
			wantStatus: http.StatusInternalServerError,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()

			handler := New(
				serviceStub{err: test.err},
				discardLogger(),
			)
			request := httptest.NewRequest(http.MethodGet, "/", nil)
			request.SetPathValue("networkSectionID", "1")
			response := httptest.NewRecorder()

			handler.GetQHValue(response, request)

			if response.Code != test.wantStatus {
				t.Errorf(
					"status = %d, want %d",
					response.Code,
					test.wantStatus,
				)
			}
		})
	}
}

func discardLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func textPointer(value string) *string {
	return &value
}
