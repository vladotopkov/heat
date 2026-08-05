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

	"lostHeat/internal/config"
	heatsourcepostgres "lostHeat/internal/heatsource/adapters/postgres"
	heatsourcehttp "lostHeat/internal/heatsource/delivery/http"
	"lostHeat/internal/heatsource/service"
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
	// 1. Загружаем конфигурацию.
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf(
			"load configuration: %w",
			err,
		)
	}

	// 2. Ограничиваем время подключения к PostgreSQL.
	connectionContext, connectionCancel :=
		context.WithTimeout(
			context.Background(),
			10*time.Second,
		)
	defer connectionCancel()

	// 3. Создаём общий пул соединений с PostgreSQL.
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

	// 4. Создаём PostgreSQL adapter модуля heatsource.
	heatSourceRepository :=
		heatsourcepostgres.NewRepository(db)

	// 5. Создаём service модуля heatsource.
	heatSourceService :=
		service.New(heatSourceRepository)

	// 6. Создаём HTTP handler модуля heatsource.
	heatSourceHandler :=
		heatsourcehttp.NewHandler(
			heatSourceService,
			logger,
		)

	// 7. Регистрируем маршруты.
	mux := http.NewServeMux()

	mux.HandleFunc(
		"GET /api/v1/boiler-houses",
		heatSourceHandler.ListBoilerHouses,
	)

	mux.HandleFunc(
		"GET /api/v1/network-types",
		heatSourceHandler.ListNetworkTypes,
	)

	mux.HandleFunc(
		"GET /api/v1/insulation-materials",
		heatSourceHandler.ListInsulationMaterials,
	)

	mux.HandleFunc(
		"GET /api/v1/laying-methods",
		heatSourceHandler.ListLayingMethods,
	)

	mux.HandleFunc(
		"GET /api/v1/soil-types",
		heatSourceHandler.ListSoilTypes,
	)

	// 8. Создаём HTTP-сервер.
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

	// 9. Создаём контекст, который завершится после Ctrl+C
	// или SIGTERM от Docker.
	shutdownContext, stop :=
		signal.NotifyContext(
			context.Background(),
			os.Interrupt,
			syscall.SIGTERM,
		)
	defer stop()

	serverErrors := make(chan error, 1)

	// 10. Запускаем HTTP-сервер в отдельной goroutine.
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

	// 11. Ждём либо ошибку сервера, либо сигнал остановки.
	select {
	case err := <-serverErrors:
		return fmt.Errorf(
			"HTTP server failed: %w",
			err,
		)

	case <-shutdownContext.Done():
		logger.Info("shutdown signal received")
	}

	// 12. Даём активным запросам до 10 секунд на завершение.
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
