package application

import (
	"context"
	"fmt"
	"sort"

	"lostHeat/internal/qh/domain"
	"lostHeat/internal/qh/ports"
)

type RowSelectionResolver struct {
	sessions ports.SessionRepository

	answers ports.AnswerRepository

	questions ports.QuestionRepository

	tableDimensions ports.TableDimensionRepository

	rows ports.RowRepository
}

func NewRowSelectionResolver(
	sessions ports.SessionRepository,
	answers ports.AnswerRepository,
	questions ports.QuestionRepository,
	tableDimensions ports.TableDimensionRepository,
	rows ports.RowRepository,
) *RowSelectionResolver {

	return &RowSelectionResolver{
		sessions: sessions,

		answers: answers,

		questions: questions,

		tableDimensions: tableDimensions,

		rows: rows,
	}
}

func (r *RowSelectionResolver) Resolve(
	ctx context.Context,
	sessionID int64,
) (*domain.RowSelectionResult, error) {

	// =========================================================
	// 1. Получаем текущую сессию
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
	// 2. Для выбора строки таблица уже должна быть выбрана
	// =========================================================

	if session.SelectedQHTableID == nil {

		return nil, fmt.Errorf(
			"cannot select qh row: qh table is not selected",
		)
	}

	// =========================================================
	// 3. Если строка уже была выбрана,
	//    повторно ничего не вычисляем
	// =========================================================

	if session.Status ==
		domain.QuestionnaireStatusRowSelected {

		if session.SelectedQHRowID == nil {

			return nil, fmt.Errorf(
				"session has ROW_SELECTED status but selected_qh_row_id is null",
			)
		}

		row, err :=
			r.rows.GetByID(
				ctx,
				*session.SelectedQHRowID,
			)

		if err != nil {
			return nil, err
		}

		return &domain.RowSelectionResult{
			Session:     session,
			SelectedRow: row,
		}, nil
	}

	tableID :=
		*session.SelectedQHTableID

	// =========================================================
	// 4. Получаем dimensions выбранной таблицы
	//
	// Например:
	// Б.7 → NOMINAL_BORE
	// =========================================================

	dimensions, err :=
		r.tableDimensions.GetByTableID(
			ctx,
			tableID,
		)

	if err != nil {
		return nil, err
	}

	if len(dimensions) == 0 {

		return nil, fmt.Errorf(
			"qh table %d has no row dimensions configured",
			tableID,
		)
	}

	// =========================================================
	// 5. Получаем все ответы текущей сессии
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

	for _, answer :=
		range answers {

		answersByQuestion[
			answer.QuestionCode] = answer
	}

	// =========================================================
	// 6. Получаем все строки выбранной таблицы
	// =========================================================

	rows, err :=
		r.rows.GetByTableID(
			ctx,
			tableID,
		)

	if err != nil {
		return nil, err
	}

	if len(rows) == 0 {

		return nil, fmt.Errorf(
			"qh table %d has no active rows",
			tableID,
		)
	}

	// =========================================================
	// 7. Отбрасываем строки, которые уже противоречат
	//    ответам пользователя
	// =========================================================

	candidates, err :=
		filterRowCandidates(
			rows,
			dimensions,
			answersByQuestion,
		)

	if err != nil {
		return nil, err
	}

	// =========================================================
	// 8. Не осталось ни одной строки
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

		return &domain.RowSelectionResult{
			Session: session,
		}, nil
	}

	// =========================================================
	// 9. Осталась ровно одна строка
	//
	// Значит строка однозначно определена.
	// =========================================================

	if len(candidates) == 1 {

		selectedRow :=
			candidates[0]

		err :=
			r.sessions.SelectRow(
				ctx,
				sessionID,
				selectedRow.ID,
			)

		if err != nil {
			return nil, err
		}

		session.Status =
			domain.QuestionnaireStatusRowSelected

		rowID :=
			selectedRow.ID

		session.SelectedQHRowID =
			&rowID

		return &domain.RowSelectionResult{
			Session:
				session,

			SelectedRow:
				&selectedRow,
		}, nil
	}

	// =========================================================
	// 10. Строк несколько.
	//
	// Ищем следующую unanswered dimension,
	// которая реально различает оставшиеся строки.
	// =========================================================

	var nextDimension *domain.QHTableDimensionConfig

	for i :=
		range dimensions {

		config :=
			&dimensions[i]

		questionCode :=
			config.Dimension.QuestionCode

		// Если пользователь уже ответил —
		// этот dimension нам больше не нужен.
		if _, answered :=
			answersByQuestion[
				questionCode]; answered {

			continue
		}

		distinctCount :=
			countDistinctDimensionValues(
				candidates,
				config.Dimension.ID,
			)

		// Если у всех оставшихся строк
		// значение одинаковое,
		// вопрос не поможет выбрать строку.
		if distinctCount <= 1 {
			continue
		}

		nextDimension =
			config

		break
	}

	// =========================================================
	// 11. Строк несколько, но больше нечего спрашивать
	//
	// Значит конфигурация неоднозначна.
	// =========================================================

	if nextDimension == nil {

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

		return &domain.RowSelectionResult{
			Session: session,
		}, nil
	}

	// =========================================================
	// 12. Получаем описание вопроса
	//
	// Например:
	// NOMINAL_BORE
	// "Условный проход трубопровода"
	// =========================================================

	question, err :=
		r.questions.GetByCode(
			ctx,
			nextDimension.Dimension.QuestionCode,
		)

	if err != nil {
		return nil, err
	}

	// =========================================================
	// 13. Формируем варианты ответа
	//     непосредственно из оставшихся qh_rows
	// =========================================================

	options, err :=
		buildRowSelectionOptions(
			candidates,
			nextDimension.Dimension,
		)

	if err != nil {
		return nil, err
	}

	if len(options) == 0 {

		return nil, fmt.Errorf(
			"no options found for dimension %s",
			nextDimension.Dimension.Code,
		)
	}

	// =========================================================
	// 14. Возвращаем следующий вопрос
	// =========================================================

	return &domain.RowSelectionResult{
		Session:
			session,

		Question:
			question,

		Options:
			options,
	}, nil
}

