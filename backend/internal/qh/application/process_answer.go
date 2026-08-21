package application

import (
	"context"
	"fmt"

	"lostHeat/internal/qh/domain"
	"lostHeat/internal/qh/ports"
)

type ProcessAnswer struct {
	answers ports.AnswerRepository

	resolver *QuestionnaireResolver
}

func NewProcessAnswer(
	answers ports.AnswerRepository,
	resolver *QuestionnaireResolver,
) *ProcessAnswer {

	return &ProcessAnswer{
		answers:  answers,
		resolver: resolver,
	}
}

func (uc *ProcessAnswer) Execute(
	ctx context.Context,
	answer domain.QuestionnaireAnswer,
) (*QuestionnaireState, error) {

	// =========================================================
	// 1. Узнаём, какой вопрос backend ожидает СЕЙЧАС
	// =========================================================

	currentState, err :=
		uc.resolver.Resolve(
			ctx,
			answer.SessionID,
		)

	if err != nil {
		return nil, fmt.Errorf(
			"resolve current questionnaire state: %w",
			err,
		)
	}

	// =========================================================
	// 2. Если вопроса нет —
	//    backend сейчас не ожидает ответа.
	// =========================================================

	if currentState.Question == nil {

		return nil, fmt.Errorf(
			"questionnaire is not waiting for an answer",
		)
	}

	// =========================================================
	// 3. Проверяем, что frontend отвечает именно
	//    на текущий вопрос.
	// =========================================================

	if answer.QuestionCode !=
		currentState.Question.Code {

		return nil, fmt.Errorf(
			"expected answer for question %s, got %s",
			currentState.Question.Code,
			answer.QuestionCode,
		)
	}

	// =========================================================
	// 4. Проверяем корректность типа и значения ответа
	// =========================================================

	if err :=
		validateAnswer(
			currentState.Question,
			currentState.Options,
			answer,
		); err != nil {

		return nil, err
	}

	// =========================================================
	// 5. Сохраняем ответ пользователя
	// =========================================================

	if err :=
		uc.answers.Save(
			ctx,
			answer,
		); err != nil {

		return nil, fmt.Errorf(
			"save answer: %w",
			err,
		)
	}

	// =========================================================
	// 6. После сохранения ответа заново запускаем
	//    QuestionnaireResolver.
	//
	// Он сам решит:
	//
	// - продолжать выбор таблицы;
	// - перейти к выбору строки;
	// - вернуть ROW_SELECTED.
	// =========================================================

	nextState, err :=
		uc.resolver.Resolve(
			ctx,
			answer.SessionID,
		)

	if err != nil {
		return nil, fmt.Errorf(
			"resolve next questionnaire state: %w",
			err,
		)
	}

	return nextState, nil
}

func validateAnswer(
	question *domain.Question,
	options []QuestionnaireOption,
	answer domain.QuestionnaireAnswer,
) error {

	// =========================================================
	// Должно быть заполнено РОВНО одно value_*
	// =========================================================

	valuesCount := 0

	if answer.ValueText != nil {
		valuesCount++
	}

	if answer.ValueNumeric != nil {
		valuesCount++
	}

	if answer.ValueDate != nil {
		valuesCount++
	}

	if answer.ValueBoolean != nil {
		valuesCount++
	}

	if valuesCount != 1 {

		return fmt.Errorf(
			"exactly one answer value must be provided",
		)
	}

	// =========================================================
	// Проверяем input_type
	// =========================================================

	switch question.InputType {

	// ---------------------------------------------------------
	// TEXT
	// ---------------------------------------------------------

	case domain.InputTypeText:

		if answer.ValueText == nil {

			return fmt.Errorf(
				"question %s requires text value",
				question.Code,
			)
		}

	// ---------------------------------------------------------
	// NUMBER
	// ---------------------------------------------------------

	case domain.InputTypeNumber:

		if answer.ValueNumeric == nil {

			return fmt.Errorf(
				"question %s requires numeric value",
				question.Code,
			)
		}

	// ---------------------------------------------------------
	// DATE
	// ---------------------------------------------------------

	case domain.InputTypeDate:

		if answer.ValueDate == nil {

			return fmt.Errorf(
				"question %s requires date value",
				question.Code,
			)
		}

	// ---------------------------------------------------------
	// BOOLEAN
	// ---------------------------------------------------------

	case domain.InputTypeBoolean:

		if answer.ValueBoolean == nil {

			return fmt.Errorf(
				"question %s requires boolean value",
				question.Code,
			)
		}

	// ---------------------------------------------------------
	// SELECT
	//
	// ВАЖНО:
	//
	// Select может теперь содержать:
	//
	// ValueText:
	// STANDARD
	//
	// или ValueNumeric:
	// 100
	//
	// Поэтому нельзя считать,
	// что любой select — обязательно string.
	// ---------------------------------------------------------

	case domain.InputTypeSelect:

		if len(options) == 0 {

			return fmt.Errorf(
				"question %s has no available options",
				question.Code,
			)
		}

		found := false

		for _, option :=
			range options {

			// ---------------------------------------------
			// TEXT OPTION
			// ---------------------------------------------

			if option.ValueText != nil &&
				answer.ValueText != nil &&
				*option.ValueText ==
					*answer.ValueText {

				found = true
				break
			}

			// ---------------------------------------------
			// NUMERIC OPTION
			// ---------------------------------------------

			if option.ValueNumeric != nil &&
				answer.ValueNumeric != nil &&
				*option.ValueNumeric ==
					*answer.ValueNumeric {

				found = true
				break
			}
		}

		if !found {

			return fmt.Errorf(
				"answer value is not allowed for question %s",
				question.Code,
			)
		}

	default:

		return fmt.Errorf(
			"unsupported input type %s",
			question.InputType,
		)
	}

	return nil
}