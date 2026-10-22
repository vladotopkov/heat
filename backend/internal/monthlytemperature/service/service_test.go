package service

import (
	"context"
	"errors"
	"math"
	"testing"
	"time"

	"lostHeat/internal/monthlytemperature/domain"
)

type repositoryStub struct {
	rows          []domain.NetworkTemperature
	saved         domain.NetworkTemperature
	listMonth     time.Time
	saveMonth     time.Time
	saveNetworkID int64
	saveValues    domain.Values
	listErr       error
	saveErr       error
}

func (stub *repositoryStub) ListForMonth(
	_ context.Context,
	month time.Time,
) ([]domain.NetworkTemperature, error) {
	stub.listMonth = month
	return stub.rows, stub.listErr
}

func (stub *repositoryStub) Upsert(
	_ context.Context,
	heatNetworkID int64,
	month time.Time,
	values domain.Values,
) (domain.NetworkTemperature, error) {
	stub.saveNetworkID = heatNetworkID
	stub.saveMonth = month
	stub.saveValues = values
	return stub.saved, stub.saveErr
}

func TestListForMonthNormalizesToFirstDay(t *testing.T) {
	t.Parallel()

	stub := &repositoryStub{}
	_, err := New(stub).ListForMonth(
		context.Background(),
		time.Date(2026, time.August, 27, 12, 30, 0, 0, time.Local),
	)
	if err != nil {
		t.Fatalf("ListForMonth() error = %v", err)
	}

	if got := stub.listMonth.Format("2006-01-02"); got != "2026-08-01" {
		t.Errorf("repository month = %s, want 2026-08-01", got)
	}
}

func TestSavePassesValidatedValuesToRepository(t *testing.T) {
	t.Parallel()

	want := domain.NetworkTemperature{HeatNetworkID: 7}
	stub := &repositoryStub{saved: want}
	values := domain.Values{Supply: 91.25, Return: 51.5, Ground: 7.75}

	got, err := New(stub).Save(
		context.Background(),
		7,
		time.Date(2026, time.August, 1, 0, 0, 0, 0, time.UTC),
		values,
	)
	if err != nil {
		t.Fatalf("Save() error = %v", err)
	}

	if got.HeatNetworkID != want.HeatNetworkID {
		t.Errorf("Save() result = %#v, want %#v", got, want)
	}
	if stub.saveNetworkID != 7 || stub.saveValues != values {
		t.Errorf(
			"repository call = id %d, values %#v; want id 7, values %#v",
			stub.saveNetworkID,
			stub.saveValues,
			values,
		)
	}
}

func TestSaveRejectsInvalidTemperature(t *testing.T) {
	t.Parallel()

	stub := &repositoryStub{}
	_, err := New(stub).Save(
		context.Background(),
		1,
		time.Date(2026, time.August, 1, 0, 0, 0, 0, time.UTC),
		domain.Values{Supply: math.Inf(1)},
	)

	if !errors.Is(err, domain.ErrInvalidTemperature) {
		t.Fatalf("Save() error = %v, want ErrInvalidTemperature", err)
	}
}

func TestSaveGVSValidation(t *testing.T) {
	t.Parallel()
	ptr := func(value float64) *float64 { return &value }
	for _, tc := range []struct {
		name            string
		networkID       int64
		supply, returnT *float64
		valid           bool
	}{
		{name: "military town", networkID: 2, supply: ptr(65.5), returnT: ptr(40), valid: true},
		{name: "zero temperatures", networkID: 2, supply: ptr(0), returnT: ptr(0), valid: true},
		{name: "heating only", networkID: 2, valid: true},
		{name: "other network", networkID: 1, supply: ptr(65), returnT: ptr(40)},
		{name: "missing return", networkID: 2, supply: ptr(65)},
		{name: "missing supply", networkID: 2, returnT: ptr(40)},
		{name: "out of range", networkID: 2, supply: ptr(10000), returnT: ptr(40)},
		{name: "not finite", networkID: 2, supply: ptr(65), returnT: ptr(math.NaN())},
	} {
		t.Run(tc.name, func(t *testing.T) {
			stub := &repositoryStub{}
			values := domain.Values{Supply: 90, Return: 50, Ground: 8, GVSSupply: tc.supply, GVSReturn: tc.returnT}
			_, err := New(stub).Save(context.Background(), tc.networkID,
				time.Date(2026, time.October, 21, 0, 0, 0, 0, time.UTC), values)
			if tc.valid {
				if err != nil {
					t.Fatal(err)
				}
				if stub.saveValues != values || stub.saveMonth.Format("2006-01-02") != "2026-10-01" {
					t.Fatalf("unexpected save: %#v at %s", stub.saveValues, stub.saveMonth)
				}
			} else if !errors.Is(err, domain.ErrInvalidTemperature) || stub.saveNetworkID != 0 {
				t.Fatalf("invalid values reached repository or wrong error: %v", err)
			}
		})
	}
}
