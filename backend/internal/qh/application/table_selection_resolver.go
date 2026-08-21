package application

import (
	"context"
	"fmt"
	"time"

	"lostHeat/internal/qh/domain"
	"lostHeat/internal/qh/ports"
)

type TableSelectionResult struct {
	Session *domain.QuestionnaireSession

	Question *domain.Question
	Options  []domain.QuestionOption

	SelectedRule  *domain.QHSelectionRule
	SelectedTable *domain.QHTable
}

type TableSelectionResolver struct {
	sessions  ports.SessionRepository
	answers   ports.AnswerRepository
	rules     ports.SelectionRuleRepository
	questions ports.QuestionRepository
	tables    ports.QHTableRepository
}

func NewTableSelectionResolver(
	sessions ports.SessionRepository,
	answers ports.AnswerRepository,
	rules ports.SelectionRuleRepository,
	questions ports.QuestionRepository,
	tables ports.QHTableRepository,
) *TableSelectionResolver {

	return &TableSelectionResolver{
		sessions:  sessions,
		answers:   answers,
		rules:     rules,
		questions: questions,
		tables:    tables,
	}
}

func (r *TableSelectionResolver) Resolve(
	ctx context.Context,
	sessionID int64,
) (*TableSelectionResult, error) {

	// =========================================================
	// 1. Получаем сессию
	// =========================================================

	session, err :=
		r.sessions.GetByID(
			ctx,
			sessionID,
		)

	if err != nil {
		return nil, err
	}

	// =========================================================
	// 2. Если таблица уже была выбрана,
	//    повторно правила не вычисляем
	// =========================================================

	if session.Status ==
		domain.QuestionnaireStatusTableSelected {

		if session.SelectedQHTableID == nil {
			return nil, fmt.Errorf(
				"session has TABLE_SELECTED status but selected_qh_table_id is null",
			)
		}

		table, err :=
			r.tables.GetByID(
				ctx,
				*session.SelectedQHTableID,
			)

		if err != nil {
			return nil, err
		}

		return &TableSelectionResult{
			Session:       session,
			SelectedTable: table,
		}, nil
	}

	// =========================================================
	// 3. Получаем ответы текущей сессии
	// =========================================================

	answers, err :=
		r.answers.GetBySessionID(
			ctx,
			sessionID,
		)

	if err != nil {
		return nil, err
	}

	answersByQuestion :=
		make(
			map[string]domain.QuestionnaireAnswer,
			len(answers),
		)

	// Добавляем в map:	ключ = answer.QuestionCode (код вопроса), значение = answer (весь объект ответа)

	for _, answer := range answers {
		answersByQuestion[answer.QuestionCode] = answer
	}

	// =========================================================
	// 4. Получаем все активные правила выбора таблицы
	// =========================================================

	rules, err :=
		r.rules.GetActive(ctx)

	if err != nil {
		return nil, err
	}

	if len(rules) == 0 {
		return nil, fmt.Errorf(
			"no active qh selection rules configured",
		)
	}

	// =========================================================
	// 5. Оставляем только те правила,
	//    которые ЕЩЁ МОГУТ подойти
	//
	// Если на условие ещё нет ответа:
	// правило НЕ отбрасываем.
	//
	// Если ответ есть и он не соответствует условию:
	// правило отбрасываем.
	// =========================================================

	type candidate struct {
		rule                  domain.QHSelectionRule
		allConditionsAnswered bool
	}

	var candidates []candidate

	for _, rule := range rules {

		possible := true
		allConditionsAnswered := true

		for _, condition := range rule.Conditions {

			answer, answered :=
				answersByQuestion[condition.QuestionCode]

			if !answered {
				allConditionsAnswered = false
				continue
			}

			matches, err :=
				matchCondition(
					condition,
					answer,
				)

			if err != nil {
				return nil, fmt.Errorf(
					"evaluate rule %s condition %d: %w",
					rule.Code,
					condition.ID,
					err,
				)
			}

			if !matches {
				possible = false
				break
			}
		}

		if possible {
			candidates = append(
				candidates,
				candidate{
					rule:                  rule,
					allConditionsAnswered: allConditionsAnswered,
				},
			)
		}
	}

	// =========================================================
	// 6. Не осталось ни одного правила
	// =========================================================

	if len(candidates) == 0 {

		err :=
			r.sessions.SetStatus(
				ctx,
				sessionID,
				domain.QuestionnaireStatusUnsupported,
			)

		if err != nil {
			return nil, err
		}

		session.Status =
			domain.QuestionnaireStatusUnsupported

		return &TableSelectionResult{
			Session: session,
		}, nil
	}

	// =========================================================
	// 7. Осталось ровно одно правило
	//    И ВСЕ его условия уже получили ответы
	//
	// Значит таблица определена.
	// =========================================================

	if len(candidates) == 1 &&
		candidates[0].allConditionsAnswered {

		selectedRule :=
			candidates[0].rule

		err :=
			r.sessions.SelectTable(
				ctx,
				sessionID,
				selectedRule.ID,
				selectedRule.QHTableID,
			)

		if err != nil {
			return nil, err
		}

		table, err :=
			r.tables.GetByID(
				ctx,
				selectedRule.QHTableID,
			)

		if err != nil {
			return nil, err
		}

		session.Status =
			domain.QuestionnaireStatusTableSelected

		ruleID := selectedRule.ID
		tableID := selectedRule.QHTableID

		session.SelectedTableRuleID =
			&ruleID

		session.SelectedQHTableID =
			&tableID

		return &TableSelectionResult{
			Session:       session,
			SelectedRule:  &selectedRule,
			SelectedTable: table,
		}, nil
	}

	// =========================================================
	// 8. Таблица ещё не определена.
	//
	// Собираем вопросы, ответы на которые ещё нужны
	// хотя бы одному оставшемуся правилу.
	// =========================================================

	pendingQuestions :=
		make(map[string]struct{})

	for _, candidate := range candidates {

		for _, condition := range candidate.rule.Conditions {

			_, answered :=
				answersByQuestion[condition.QuestionCode]

			if !answered {
				pendingQuestions[condition.QuestionCode] = struct{}{}
			}
		}
	}

	// =========================================================
	// 9. Если правила остались, но вопросов больше нет,
	//    значит несколько правил одновременно полностью подходят
	// =========================================================

	if len(pendingQuestions) == 0 {

		err :=
			r.sessions.SetStatus(
				ctx,
				sessionID,
				domain.QuestionnaireStatusAmbiguous,
			)

		if err != nil {
			return nil, err
		}

		session.Status =
			domain.QuestionnaireStatusAmbiguous

		return &TableSelectionResult{
			Session: session,
		}, nil
	}

	// =========================================================
	// 10. Получаем вопросы TABLE_SELECTION
	//     уже отсортированные по selection_order
	// =========================================================

	questions, err :=
		r.questions.GetActiveByPhase(
			ctx,
			domain.QuestionPhaseTableSelection,
		)

	if err != nil {
		return nil, err
	}

	// =========================================================
	// 11. Первый вопрос по selection_order,
	//     который ещё нужен кандидатам,
	//     становится следующим вопросом
	// =========================================================

	var nextQuestion *domain.Question

	for i := range questions {

		question := &questions[i]

		if _, needed :=
			pendingQuestions[question.Code]; needed {

			nextQuestion = question
			break
		}
	}

	if nextQuestion == nil {
		return nil, fmt.Errorf(
			"selection rules require unanswered questions but no active question configuration was found",
		)
	}

	// =========================================================
	// 12. Если options STATIC,
	//     загружаем question_options
	// =========================================================

	var options []domain.QuestionOption

	if nextQuestion.OptionSource != nil &&
		*nextQuestion.OptionSource ==
			domain.OptionSourceStatic {

		options, err =
			r.questions.GetStaticOptions(
				ctx,
				nextQuestion.Code,
			)

		if err != nil {
			return nil, err
		}
	}

	return &TableSelectionResult{
		Session:  session,
		Question: nextQuestion,
		Options:  options,
	}, nil
}

