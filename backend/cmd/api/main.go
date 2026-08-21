package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"

	"lostHeat/internal/platform/database"
	platformhttp "lostHeat/internal/platform/http"

	"lostHeat/internal/qh/application"
	qhhttp "lostHeat/internal/qh/http"
	qhpostgres "lostHeat/internal/qh/postgres"
)

func main() {

	ctx :=
		context.Background()

	databaseURL :=
		os.Getenv(
			"DATABASE_URL",
		)

	if databaseURL == "" {
		log.Fatal(
			"DATABASE_URL is required",
		)
	}

	port :=
		os.Getenv(
			"PORT",
		)

	if port == "" {
		port = "8080"
	}

	// =========================================================
	// DATABASE
	// =========================================================

	pool, err :=
		database.NewPostgresPool(
			ctx,
			databaseURL,
		)

	if err != nil {
		log.Fatalf(
			"connect to database: %v",
			err,
		)
	}

	defer pool.Close()

	// =========================================================
	// REPOSITORIES
	// =========================================================

	sessionRepository :=
		qhpostgres.NewSessionRepository(
			pool,
		)

	answerRepository :=
		qhpostgres.NewAnswerRepository(
			pool,
		)

	questionRepository :=
		qhpostgres.NewQuestionRepository(
			pool,
		)

	selectionRuleRepository :=
		qhpostgres.NewSelectionRuleRepository(
			pool,
		)

	qhTableRepository :=
		qhpostgres.NewQHTableRepository(
			pool,
		)

	tableDimensionRepository :=
		qhpostgres.NewTableDimensionRepository(
			pool,
		)

	rowRepository :=
		qhpostgres.NewRowRepository(
			pool,
		)

	temperatureRegimeRepository :=
		qhpostgres.NewTemperatureRegimeRepository(
			pool,
		)

	qhValueRepository :=
		qhpostgres.NewQHValueRepository(
			pool,
		)

	qhResultRepository :=
		qhpostgres.NewQHResultRepository(
			pool,
		)

	// =========================================================
	// TABLE SELECTION
	// =========================================================

	tableSelectionResolver :=
		application.NewTableSelectionResolver(
			sessionRepository,
			answerRepository,
			selectionRuleRepository,
			questionRepository,
			qhTableRepository,
		)

	// =========================================================
	// ROW SELECTION
	// =========================================================

	rowSelectionResolver :=
		application.NewRowSelectionResolver(
			sessionRepository,
			answerRepository,
			questionRepository,
			tableDimensionRepository,
			rowRepository,
		)

	// =========================================================
	// QH
	// =========================================================

	qhResolver :=
		application.NewQHResolver(
			sessionRepository,
			answerRepository,
			questionRepository,
			temperatureRegimeRepository,
			qhValueRepository,
			qhResultRepository,
		)

	// =========================================================
	// ОБЩИЙ QUESTIONNAIRE RESOLVER
	// =========================================================

	questionnaireResolver :=
		application.NewQuestionnaireResolver(
			sessionRepository,
			qhTableRepository,
			tableSelectionResolver,
			rowSelectionResolver,
			qhResolver,
		)

	// =========================================================
	// USE CASES
	// =========================================================

	startSession :=
		application.NewStartSession(
			sessionRepository,
			questionnaireResolver,
		)

	processAnswer :=
		application.NewProcessAnswer(
			answerRepository,
			questionnaireResolver,
		)

	// =========================================================
	// HTTP
	// =========================================================

	qhHandler :=
		qhhttp.NewHandler(
			startSession,
			processAnswer,
		)

	router :=
		platformhttp.NewRouter(
			qhHandler,
		)

	server :=
		&http.Server{
			Addr:
				":" + port,

			Handler:
				router,
		}

	log.Printf(
		"API listening on :%s",
		port,
	)

	err =
		server.ListenAndServe()

	if err != nil &&
		!errors.Is(
			err,
			http.ErrServerClosed,
		) {

		log.Fatalf(
			"http server: %v",
			err,
		)
	}
}