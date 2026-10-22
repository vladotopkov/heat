package postgres

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"lostHeat/internal/monthlytemperature/domain"
)

// Use an empty, dedicated test database. All fixtures are rolled back.
func TestTemperaturesByNetworkMonthAndType(t *testing.T) {
	url := os.Getenv("TEST_TEMPERATURE_DATABASE_URL")
	if url == "" {
		t.Skip("TEST_TEMPERATURE_DATABASE_URL is not set")
	}
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, url)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback(ctx)
	_, err = tx.Exec(ctx, `
		CREATE TABLE public."HeatNetwork" (id bigint PRIMARY KEY, name text NOT NULL);
		CREATE TABLE public.temperatures (
			id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
			heat_network_id bigint NOT NULL REFERENCES public."HeatNetwork"(id),
			month date NOT NULL,
			supply_t numeric(6,2) NOT NULL,
			return_t numeric(6,2) NOT NULL,
			ground_t numeric(6,2) NOT NULL,
			network_type varchar(20) NOT NULL DEFAULT 'HEATING' CHECK (network_type IN ('HEATING', 'GVS')),
			UNIQUE (heat_network_id, month, network_type)
		);
		INSERT INTO public."HeatNetwork" VALUES (1, 'Other network'), (2, 'Military town');
	`)
	if err != nil {
		t.Fatal(err)
	}
	repo := &Repository{pool: tx}
	month := time.Date(2026, time.October, 1, 0, 0, 0, 0, time.UTC)
	rows, err := repo.ListForMonth(ctx, month)
	if err != nil || len(rows) != 2 {
		t.Fatalf("empty month rows = %#v, error = %v", rows, err)
	}
	for _, row := range rows {
		if row.ID != nil || row.GVSSupply != nil {
			t.Fatalf("unexpected temperatures: %#v", row)
		}
	}
	gvsSupply, gvsReturn := 65.5, 40.25
	values := domain.Values{Supply: 90, Return: 50, Ground: 8, GVSSupply: &gvsSupply, GVSReturn: &gvsReturn}
	saved, err := repo.Upsert(ctx, 2, month, values)
	if err != nil {
		t.Fatal(err)
	}
	if saved.GVSSupply == nil || *saved.GVSSupply != gvsSupply || saved.GVSReturn == nil || *saved.GVSReturn != gvsReturn {
		t.Fatalf("GVS not returned: %#v", saved)
	}
	var gvsID int64
	var ground float64
	err = tx.QueryRow(ctx, `SELECT id, ground_t FROM public.temperatures WHERE heat_network_id=2 AND month=$1 AND network_type='GVS'`, month).Scan(&gvsID, &ground)
	if err != nil || ground != 8 {
		t.Fatalf("GVS row: ground = %v, error = %v", ground, err)
	}
	gvsSupply, values.Ground = 66.75, 9
	updated, err := repo.Upsert(ctx, 2, month, values)
	if err != nil {
		t.Fatal(err)
	}
	if *updated.ID != *saved.ID || *updated.GVSSupply != 66.75 {
		t.Fatalf("unexpected update: %#v", updated)
	}
	var updatedGVSID int64
	err = tx.QueryRow(ctx, `SELECT id, ground_t FROM public.temperatures WHERE heat_network_id=2 AND month=$1 AND network_type='GVS'`, month).Scan(&updatedGVSID, &ground)
	if err != nil || updatedGVSID != gvsID || ground != 9 {
		t.Fatalf("GVS update: id = %d, ground = %v, error = %v", updatedGVSID, ground, err)
	}
	values.GVSSupply, values.GVSReturn = nil, nil
	saved, err = repo.Upsert(ctx, 2, month, values)
	if err != nil || saved.GVSSupply == nil || *saved.GVSSupply != 66.75 {
		t.Fatalf("heating update lost GVS: %#v, %v", saved, err)
	}
	if _, err = repo.Upsert(ctx, 1, month, values); err != nil {
		t.Fatal(err)
	}
	nextMonth := month.AddDate(0, 1, 0)
	if _, err = repo.Upsert(ctx, 2, nextMonth, values); err != nil {
		t.Fatal(err)
	}
	rows, err = repo.ListForMonth(ctx, month)
	if err != nil || len(rows) != 2 {
		t.Fatalf("month rows = %#v, error = %v", rows, err)
	}
	for _, row := range rows {
		if row.HeatNetworkID == 2 && (row.GVSSupply == nil || *row.GVSSupply != 66.75 || *row.Supply != 90) {
			t.Fatalf("mixed network types: %#v", row)
		}
		if row.HeatNetworkID == 1 && row.GVSSupply != nil {
			t.Fatalf("GVS on other network: %#v", row)
		}
	}
	rows, err = repo.ListForMonth(ctx, nextMonth)
	if err != nil {
		t.Fatal(err)
	}
	for _, row := range rows {
		if row.GVSSupply != nil {
			t.Fatalf("GVS leaked into another month: %#v", row)
		}
	}
	var count int
	if err = tx.QueryRow(ctx, `SELECT count(*) FROM public.temperatures`).Scan(&count); err != nil || count != 4 {
		t.Fatalf("row count = %d, want 4; error = %v", count, err)
	}
	if _, err = repo.Upsert(ctx, 999, month, values); !errors.Is(err, domain.ErrHeatNetworkNotFound) {
		t.Fatalf("missing network error = %v", err)
	}
}