// ============================================================
// filterRowCandidates
//
// Оставляет только строки, которые соответствуют
// уже полученным ответам пользователя.
// ============================================================

func filterRowCandidates(
	rows []domain.QHRow,
	dimensions []domain.QHTableDimensionConfig,
	answers map[string]domain.QuestionnaireAnswer,
) ([]domain.QHRow, error) {

	var result []domain.QHRow

	for _, row :=
		range rows {

		matches :=
			true

		for _, config :=
			range dimensions {

			answer, answered :=
				answers[
					config.Dimension.QuestionCode]

			// На этот dimension ещё не отвечали.
			// Значит строку пока не исключаем.
			if !answered {
				continue
			}

			rowValue, found :=
				findRowDimensionValue(
					row,
					config.Dimension.ID,
				)

			if !found {

				return nil, fmt.Errorf(
					"row %d has no value for dimension %s",
					row.ID,
					config.Dimension.Code,
				)
			}

			valueMatches, err :=
				rowDimensionMatchesAnswer(
					config.Dimension,
					rowValue,
					answer,
				)

			if err != nil {
				return nil, err
			}

			if !valueMatches {

				matches =
					false

				break
			}
		}

		if matches {

			result =
				append(
					result,
					row,
				)
		}
	}

	return result, nil
}

// ============================================================
// findRowDimensionValue
//
// Находит значение конкретной dimension внутри qh_row.
// ============================================================

func findRowDimensionValue(
	row domain.QHRow,
	dimensionID int64,
) (
	domain.QHRowDimensionValue,
	bool,
) {

	for _, value :=
		range row.DimensionValues {

		if value.DimensionID ==
			dimensionID {

			return value, true
		}
	}

	return domain.QHRowDimensionValue{},
		false
}

// ============================================================
// rowDimensionMatchesAnswer
//
// Сравнивает:
// значение характеристики строки
//
// с
//
// ответом пользователя.
// ============================================================

