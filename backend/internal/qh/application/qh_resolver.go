package application

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"sort"

	"lostHeat/internal/qh/domain"
	"lostHeat/internal/qh/ports"
)

const (
	questionRegulationType =
		"REGULATION_TYPE"

	questionTemperatureRegime =
		"TEMPERATURE_REGIME"

	questionMaxCoolantTemperature =
		"MAX_COOLANT_TEMPERATURE"

	regulationTypeQualitative =
		"QUALITATIVE"

	regulationTypeQuantitative =
		"QUANTITATIVE"

	returnTemperatureC =
		50.0
)

type QHResolverResult struct {
	Session *domain.QuestionnaireSession

	Question *domain.Question

	Options []QuestionnaireOption

	Results []domain.QHResult
}

type QHResolver struct {
	sessions ports.SessionRepository

	answers ports.AnswerRepository

	questions ports.QuestionRepository

	temperatureRegimes ports.TemperatureRegimeRepository

	values ports.QHValueRepository

	results ports.QHResultRepository
}

func NewQHResolver(
	sessions ports.SessionRepository,
	answers ports.AnswerRepository,
	questions ports.QuestionRepository,
	temperatureRegimes ports.TemperatureRegimeRepository,
	values ports.QHValueRepository,
	results ports.QHResultRepository,
) *QHResolver {

	return &QHResolver{
		sessions: sessions,

		answers: answers,

		questions: questions,

		temperatureRegimes:
			temperatureRegimes,

		values:
			values,

		results:
			results,
	}
}

