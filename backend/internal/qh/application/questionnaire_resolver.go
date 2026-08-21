package application

import (
	"context"
	"fmt"

	"lostHeat/internal/qh/domain"
	"lostHeat/internal/qh/ports"
)

type QuestionnaireOption struct {
	ValueText *string

	ValueNumeric *float64

	Label string
}

type QuestionnaireState struct {
	Session *domain.QuestionnaireSession

	Question *domain.Question

	Options []QuestionnaireOption

	SelectedTable *domain.QHTable

	SelectedRow *domain.QHRow

	Results []domain.QHResult
}

type QuestionnaireResolver struct {
	sessions ports.SessionRepository

	tables ports.QHTableRepository

	tableSelection *TableSelectionResolver

	rowSelection *RowSelectionResolver

	qhResolver *QHResolver
}

func NewQuestionnaireResolver(
	sessions ports.SessionRepository,
	tables ports.QHTableRepository,
	tableSelection *TableSelectionResolver,
	rowSelection *RowSelectionResolver,
	qhResolver *QHResolver,
) *QuestionnaireResolver {

	return &QuestionnaireResolver{
		sessions:
			sessions,

		tables:
			tables,

		tableSelection:
			tableSelection,

		rowSelection:
			rowSelection,

		qhResolver:
			qhResolver,
	}
}

func (r *QuestionnaireResolver) Resolve(
	ctx context.Context,
	sessionID int64,
) (*QuestionnaireState, error) {

	// =========================================================
	// 1. SESSION
	// =========================================================

	session, err :=
		r.sessions.GetByID(
			ctx,
			sessionID,
		)

	if err != nil {
		return nil, err
	}

	state :=
		&QuestionnaireState{
			Session:
				session,
		}

	// =========================================================
	// 2. Если таблица уже есть —
	//    добавляем её в response state
	// =========================================================

	if session.SelectedQHTableID != nil {

		table, err :=
			r.tables.GetByID(
				ctx,
				*session.SelectedQHTableID,
			)

		if err != nil {
			return nil, err
		}

		state.SelectedTable =
			table
	}

	// =========================================================
	// 3. Ошибочные/неподдерживаемые состояния
	// =========================================================

	switch session.Status {

	case domain.QuestionnaireStatusUnsupported,
		domain.QuestionnaireStatusAmbiguous,
		domain.QuestionnaireStatusError:

		return state, nil
	}

	// =========================================================
	// 4. Если COMPLETED —
	//    qh уже вычислен.
	//
	// QHResolver просто загрузит qh_results.
	// =========================================================

	if session.Status ==
		domain.QuestionnaireStatusCompleted {

		qhResult, err :=
			r.qhResolver.Resolve(
				ctx,
				sessionID,
			)

		if err != nil {
			return nil, err
		}

		state.Session =
			qhResult.Session

		state.Results =
			qhResult.Results

		return state, nil
	}

	// =========================================================
	// 5. ТАБЛИЦА
	// =========================================================

	if session.SelectedQHTableID == nil {

		tableResult, err :=
			r.tableSelection.Resolve(
				ctx,
				sessionID,
			)

		if err != nil {
			return nil, fmt.Errorf(
				"resolve qh table: %w",
				err,
			)
		}

		session =
			tableResult.Session

		state.Session =
			session

		if tableResult.Question != nil {

			state.Question =
				tableResult.Question

			state.Options =
				convertTableSelectionOptions(
					tableResult.Options,
				)

			return state, nil
		}

		switch session.Status {

		case domain.QuestionnaireStatusUnsupported,
			domain.QuestionnaireStatusAmbiguous,
			domain.QuestionnaireStatusError:

			return state, nil
		}

		if tableResult.SelectedTable != nil {

			state.SelectedTable =
				tableResult.SelectedTable
		}
	}

	if session.SelectedQHTableID == nil {

		return nil, fmt.Errorf(
			"qh table was not selected",
		)
	}

	// =========================================================
	// 6. СТРОКА
	// =========================================================

	rowResult, err :=
		r.rowSelection.Resolve(
			ctx,
			sessionID,
		)

	if err != nil {
		return nil, fmt.Errorf(
			"resolve qh row: %w",
			err,
		)
	}

	session =
		rowResult.Session

	state.Session =
		session

	if rowResult.Question != nil {

		state.Question =
			rowResult.Question

		state.Options =
			convertRowSelectionOptions(
				rowResult.Options,
			)

		return state, nil
	}

	switch session.Status {

	case domain.QuestionnaireStatusUnsupported,
		domain.QuestionnaireStatusAmbiguous,
		domain.QuestionnaireStatusError:

		return state, nil
	}

	if rowResult.SelectedRow != nil {

		state.SelectedRow =
			rowResult.SelectedRow
	}

	if session.SelectedQHRowID == nil {

		return nil, fmt.Errorf(
			"qh row was not selected",
		)
	}

	// =========================================================
	// 7. QH
	//
	// Строка уже известна.
	//
	// Теперь определяем температуру и qh.
	// =========================================================

	qhResult, err :=
		r.qhResolver.Resolve(
			ctx,
			sessionID,
		)

	if err != nil {
		return nil, fmt.Errorf(
			"resolve qh: %w",
			err,
		)
	}

	state.Session =
		qhResult.Session

	// ---------------------------------------------------------
	// QHResolver требует ещё один вопрос
	// ---------------------------------------------------------

	if qhResult.Question != nil {

		state.Question =
			qhResult.Question

		state.Options =
			qhResult.Options

		return state, nil
	}

	// ---------------------------------------------------------
	// QH рассчитан
	// ---------------------------------------------------------

	state.Results =
		qhResult.Results

	return state, nil
}

func convertTableSelectionOptions(
	options []domain.QuestionOption,
) []QuestionnaireOption {

	result :=
		make(
			[]QuestionnaireOption,
			0,
			len(options),
		)

	for _, option :=
		range options {

		value :=
			option.Value

		result =
			append(
				result,
				QuestionnaireOption{
					ValueText:
						&value,

					Label:
						option.Label,
				},
			)
	}

	return result
}

func convertRowSelectionOptions(
	options []domain.RowSelectionOption,
) []QuestionnaireOption {

	result :=
		make(
			[]QuestionnaireOption,
			0,
			len(options),
		)

	for _, option :=
		range options {

		result =
			append(
				result,
				QuestionnaireOption{
					ValueText:
						option.ValueText,

					ValueNumeric:
						option.ValueNumeric,

					Label:
						option.Label,
				},
			)
	}

	return result
}