package postgres_test

import (
	"context"
	"math"
	"os"
	"testing"

	"lostHeat/internal/platform/database"
	sectionqhpostgres "lostHeat/internal/sectionqh/adapters/postgres"
	sectionqhservice "lostHeat/internal/sectionqh/service"
)

func TestRepositoryAgainstDatabase(t *testing.T) {
	databaseURL := os.Getenv("TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("TEST_DATABASE_URL is not set")
	}

	ctx := context.Background()

	pool, err := database.NewPostgresPool(ctx, databaseURL)
	if err != nil {
		t.Fatalf("connect to test database: %v", err)
	}
	defer pool.Close()

	repository := sectionqhpostgres.New(pool)
	networks, err := repository.ListHeatNetworks(ctx)
	if err != nil {
		t.Fatalf("ListHeatNetworks() error = %v", err)
	}
	if len(networks) == 0 || networks[0].ID != 1 {
		t.Fatalf("ListHeatNetworks() = %#v, want network id=1", networks)
	}

	section, err := repository.GetNetworkSection(ctx, 1)
	if err != nil {
		t.Fatalf("GetNetworkSection() error = %v", err)
	}

	values, err := repository.ListQHValuesByTableID(ctx, section.QHTableID)
	if err != nil {
		t.Fatalf("ListQHValuesByTableID() error = %v", err)
	}
	if len(values) == 0 {
		t.Fatal("ListQHValuesByTableID() returned no rows")
	}

	betaValues, err := repository.ListBetaValues(ctx)
	if err != nil {
		t.Fatalf("ListBetaValues() error = %v", err)
	}
	if len(betaValues) != 22 {
		t.Fatalf("beta values count = %d, want 22", len(betaValues))
	}
	for _, value := range values {
		if value.QHTableID != section.QHTableID {
			t.Fatalf(
				"loaded qh_table_id=%d, want only %d",
				value.QHTableID,
				section.QHTableID,
			)
		}
	}

	match, err := sectionqhservice.New(repository).GetQHValue(ctx, 1)
	if err != nil {
		t.Fatalf("GetQHValue() error = %v", err)
	}

	if match.QHValue.ID != 51 {
		t.Errorf("selected qh_value id = %d, want 51", match.QHValue.ID)
	}
	if math.Abs(match.QHValue.Value-53.925) > 1e-9 {
		t.Errorf("selected qh_value = %v, want 53.925", match.QHValue.Value)
	}

	sections, err := sectionqhservice.New(repository).ListNetworkSections(ctx, 1)
	if err != nil {
		t.Fatalf("ListNetworkSections() error = %v", err)
	}
	if len(sections.Sections) != 34 {
		t.Fatalf("sections count = %d, want 34", len(sections.Sections))
	}
	if sections.Sections[0].QHValue == nil ||
		math.Abs(sections.Sections[0].QHValue.Value-53.925) > 1e-9 {
		t.Errorf(
			"first section qh_value = %#v, want 53.925",
			sections.Sections[0].QHValue,
		)
	}
	if sections.Sections[0].Beta == nil ||
		math.Abs(sections.Sections[0].Beta.Value-1) > 1e-9 {
		t.Errorf(
			"first section beta = %#v, want 1.00",
			sections.Sections[0].Beta,
		)
	}

	storedSection, err := repository.GetNetworkSection(ctx, 1)
	if err != nil {
		t.Fatalf("GetNetworkSection() after beta selection error = %v", err)
	}
	if storedSection.Beta == nil || math.Abs(*storedSection.Beta-1) > 1e-9 {
		t.Errorf("stored section beta = %#v, want 1.00", storedSection.Beta)
	}
}