func (r *QHResolver) Resolve(
	ctx context.Context,
	sessionID int64,
) (*QHResolverResult, error) {

	// =========================================================
	// 1. Получаем session
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
	// 2. QHResolver можно запускать только после того,
	//    как известны таблица и строка
	// =========================================================

	if session.SelectedQHTableID == nil {
		return nil, fmt.Errorf(
			"cannot resolve qh: qh table is not selected",
		)
	}

	if session.SelectedQHRowID == nil {
		return nil, fmt.Errorf(
			"cannot resolve qh: qh row is not selected",
		)
	}

	// =========================================================
	// 3. Если qh уже был рассчитан,
	//    просто возвращаем сохранённый результат
	// =========================================================

	if session.Status ==
		domain.QuestionnaireStatusCompleted {

		results, err :=
			r.results.GetBySessionID(
				ctx,
				sessionID,
			)

		if err != nil {
			return nil, err
		}

		return &QHResolverResult{
			Session:
				session,

			Results:
				results,
		}, nil
	}

	// =========================================================
	// 4. Загружаем ответы пользователя
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
	// 5. Сначала нужно знать REGULATION_TYPE (количественная или качественная)
	// =========================================================

	regulationAnswer, answered :=
		answersByQuestion[
			questionRegulationType]

	if !answered {

		return r.staticQuestionResult(
			ctx,
			session,
			questionRegulationType,
		)
	}

	if regulationAnswer.ValueText == nil {

		return nil, fmt.Errorf(
			"%s requires text value",
			questionRegulationType,
		)
	}

	regulationType :=
		*regulationAnswer.ValueText

	// =========================================================
	// 6. Определяем расчётную температуру подачи
	// =========================================================

	var calculatedSupplyTemperature float64

	switch regulationType {

	// ---------------------------------------------------------
	// КАЧЕСТВЕННОЕ РЕГУЛИРОВАНИЕ
	//
	// Пользователь выбирает температурный график.
	//
	// Например:
	//
	// 130/70
	//
	// А из temperature_regimes берём:
	//
	// calculated_supply_temperature_c = 80.9
	// ---------------------------------------------------------

	case regulationTypeQualitative:

		regimeAnswer, answered :=
			answersByQuestion[
				questionTemperatureRegime]

		if !answered {

			return r.temperatureRegimeQuestionResult(
				ctx,
				session,
			)
		}

		if regimeAnswer.ValueNumeric == nil {

			return nil, fmt.Errorf(
				"%s requires numeric regime id",
				questionTemperatureRegime,
			)
		}

		regimeIDFloat :=
			*regimeAnswer.ValueNumeric

		regimeID :=
			int64(
				math.Round(
					regimeIDFloat,
				),
			)

		if math.Abs(
			float64(regimeID)-
				regimeIDFloat,
		) > 0.000001 {

			return nil, fmt.Errorf(
				"invalid temperature regime id %v",
				regimeIDFloat,
			)
		}

		regime, err :=
			r.temperatureRegimes.GetByID(
				ctx,
				regimeID,
			)

		if err != nil {
			return nil, err
		}

		calculatedSupplyTemperature =
			regime.CalculatedSupplyTemperatureC

	// ---------------------------------------------------------
	// КОЛИЧЕСТВЕННОЕ РЕГУЛИРОВАНИЕ
	//
	// Используем максимальную температуру теплоносителя,
	// которую ввёл пользователь.
	// ---------------------------------------------------------

	case regulationTypeQuantitative:

		temperatureAnswer, answered :=
			answersByQuestion[
				questionMaxCoolantTemperature]

		if !answered {

			return r.simpleQuestionResult(
				ctx,
				session,
				questionMaxCoolantTemperature,
			)
		}

		if temperatureAnswer.ValueNumeric == nil {

			return nil, fmt.Errorf(
				"%s requires numeric value",
				questionMaxCoolantTemperature,
			)
		}

		calculatedSupplyTemperature =
			*temperatureAnswer.ValueNumeric

	default:

		return nil, fmt.Errorf(
			"unsupported regulation type %s",
			regulationType,
		)
	}

	// =========================================================
	// 7. Получаем qh_values ТОЛЬКО выбранной строки
	// =========================================================

	qhValues, err :=
		r.values.GetByRowID(
			ctx,
			*session.SelectedQHRowID,
		)

	if err != nil {
		return nil, err
	}

	if len(qhValues) == 0 {

		return nil, fmt.Errorf(
			"qh row %d has no qh values",
			*session.SelectedQHRowID,
		)
	}

	// =========================================================
	// 8. Находим qh обратного трубопровода
	//
	// Для него используем 50 °C.
	// =========================================================

	returnLookup, err :=
		resolveReturnQH(
			qhValues,
			returnTemperatureC,
		)

	if err != nil {
		return nil, err
	}

	// =========================================================
	// 9. Находим qh подающего трубопровода
	//
	// Если точной температуры нет —
	// интерполируем.
	// =========================================================

	supplyLookup, err :=
		resolveSupplyQH(
			qhValues,
			calculatedSupplyTemperature,
		)

	if err != nil {
		return nil, err
	}

	// =========================================================
	// 10. Формируем calculation_details
	// =========================================================

	supplyDetails, err :=
		buildCalculationDetails(
			supplyLookup,
		)

	if err != nil {
		return nil, err
	}

	returnDetails, err :=
		buildCalculationDetails(
			returnLookup,
		)

	if err != nil {
		return nil, err
	}

	// =========================================================
	// 11. Формируем результаты
	//
	// ВАЖНО:
	//
	// qh_adjustment_rules пока НЕ применяем.
	//
	// Поэтому:
	//
	// adjusted_qh = base_qh
	// =========================================================

	tableID :=
		*session.SelectedQHTableID

	rowID :=
		*session.SelectedQHRowID

	supplyTemperature :=
		calculatedSupplyTemperature

	returnTemperature :=
		returnTemperatureC

	calculatedResults :=
		[]domain.QHResult{

			// -------------------------------------------------
			// SUPPLY
			// -------------------------------------------------

			{
				SessionID:
					sessionID,

				QHTableID:
					tableID,

				QHRowID:
					rowID,

				PipelineRole:
					domain.PipelineRoleSupply,

				CalculatedSupplyTemperatureC:
					&supplyTemperature,

				BaseQHWPerM:
					supplyLookup.QH,

				AdjustedQHWPerM:
					supplyLookup.QH,

				CalculationDetails:
					supplyDetails,
			},

			// -------------------------------------------------
			// RETURN
			// -------------------------------------------------

			{
				SessionID:
					sessionID,

				QHTableID:
					tableID,

				QHRowID:
					rowID,

				PipelineRole:
					domain.PipelineRoleReturn,

				CalculatedReturnTemperatureC:
					&returnTemperature,

				BaseQHWPerM:
					returnLookup.QH,

				AdjustedQHWPerM:
					returnLookup.QH,

				CalculationDetails:
					returnDetails,
			},
		}

	// =========================================================
	// 12. Сохраняем qh_results
	// =========================================================

	savedResults, err :=
		r.results.ReplaceForSession(
			ctx,
			sessionID,
			calculatedResults,
		)

	if err != nil {
		return nil, err
	}

	// =========================================================
	// 13. Завершаем текущий qh questionnaire
	// =========================================================

	err =
		r.sessions.SetStatus(
			ctx,
			sessionID,
			domain.QuestionnaireStatusCompleted,
		)

	if err != nil {
		return nil, err
	}

	session.Status =
		domain.QuestionnaireStatusCompleted

	// =========================================================
	// 14. Возвращаем результат
	// =========================================================

	return &QHResolverResult{
		Session:
			session,

		Results:
			savedResults,
	}, nil
}

