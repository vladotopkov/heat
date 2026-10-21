package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"time"

	"lostHeat/internal/config"
	monthlylosspostgres "lostHeat/internal/monthlyloss/adapters/postgres"
	monthlylosshttp "lostHeat/internal/monthlyloss/delivery/http"
	monthlylossservice "lostHeat/internal/monthlyloss/service"
	monthlytemperaturepostgres "lostHeat/internal/monthlytemperature/adapters/postgres"
	monthlytemperaturehttp "lostHeat/internal/monthlytemperature/delivery/http"
	monthlytemperatureservice "lostHeat/internal/monthlytemperature/service"
	monthlyuptimepostgres "lostHeat/internal/monthlyuptime/adapters/postgres"
	monthlyuptimehttp "lostHeat/internal/monthlyuptime/delivery/http"
	monthlyuptimeservice "lostHeat/internal/monthlyuptime/service"
	"lostHeat/internal/platform/database"
	platformhttp "lostHeat/internal/platform/http"
	sectionqhpostgres "lostHeat/internal/sectionqh/adapters/postgres"
	sectionqhhttp "lostHeat/internal/sectionqh/delivery/http"
	sectionqhservice "lostHeat/internal/sectionqh/service"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	cfg, err := config.Load()
	if err != nil {
		logger.Error("load configuration", "error", err)
		os.Exit(1)
	}

	ctx := context.Background()

	pool, err := database.NewPostgresPool(ctx, cfg.DatabaseURL)
	if err != nil {
		logger.Error("connect to database", "error", err)
		os.Exit(1)
	}
	defer pool.Close()

	repository := sectionqhpostgres.New(pool)
	sectionQHService := sectionqhservice.New(repository)
	sectionQHHandler := sectionqhhttp.New(sectionQHService, logger)
	monthlyTemperatureRepository := monthlytemperaturepostgres.New(pool)
	monthlyTemperatureService := monthlytemperatureservice.New(
		monthlyTemperatureRepository,
	)
	monthlyTemperatureHandler := monthlytemperaturehttp.New(
		monthlyTemperatureService,
		logger,
	)
	monthlyUptimeRepository := monthlyuptimepostgres.New(pool)
	monthlyUptimeService := monthlyuptimeservice.New(monthlyUptimeRepository)
	monthlyUptimeHandler := monthlyuptimehttp.New(
		monthlyUptimeService,
		logger,
	)
	monthlyLossRepository := monthlylosspostgres.New(pool)
	monthlyLossService := monthlylossservice.New(
		monthlyLossRepository,
		sectionQHService,
	)
	monthlyLossHandler := monthlylosshttp.New(monthlyLossService, logger)

	server := &http.Server{
		Addr: ":" + cfg.Port,
		Handler: platformhttp.NewRouter(
			sectionQHHandler,
			monthlyTemperatureHandler,
			monthlyUptimeHandler,
			monthlyLossHandler,
		),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	logger.Info("API listening", "address", server.Addr)

	if err := server.ListenAndServe(); err != nil &&
		!errors.Is(err, http.ErrServerClosed) {
		logger.Error("HTTP server stopped", "error", err)
		os.Exit(1)
	}
}
