package monthlytemperaturehttp

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"lostHeat/internal/monthlytemperature/domain"
)

type serviceStub struct {
	rows          []domain.NetworkTemperature
	saved         domain.NetworkTemperature
	listMonth     time.Time
	saveMonth     time.Time
	saveNetworkID int64
	saveValues    domain.Values
	err           error
}

func (stub *serviceStub) ListForMonth(
	_ context.Context,
	month time.Time,
) ([]domain.NetworkTemperature, error) {
	stub.listMonth = month
	return stub.rows, stub.err
}

func (stub *serviceStub) Save(
	_ context.Context,
	heatNetworkID int64,
	month time.Time,
	values domain.Values,
) (domain.NetworkTemperature, error) {
	stub.saveNetworkID = heatNetworkID
	stub.saveMonth = month
	stub.saveValues = values
	return stub.saved, stub.err
}

func TestListResponseIncludesNetworksWithoutValues(t *testing.T) {
	t.Parallel()

	stub := &serviceStub{rows: []domain.NetworkTemperature{{
		HeatNetworkID:   1,
		HeatNetworkName: "Network 1",
		Month:           time.Date(2026, time.August, 1, 0, 0, 0, 0, time.UTC),
	}}}
	handler := New(stub, discardLogger())
	request := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/temperatures?month=2026-08",
		nil,
	)
	response := httptest.NewRecorder()

	handler.List(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	for _, part := range []string{
		`"month":"2026-08"`,
		`"heat_network_name":"Network 1"`,
		`"supply_t":null`,
	} {
		if !strings.Contains(response.Body.String(), part) {
			t.Errorf("body = %s, want %s", response.Body.String(), part)
		}
	}
}

func TestSaveRequest(t *testing.T) {
	t.Parallel()

	supply := 90.5
	returnTemperature := 50.25
	ground := 8.75
	stub := &serviceStub{saved: domain.NetworkTemperature{
		HeatNetworkID:   3,
		HeatNetworkName: "Network 3",
		Month:           time.Date(2026, time.August, 1, 0, 0, 0, 0, time.UTC),
		Supply:          &supply,
		Return:          &returnTemperature,
		Ground:          &ground,
	}}
	handler := New(stub, discardLogger())
	request := httptest.NewRequest(
		http.MethodPut,
		"/api/v1/heat-networks/3/temperatures/2026-08",
		strings.NewReader(`{"supply_t":90.5,"return_t":50.25,"ground_t":8.75}`),
	)
	request.SetPathValue("heatNetworkID", "3")
	request.SetPathValue("month", "2026-08")
	response := httptest.NewRecorder()

	handler.Save(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
	if stub.saveNetworkID != 3 || stub.saveValues.Supply != 90.5 ||
		stub.saveValues.Return != 50.25 || stub.saveValues.Ground != 8.75 {
		t.Errorf(
			"service Save() = id %d, values %#v",
			stub.saveNetworkID,
			stub.saveValues,
		)
	}
	if !strings.Contains(response.Body.String(), `"heat_network_id":3`) {
		t.Errorf("body = %s, want heat_network_id=3", response.Body.String())
	}
}

func TestSaveRejectsMissingField(t *testing.T) {
	t.Parallel()

	handler := New(&serviceStub{}, discardLogger())
	request := httptest.NewRequest(
		http.MethodPut,
		"/api/v1/heat-networks/3/temperatures/2026-08",
		strings.NewReader(`{"supply_t":90.5,"return_t":50.25}`),
	)
	request.SetPathValue("heatNetworkID", "3")
	request.SetPathValue("month", "2026-08")
	response := httptest.NewRecorder()

	handler.Save(response, request)

	if response.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusBadRequest)
	}
}

func TestSaveGVSRequest(t *testing.T) {
	t.Parallel()
	supply, returnT := 65.5, 40.25
	stub := &serviceStub{saved: domain.NetworkTemperature{
		HeatNetworkID: 2,
		Month:         time.Date(2026, time.October, 1, 0, 0, 0, 0, time.UTC),
		GVSSupply:     &supply, GVSReturn: &returnT,
	}}
	request := httptest.NewRequest(http.MethodPut,
		"/api/v1/heat-networks/2/temperatures/2026-10",
		strings.NewReader(`{"supply_t":90,"return_t":50,"ground_t":8,"gvs_supply_t":65.5,"gvs_return_t":40.25}`))
	request.SetPathValue("heatNetworkID", "2")
	request.SetPathValue("month", "2026-10")
	response := httptest.NewRecorder()
	New(stub, discardLogger()).Save(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
	if stub.saveNetworkID != 2 || stub.saveMonth.Format("2006-01") != "2026-10" ||
		stub.saveValues.GVSSupply == nil || *stub.saveValues.GVSSupply != supply ||
		stub.saveValues.GVSReturn == nil || *stub.saveValues.GVSReturn != returnT {
		t.Fatalf("unexpected save: %#v", stub)
	}
	for _, part := range []string{`"gvs_supply_t":65.5`, `"gvs_return_t":40.25`} {
		if !strings.Contains(response.Body.String(), part) {
			t.Errorf("body = %s, want %s", response.Body.String(), part)
		}
	}
}

func discardLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}