// ============================================================
// STATIC QUESTION
//
// Например REGULATION_TYPE.
// ============================================================

func (r *QHResolver) staticQuestionResult(
	ctx context.Context,
	session *domain.QuestionnaireSession,
	questionCode string,
) (*QHResolverResult, error) {

	question, err :=
		r.questions.GetByCode(
			ctx,
			questionCode,
		)

	if err != nil {
		return nil, err
	}

	options, err :=
		r.questions.GetStaticOptions(
			ctx,
			questionCode,
		)

	if err != nil {
		return nil, err
	}

	resultOptions :=
		make(
			[]QuestionnaireOption,
			0,
			len(options),
		)

	for _, option :=
		range options {

		value :=
			option.Value

		resultOptions =
			append(
				resultOptions,
				QuestionnaireOption{
					ValueText:
						&value,

					Label:
						option.Label,
				},
			)
	}

	return &QHResolverResult{
		Session:
			session,

		Question:
			question,

		Options:
			resultOptions,
	}, nil
}

// ============================================================
// Обычный вопрос без options.
//
// Например MAX_COOLANT_TEMPERATURE.
// ============================================================

func (r *QHResolver) simpleQuestionResult(
	ctx context.Context,
	session *domain.QuestionnaireSession,
	questionCode string,
) (*QHResolverResult, error) {

	question, err :=
		r.questions.GetByCode(
			ctx,
			questionCode,
		)

	if err != nil {
		return nil, err
	}

	return &QHResolverResult{
		Session:
			session,

		Question:
			question,
	}, nil
}

// ============================================================
// TEMPERATURE_REGIME
//
// Options берём не из question_options,
// а из temperature_regimes.
// ============================================================

func (r *QHResolver) temperatureRegimeQuestionResult(
	ctx context.Context,
	session *domain.QuestionnaireSession,
) (*QHResolverResult, error) {

	question, err :=
		r.questions.GetByCode(
			ctx,
			questionTemperatureRegime,
		)

	if err != nil {
		return nil, err
	}

	regimes, err :=
		r.temperatureRegimes.GetAll(
			ctx,
		)

	if err != nil {
		return nil, err
	}

	options :=
		make(
			[]QuestionnaireOption,
			0,
			len(regimes),
		)

	for _, regime :=
		range regimes {

		id :=
			float64(
				regime.ID,
			)

		label :=
			fmt.Sprintf(
				"%g/%g °C",
				regime.ProjectSupplyTemperatureC,
				regime.ProjectReturnTemperatureC,
			)

		options =
			append(
				options,
				QuestionnaireOption{
					ValueNumeric:
						&id,

					Label:
						label,
				},
			)
	}

	return &QHResolverResult{
		Session:
			session,

		Question:
			question,

		Options:
			options,
	}, nil
}

// ============================================================
// Внутренний результат поиска qh.
// ============================================================

type qhLookupResult struct {
	QH float64

	Method string

	TargetTemperature float64

	FromTemperature float64

	ToTemperature float64

	FromQH float64

	ToQH float64
}

// ============================================================
// RETURN
//
// Для текущей логики ищем точное значение RETURN при 50 °C.
// ============================================================

func resolveReturnQH(
	values []domain.QHValue,
	targetTemperature float64,
) (qhLookupResult, error) {

	var matches []domain.QHValue

	for _, value := range values {

		if value.PipelineRole !=
			domain.PipelineRoleReturn {

			continue
		}

		if value.ReturnTemperatureC == nil {
			continue
		}

		if almostEqual(
			*value.ReturnTemperatureC,
			targetTemperature,
		) {

			matches = append(
				matches,
				value,
			)
		}
	}

	if len(matches) == 0 {
		return qhLookupResult{},
			fmt.Errorf(
				"return qh for temperature %g °C not found",
				targetTemperature,
			)
	}

	if len(matches) > 1 {
		return qhLookupResult{},
			fmt.Errorf(
				"multiple return qh values found for temperature %g °C",
				targetTemperature,
			)
	}

	value := matches[0]

	return qhLookupResult{
		QH: value.QHWPerM,

		Method: "EXACT",

		TargetTemperature: targetTemperature,

		FromTemperature: targetTemperature,
		ToTemperature:   targetTemperature,

		FromQH: value.QHWPerM,
		ToQH:   value.QHWPerM,
	}, nil
}

// ============================================================
// SUPPLY
//
// 1. Собираем температурные точки.
// 2. Ищем exact.
// 3. Если exact нет — линейная интерполяция.
// 4. Если температура снаружи диапазона — экстраполяция
//    по двум ближайшим крайним точкам.
// ============================================================

