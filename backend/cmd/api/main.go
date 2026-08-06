package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	calculationpostgres "lostHeat/internal/calculation/adapters/postgres"
	"lostHeat/internal/calculation/calculators"
	calculationhttp "lostHeat/internal/calculation/delivery/http"
	calculationservice "lostHeat/internal/calculation/service"

	"lostHeat/internal/config"

	heatsourcepostgres "lostHeat/internal/heatsource/adapters/postgres"
	heatsourcehttp "lostHeat/internal/heatsource/delivery/http"
	heatsourceservice "lostHeat/internal/heatsource/service"

	"lostHeat/internal/platform/httpserver"
	platformpostgres "lostHeat/internal/platform/postgres"
)

func main() {
	logger := slog.New(
		slog.NewJSONHandler(
			os.Stdout,
			&slog.HandlerOptions{
				Level: slog.LevelInfo,
			},
		),
	)

	if err := run(logger); err != nil {
		logger.Error(
			"application stopped with error",
			"error",
			err,
		)

		os.Exit(1)
	}
}

func run(logger *slog.Logger) error {
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf(
			"load configuration: %w",
			err,
		)
	}

	connectionContext, connectionCancel :=
		context.WithTimeout(
			context.Background(),
			10*time.Second,
		)
	defer connectionCancel()

	db, err := platformpostgres.NewPool(
		connectionContext,
		cfg.DatabaseURL,
	)
	if err != nil {
		return fmt.Errorf(
			"connect to PostgreSQL: %w",
			err,
		)
	}
	defer db.Close()

	logger.Info("connected to PostgreSQL")

	/*
		Модуль heatsource
	*/

	heatSourceRepository :=
		heatsourcepostgres.NewRepository(db)

	heatSourceService :=
		heatsourceservice.New(
			heatSourceRepository,
		)

	heatSourceHandler :=
		heatsourcehttp.NewHandler(
			heatSourceService,
			logger,
		)

	/*
		Модуль calculation
	*/

	calculationRepository :=
		calculationpostgres.NewRepository(db)

	calculatorCatalog :=
		calculators.NewCalculatorCatalog()

	calculatorCatalog.MustRegister(
		"normative_section_heat_loss",
		calculators.NewNormativeSectionHeatLossCalculator(),
	)

	calculationService :=
		calculationservice.New(
			calculationRepository,
			calculatorCatalog,
		)

	calculationHandler :=
		calculationhttp.NewHandler(
			calculationService,
			logger,
		)

	/*
		HTTP-маршруты
	*/

	mux := http.NewServeMux()

	registerHeatSourceRoutes(
		mux,
		heatSourceHandler,
	)

	registerCalculationRoutes(
		mux,
		calculationHandler,
	)

	server := &http.Server{
		Addr: ":" + cfg.Port,

		Handler: httpserver.CORS(
			cfg.AllowOrigin,
		)(mux),

		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	shutdownContext, stop :=
		signal.NotifyContext(
			context.Background(),
			os.Interrupt,
			syscall.SIGTERM,
		)
	defer stop()

	serverErrors := make(chan error, 1)

	go func() {
		logger.Info(
			"HTTP server started",
			"address",
			server.Addr,
		)

		err := server.ListenAndServe()

		if err != nil &&
			!errors.Is(err, http.ErrServerClosed) {
			serverErrors <- err
		}
	}()

	select {
	case err := <-serverErrors:
		return fmt.Errorf(
			"HTTP server failed: %w",
			err,
		)

	case <-shutdownContext.Done():
		logger.Info("shutdown signal received")
	}

	gracefulContext, gracefulCancel :=
		context.WithTimeout(
			context.Background(),
			10*time.Second,
		)
	defer gracefulCancel()

	if err := server.Shutdown(gracefulContext); err != nil {
		return fmt.Errorf(
			"shutdown HTTP server: %w",
			err,
		)
	}

	logger.Info("HTTP server stopped")

	return nil
}

func registerHeatSourceRoutes(
	mux *http.ServeMux,
	handler *heatsourcehttp.Handler,
) {
	mux.HandleFunc(
		"GET /api/v1/boiler-houses",
		handler.ListBoilerHouses,
	)

	mux.HandleFunc(
		"GET /api/v1/network-types",
		handler.ListNetworkTypes,
	)

	mux.HandleFunc(
		"GET /api/v1/insulation-materials",
		handler.ListInsulationMaterials,
	)

	mux.HandleFunc(
		"GET /api/v1/laying-methods",
		handler.ListLayingMethods,
	)

	mux.HandleFunc(
		"GET /api/v1/soil-types",
		handler.ListSoilTypes,
	)

	mux.HandleFunc(
		"GET /api/v1/calculation-operations",
		handler.ListCalculationOperations,
	)
}

func registerCalculationRoutes(
	mux *http.ServeMux,
	handler *calculationhttp.Handler,
) {
	mux.HandleFunc(
		"POST /api/v1/calculations",
		handler.Calculate,
	)
}