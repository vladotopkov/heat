package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"lostHeat/internal/monthlyuptime/domain"
)

type repositoryStub struct {
	rows          []domain.NetworkUptime
	saved         domain.NetworkUptime
	listMonth     time.Time
	saveMonth     time.Time
	saveNetworkID int64
	saveHours     int
}

func (stub *repositoryStub) ListForMonth(
	_ context.Context,
	month time.Time,
) ([]domain.NetworkUptime, error) {
	stub.listMonth = month
	return stub.rows, nil
}

func (stub *repositoryStub) Upsert(
	_ context.Context,
	heatNetworkID int64,
	month time.Time,
	hoursPerMonth int,
) (domain.NetworkUptime, error) {
	stub.saveNetworkID = heatNetworkID
	stub.saveMonth = month
	stub.saveHours = hoursPerMonth
	return stub.saved, nil
}

func TestListForMonthNormalizesToFirstDay(t *testing.T) {
	t.Parallel()

	stub := &repositoryStub{}
	_, err := New(stub).ListForMonth(
		context.Background(),
		time.Date(2026, time.August, 27, 12, 0, 0, 0, time.Local),
	)
	if err != nil {
		t.Fatalf("ListForMonth() error = %v", err)
	}

	if got := stub.listMonth.Format("2006-01-02"); got != "2026-08-01" {
		t.Errorf("repository month = %s, want 2026-08-01", got)
	}
}

func TestSavePassesHoursToRepository(t *testing.T) {
	t.Parallel()

	stub := &repositoryStub{saved: domain.NetworkUptime{HeatNetworkID: 3}}
	_, err := New(stub).Save(
		context.Background(),
		3,
		time.Date(2026, time.August, 1, 0, 0, 0, 0, time.UTC),
		720,
	)
	if err != nil {
		t.Fatalf("Save() error = %v", err)
	}

	if stub.saveNetworkID != 3 || stub.saveHours != 720 {
		t.Errorf(
			"repository call = id %d, hours %d; want id 3, hours 720",
			stub.saveNetworkID,
			stub.saveHours,
		)
	}
}

func TestSaveRejectsHoursOutsideDatabaseRange(t *testing.T) {
	t.Parallel()

	for _, hours := range []int{-1, 745} {
		_, err := New(&repositoryStub{}).Save(
			context.Background(),
			1,
			time.Date(2026, time.August, 1, 0, 0, 0, 0, time.UTC),
			hours,
		)
		if !errors.Is(err, domain.ErrInvalidHours) {
			t.Errorf("Save(hours=%d) error = %v, want ErrInvalidHours", hours, err)
		}
	}
}
