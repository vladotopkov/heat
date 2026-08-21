package http

import (
	"encoding/json"
	"log"
	nethttp "net/http"
	"strconv"
	"time"

	"lostHeat/internal/qh/application"
	"lostHeat/internal/qh/domain"
)

type Handler struct {
	startSession *application.StartSession

	processAnswer *application.ProcessAnswer
}

func NewHandler(
	startSession *application.StartSession,
	processAnswer *application.ProcessAnswer,
) *Handler {

	return &Handler{
		startSession:
			startSession,

		processAnswer:
			processAnswer,
	}
}

// ============================================================
// POST /api/v1/qh/sessions
// ============================================================

func (h *Handler) StartSession(
	w nethttp.ResponseWriter,
	r *nethttp.Request,
) {

	state, err :=
		h.startSession.Execute(
			r.Context(),
		)

	if err != nil {

		log.Printf(
			"start questionnaire: %v",
			err,
		)

		writeJSON(
			w,
			nethttp.StatusInternalServerError,
			ErrorResponse{
				Error:
					"failed to start questionnaire",
			},
		)

		return
	}

	writeJSON(
		w,
		nethttp.StatusCreated,
		newQuestionnaireStateResponse(
			state,
		),
	)
}

// ============================================================
// POST /api/v1/qh/sessions/{sessionID}/answers
// ============================================================

func (h *Handler) SubmitAnswer(
	w nethttp.ResponseWriter,
	r *nethttp.Request,
) {

	// =========================================================
	// 1. SESSION ID ИЗ URL
	// =========================================================

	sessionIDText :=
		r.PathValue(
			"sessionID",
		)

	sessionID, err :=
		strconv.ParseInt(
			sessionIDText,
			10,
			64,
		)

	if err != nil ||
		sessionID <= 0 {

		writeJSON(
			w,
			nethttp.StatusBadRequest,
			ErrorResponse{
				Error:
					"invalid session id",
			},
		)

		return
	}

	// =========================================================
	// 2. ЧИТАЕМ JSON
	// =========================================================

	var request SubmitAnswerRequest

	err =
		json.NewDecoder(
			r.Body,
		).Decode(
			&request,
		)

	if err != nil {

		writeJSON(
			w,
			nethttp.StatusBadRequest,
			ErrorResponse{
				Error:
					"invalid request body",
			},
		)

		return
	}

	if request.QuestionCode == "" {

		writeJSON(
			w,
			nethttp.StatusBadRequest,
			ErrorResponse{
				Error:
					"question_code is required",
			},
		)

		return
	}

	// =========================================================
	// 3. HTTP DTO → DOMAIN
	// =========================================================

	answer :=
		domain.QuestionnaireAnswer{
			SessionID:
				sessionID,

			QuestionCode:
				request.QuestionCode,

			ValueText:
				request.ValueText,

			ValueNumeric:
				request.ValueNumeric,

			ValueBoolean:
				request.ValueBoolean,
		}

	// =========================================================
	// 4. DATE: STRING → time.Time
	// =========================================================

	if request.ValueDate != nil {

		value, err :=
			time.Parse(
				"2006-01-02",
				*request.ValueDate,
			)

		if err != nil {

			writeJSON(
				w,
				nethttp.StatusBadRequest,
				ErrorResponse{
					Error:
						"invalid date format, expected YYYY-MM-DD",
				},
			)

			return
		}

		answer.ValueDate =
			&value
	}

	// =========================================================
	// 5. APPLICATION
	// =========================================================

	state, err :=
		h.processAnswer.Execute(
			r.Context(),
			answer,
		)

	if err != nil {

		log.Printf(
			"process questionnaire answer: %v",
			err,
		)

		writeJSON(
			w,
			nethttp.StatusBadRequest,
			ErrorResponse{
				Error:
					err.Error(),
			},
		)

		return
	}

	// =========================================================
	// 6. ОТПРАВЛЯЕМ НОВОЕ СОСТОЯНИЕ FRONTEND
	// =========================================================

	writeJSON(
		w,
		nethttp.StatusOK,
		newQuestionnaireStateResponse(
			state,
		),
	)
}

func writeJSON(
	w nethttp.ResponseWriter,
	status int,
	data any,
) {

	w.Header().Set(
		"Content-Type",
		"application/json",
	)

	w.WriteHeader(
		status,
	)

	if err :=
		json.NewEncoder(
			w,
		).Encode(
			data,
		); err != nil {

		log.Printf(
			"encode response: %v",
			err,
		)
	}
}