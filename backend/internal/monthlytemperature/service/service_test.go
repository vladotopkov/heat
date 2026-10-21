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
