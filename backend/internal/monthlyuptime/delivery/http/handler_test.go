package monthlyuptimehttp

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"lostHeat/internal/monthlyuptime/domain"
)

type serviceStub struct {
	rows          []domain.NetworkUptime
	saved         domain.NetworkUptime
	saveNetworkID int64
	saveHours     int
}

func (stub *serviceStub) ListForMonth(
	_ context.Context,
	_ time.Time,
) ([]domain.NetworkUptime, error) {
	return stub.rows, nil
}

func (stub *serviceStub) Save(
	_ context.Context,
	heatNetworkID int64,
	_ time.Time,
	hoursPerMonth int,
) (domain.NetworkUptime, error) {
	stub.saveNetworkID = heatNetworkID
	stub.saveHours = hoursPerMonth
	return stub.saved, nil
}

func TestListResponseIncludesNetworkWithoutHours(t *testing.T) {
	t.Parallel()

	stub := &serviceStub{rows: []domain.NetworkUptime{{
		HeatNetworkID:   1,
		HeatNetworkName: "Network 1",
		Month:           time.Date(2026, time.August, 1, 0, 0, 0, 0, time.UTC),
	}}}
	handler := New(stub, discardLogger())
	request := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/uptime?month=2026-08",
		nil,
	)
	response := httptest.NewRecorder()

	handler.List(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	for _, part := range []string{
		`"heat_network_name":"Network 1"`,
		`"hours_per_month":null`,
	} {
		if !strings.Contains(response.Body.String(), part) {
			t.Errorf("body = %s, want %s", response.Body.String(), part)
		}
	}
}

func TestSaveRequest(t *testing.T) {
	t.Parallel()

	hours := 720
	stub := &serviceStub{saved: domain.NetworkUptime{
		HeatNetworkID:   3,
		HeatNetworkName: "Network 3",
		Month:           time.Date(2026, time.August, 1, 0, 0, 0, 0, time.UTC),
		HoursPerMonth:   &hours,
	}}
	handler := New(stub, discardLogger())
	request := httptest.NewRequest(
		http.MethodPut,
		"/api/v1/heat-networks/3/uptime/2026-08",
		strings.NewReader(`{"hours_per_month":720}`),
	)
	request.SetPathValue("heatNetworkID", "3")
	request.SetPathValue("month", "2026-08")
	response := httptest.NewRecorder()

	handler.Save(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
	if stub.saveNetworkID != 3 || stub.saveHours != 720 {
		t.Errorf(
			"service Save() = id %d, hours %d; want id 3, hours 720",
			stub.saveNetworkID,
			stub.saveHours,
		)
	}
}

func TestSaveRejectsFractionalHours(t *testing.T) {
	t.Parallel()

	handler := New(&serviceStub{}, discardLogger())
	request := httptest.NewRequest(
		http.MethodPut,
		"/api/v1/heat-networks/3/uptime/2026-08",
		strings.NewReader(`{"hours_per_month":720.5}`),
	)
	request.SetPathValue("heatNetworkID", "3")
	request.SetPathValue("month", "2026-08")
	response := httptest.NewRecorder()

	handler.Save(response, request)

	if response.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusBadRequest)
	}
}

func discardLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}
