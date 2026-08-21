package application

import (
	"context"
	"fmt"

	"lostHeat/internal/qh/domain"
	"lostHeat/internal/qh/ports"
)

type StartSession struct {
	sessions ports.SessionRepository

	resolver *QuestionnaireResolver
}

func NewStartSession(
	sessions ports.SessionRepository,
	resolver *QuestionnaireResolver,
) *StartSession {

	return &StartSession{
		sessions: sessions,
		resolver: resolver,
	}
}

func (uc *StartSession) Execute(
	ctx context.Context,
) (*QuestionnaireState, error) {

	// =========================================================
	// 1. Создаём новую session
	// =========================================================

	session, err :=
		uc.sessions.Create(
			ctx,
		)

	if err != nil {
		return nil, fmt.Errorf(
			"create questionnaire session: %w",
			err,
		)
	}

	// =========================================================
	// 2. Определяем первый вопрос
	//
	// Сейчас QuestionnaireResolver увидит:
	//
	// selected_qh_table_id = NULL
	//
	// и вызовет TableSelectionResolver.
	// =========================================================

	state, err :=
		uc.resolver.Resolve(
			ctx,
			session.ID,
		)

	if err != nil {

		// Если после создания session произошла ошибка,
		// отмечаем её.
		_ = uc.sessions.SetStatus(
			ctx,
			session.ID,
			domain.QuestionnaireStatusError,
		)

		return nil, fmt.Errorf(
			"resolve initial questionnaire state: %w",
			err,
		)
	}

	return state, nil
}