func rowDimensionMatchesAnswer(
	dimension domain.QHDimension,
	rowValue domain.QHRowDimensionValue,
	answer domain.QuestionnaireAnswer,
) (bool, error) {

	switch dimension.ValueType {

	case domain.DimensionValueTypeNumber:

		if rowValue.ValueNumeric == nil {

			return false, fmt.Errorf(
				"dimension %s expects numeric row value",
				dimension.Code,
			)
		}

		if answer.ValueNumeric == nil {

			return false, fmt.Errorf(
				"question %s requires numeric answer",
				dimension.QuestionCode,
			)
		}

		return *rowValue.ValueNumeric ==
			*answer.ValueNumeric,
			nil

	case domain.DimensionValueTypeText:

		if rowValue.ValueText == nil {

			return false, fmt.Errorf(
				"dimension %s expects text row value",
				dimension.Code,
			)
		}

		if answer.ValueText == nil {

			return false, fmt.Errorf(
				"question %s requires text answer",
				dimension.QuestionCode,
			)
		}

		return *rowValue.ValueText ==
			*answer.ValueText,
			nil

	default:

		return false, fmt.Errorf(
			"unsupported dimension value type %s",
			dimension.ValueType,
		)
	}
}

// ============================================================
// countDistinctDimensionValues
//
// Считает, сколько разных значений dimension
// существует среди оставшихся строк.
// ============================================================

func countDistinctDimensionValues(
	rows []domain.QHRow,
	dimensionID int64,
) int {

	numericValues :=
		make(
			map[float64]struct{},
		)

	textValues :=
		make(
			map[string]struct{},
		)

	for _, row :=
		range rows {

		value, found :=
			findRowDimensionValue(
				row,
				dimensionID,
			)

		if !found {
			continue
		}

		if value.ValueNumeric != nil {

			numericValues[
				*value.ValueNumeric] = struct{}{}
		}

		if value.ValueText != nil {

			textValues[
				*value.ValueText] = struct{}{}
		}
	}

	return len(numericValues) +
		len(textValues)
}

// ============================================================
// buildRowSelectionOptions
//
// Формирует options для frontend из строк таблицы.
// ============================================================

func buildRowSelectionOptions(
	rows []domain.QHRow,
	dimension domain.QHDimension,
) ([]domain.RowSelectionOption, error) {

	switch dimension.ValueType {

	// ---------------------------------------------------------
	// NUMBER
	// ---------------------------------------------------------

	case domain.DimensionValueTypeNumber:

		unique :=
			make(
				map[float64]struct{},
			)

		for _, row :=
			range rows {

			value, found :=
				findRowDimensionValue(
					row,
					dimension.ID,
				)

			if !found ||
				value.ValueNumeric == nil {

				continue
			}

			unique[
				*value.ValueNumeric] = struct{}{}
		}

		values :=
			make(
				[]float64,
				0,
				len(unique),
			)

		for value :=
			range unique {

			values =
				append(
					values,
					value,
				)
		}

		sort.Float64s(values)

		options :=
			make(
				[]domain.RowSelectionOption,
				0,
				len(values),
			)

		for _, value :=
			range values {

			valueCopy :=
				value

			label :=
				fmt.Sprintf(
					"%g",
					value,
				)

			if dimension.Unit != nil {

				label +=
					" " +
						*dimension.Unit
			}

			options =
				append(
					options,
					domain.RowSelectionOption{
						ValueNumeric:
							&valueCopy,

						Label:
							label,
					},
				)
		}

		return options, nil

	// ---------------------------------------------------------
	// TEXT
	// ---------------------------------------------------------

	case domain.DimensionValueTypeText:

		unique :=
			make(
				map[string]struct{},
			)

		for _, row :=
			range rows {

			value, found :=
				findRowDimensionValue(
					row,
					dimension.ID,
				)

			if !found ||
				value.ValueText == nil {

				continue
			}

			unique[
				*value.ValueText] = struct{}{}
		}

		values :=
			make(
				[]string,
				0,
				len(unique),
			)

		for value :=
			range unique {

			values =
				append(
					values,
					value,
				)
		}

		sort.Strings(values)

		options :=
			make(
				[]domain.RowSelectionOption,
				0,
				len(values),
			)

		for _, value :=
			range values {

			valueCopy :=
				value

			options =
				append(
					options,
					domain.RowSelectionOption{
						ValueText:
							&valueCopy,

						Label:
							value,
					},
				)
		}

		return options, nil

	default:

		return nil, fmt.Errorf(
			"unsupported dimension value type %s",
			dimension.ValueType,
		)
	}
}