// ============================================================
// Проверка одного условия правила
// ============================================================

func matchCondition(
	condition domain.QHRuleCondition,
	answer domain.QuestionnaireAnswer,
) (bool, error) {

	// ---------------------------------------------------------
	// TEXT
	// ---------------------------------------------------------

	if condition.ValueText != nil {

		if answer.ValueText == nil {
			return false, fmt.Errorf(
				"condition expects text answer",
			)
		}

		switch condition.Operator {

		case domain.RuleOperatorEQ:
			return *answer.ValueText ==
				*condition.ValueText, nil

		case domain.RuleOperatorNEQ:
			return *answer.ValueText !=
				*condition.ValueText, nil

		default:
			return false, fmt.Errorf(
				"operator %s is not supported for text",
				condition.Operator,
			)
		}
	}

	// ---------------------------------------------------------
	// NUMBER
	// ---------------------------------------------------------

	if condition.ValueNumeric != nil {

		if answer.ValueNumeric == nil {
			return false, fmt.Errorf(
				"condition expects numeric answer",
			)
		}

		answerValue :=
			*answer.ValueNumeric

		value :=
			*condition.ValueNumeric

		switch condition.Operator {

		case domain.RuleOperatorEQ:
			return answerValue == value, nil

		case domain.RuleOperatorNEQ:
			return answerValue != value, nil

		case domain.RuleOperatorGT:
			return answerValue > value, nil

		case domain.RuleOperatorGTE:
			return answerValue >= value, nil

		case domain.RuleOperatorLT:
			return answerValue < value, nil

		case domain.RuleOperatorLTE:
			return answerValue <= value, nil

		case domain.RuleOperatorBetween:

			if condition.ValueNumericTo == nil {
				return false, fmt.Errorf(
					"BETWEEN requires value_numeric_to",
				)
			}

			return answerValue >= value &&
					answerValue <=
						*condition.ValueNumericTo,
				nil

		default:
			return false, fmt.Errorf(
				"unsupported numeric operator %s",
				condition.Operator,
			)
		}
	}

	// ---------------------------------------------------------
	// DATE
	// ---------------------------------------------------------

	if condition.ValueDate != nil {

		if answer.ValueDate == nil {
			return false, fmt.Errorf(
				"condition expects date answer",
			)
		}

		answerDate :=
			normalizeDate(
				*answer.ValueDate,
			)

		valueDate :=
			normalizeDate(
				*condition.ValueDate,
			)

		switch condition.Operator {

		case domain.RuleOperatorEQ:
			return answerDate.Equal(
				valueDate,
			), nil

		case domain.RuleOperatorNEQ:
			return !answerDate.Equal(
				valueDate,
			), nil

		case domain.RuleOperatorGT:
			return answerDate.After(
				valueDate,
			), nil

		case domain.RuleOperatorGTE:
			return answerDate.Equal(valueDate) ||
					answerDate.After(valueDate),
				nil

		case domain.RuleOperatorLT:
			return answerDate.Before(
				valueDate,
			), nil

		case domain.RuleOperatorLTE:
			return answerDate.Equal(valueDate) ||
					answerDate.Before(valueDate),
				nil

		case domain.RuleOperatorBetween:

			if condition.ValueDateTo == nil {
				return false, fmt.Errorf(
					"BETWEEN requires value_date_to",
				)
			}

			to :=
				normalizeDate(
					*condition.ValueDateTo,
				)

			return (answerDate.Equal(valueDate) ||
					answerDate.After(valueDate)) &&
					(answerDate.Equal(to) ||
						answerDate.Before(to)),
				nil

		default:
			return false, fmt.Errorf(
				"unsupported date operator %s",
				condition.Operator,
			)
		}
	}

	// ---------------------------------------------------------
	// BOOLEAN
	// ---------------------------------------------------------

	if condition.ValueBoolean != nil {

		if answer.ValueBoolean == nil {
			return false, fmt.Errorf(
				"condition expects boolean answer",
			)
		}

		switch condition.Operator {

		case domain.RuleOperatorEQ:
			return *answer.ValueBoolean ==
				*condition.ValueBoolean, nil

		case domain.RuleOperatorNEQ:
			return *answer.ValueBoolean !=
				*condition.ValueBoolean, nil

		default:
			return false, fmt.Errorf(
				"operator %s is not supported for boolean",
				condition.Operator,
			)
		}
	}

	return false, fmt.Errorf(
		"condition %d contains no comparison value",
		condition.ID,
	)
}

func normalizeDate(
	value time.Time,
) time.Time {

	return time.Date(
		value.Year(),
		value.Month(),
		value.Day(),
		0,
		0,
		0,
		0,
		time.UTC,
	)
}
