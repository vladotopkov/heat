package http

import (
	nethttp "net/http"

	qhhttp "lostHeat/internal/qh/http"
)

func NewRouter(
	qhHandler *qhhttp.Handler,
) nethttp.Handler {

	mux :=
		nethttp.NewServeMux()

	mux.HandleFunc(
		"POST /api/v1/qh/sessions",
		qhHandler.StartSession,
	)

	mux.HandleFunc(
		"POST /api/v1/qh/sessions/{sessionID}/answers",
		qhHandler.SubmitAnswer,
	)

	return mux
}