func resolveSupplyQH(
	values []domain.QHValue,
	targetTemperature float64,
) (qhLookupResult, error) {

	type point struct {
		Temperature float64
		QH float64
	}

	var points []point

	for _, value :=
		range values {

		if value.PipelineRole !=
			domain.PipelineRoleSupply {

			continue
		}

		if value.SupplyTemperatureC == nil {
			continue
		}

		points =
			append(
				points,
				point{
					Temperature:
						*value.SupplyTemperatureC,

					QH:
						value.QHWPerM,
				},
			)
	}

	if len(points) < 2 {

		return qhLookupResult{},
			fmt.Errorf(
				"at least two supply qh temperature points are required",
			)
	}

	sort.Slice(
		points,
		func(
			i int,
			j int,
		) bool {

			return points[i].Temperature <
				points[j].Temperature
		},
	)

	// =========================================================
	// EXACT
	// =========================================================

	for _, point :=
		range points {

		if almostEqual(
			point.Temperature,
			targetTemperature,
		) {

			return qhLookupResult{
				QH:
					point.QH,

				Method:
					"EXACT",

				TargetTemperature:
					targetTemperature,

				FromTemperature:
					point.Temperature,

				ToTemperature:
					point.Temperature,

				FromQH:
					point.QH,

				ToQH:
					point.QH,
			}, nil
		}
	}

	// =========================================================
	// Выбираем две точки
	// =========================================================

	var lower point
	var upper point

	method :=
		"INTERPOLATION"

	// ---------------------------------------------------------
	// Ниже минимальной температуры:
	// используем первые две точки.
	// ---------------------------------------------------------

	if targetTemperature <
		points[0].Temperature {

		lower =
			points[0]

		upper =
			points[1]

		method =
			"EXTRAPOLATION"

	// ---------------------------------------------------------
	// Выше максимальной температуры:
	// используем последние две точки.
	// ---------------------------------------------------------

	} else if targetTemperature >
		points[len(points)-1].Temperature {

		lower =
			points[len(points)-2]

		upper =
			points[len(points)-1]

		method =
			"EXTRAPOLATION"

	// ---------------------------------------------------------
	// Температура внутри диапазона:
	// ищем две окружающие точки.
	// ---------------------------------------------------------

	} else {

		found :=
			false

		for i :=
			0;
			i < len(points)-1;
			i++ {

			if targetTemperature >
				points[i].Temperature &&
				targetTemperature <
					points[i+1].Temperature {

				lower =
					points[i]

				upper =
					points[i+1]

				found =
					true

				break
			}
		}

		if !found {

			return qhLookupResult{},
				fmt.Errorf(
					"cannot find qh interpolation interval for temperature %g",
					targetTemperature,
				)
		}
	}

	// =========================================================
	// Проверяем интервал
	// =========================================================

	if almostEqual(
		lower.Temperature,
		upper.Temperature,
	) {

		return qhLookupResult{},
			fmt.Errorf(
				"cannot interpolate qh between equal temperatures",
			)
	}

	// =========================================================
	// ЛИНЕЙНАЯ ИНТЕРПОЛЯЦИЯ
	//
	//               T - T1
	// qh = qh1 + ------------ × (qh2 - qh1)
	//               T2 - T1
	// =========================================================

	qh :=
		lower.QH +
			(
				(targetTemperature-
					lower.Temperature)/
					(upper.Temperature-
						lower.Temperature) )*
				(upper.QH-
					lower.QH)

	return qhLookupResult{
		QH:
			qh,

		Method:
			method,

		TargetTemperature:
			targetTemperature,

		FromTemperature:
			lower.Temperature,

		ToTemperature:
			upper.Temperature,

		FromQH:
			lower.QH,

		ToQH:
			upper.QH,
	}, nil
}

func almostEqual(
	a float64,
	b float64,
) bool {

	return math.Abs(
		a-b,
	) < 0.000001
}

func buildCalculationDetails(
	lookup qhLookupResult,
) (json.RawMessage, error) {

	details :=
		map[string]any{
			"method":
				lookup.Method,

			"target_temperature_c":
				lookup.TargetTemperature,

			"from_temperature_c":
				lookup.FromTemperature,

			"to_temperature_c":
				lookup.ToTemperature,

			"from_qh_w_per_m":
				lookup.FromQH,

			"to_qh_w_per_m":
				lookup.ToQH,

			"adjustments_applied":
				false,
		}

	data, err :=
		json.Marshal(
			details,
		)

	if err != nil {
		return nil, fmt.Errorf(
			"marshal qh calculation details: %w",
			err,
		)
	}

	return data, nil
}