package http

import (
	"lostHeat/internal/qh/application"
	"lostHeat/internal/qh/domain"
)

type QuestionOptionResponse struct {
	ValueText *string `json:"value_text,omitempty"`

	ValueNumeric *float64 `json:"value_numeric,omitempty"`

	Label string `json:"label"`
}

type QuestionResponse struct {
	Code string `json:"code"`

	Label string `json:"label"`

	Description *string `json:"description,omitempty"`

	Phase string `json:"phase"`

	InputType string `json:"input_type"`

	Unit *string `json:"unit,omitempty"`

	OptionSource *string `json:"option_source,omitempty"`

	Options []QuestionOptionResponse `json:"options,omitempty"`
}

type SelectedTableResponse struct {
	ID int64 `json:"id"`

	Code string `json:"code"`

	Title string `json:"title"`
}

type SelectedRowResponse struct {
	ID int64 `json:"id"`

	SourceRowNo int `json:"source_row_no"`
}

type QHResultResponse struct {
	PipelineRole string `json:"pipeline_role"`

	CalculatedSupplyTemperatureC *float64 `json:"calculated_supply_temperature_c,omitempty"`

	CalculatedReturnTemperatureC *float64 `json:"calculated_return_temperature_c,omitempty"`

	BaseQHWPerM float64 `json:"base_qh_w_per_m"`

	AdjustedQHWPerM float64 `json:"adjusted_qh_w_per_m"`
}

type QuestionnaireStateResponse struct {
	SessionID int64 `json:"session_id"`

	Status string `json:"status"`

	Question *QuestionResponse `json:"question,omitempty"`

	Table *SelectedTableResponse `json:"table,omitempty"`

	Row *SelectedRowResponse `json:"row,omitempty"`

	Results []QHResultResponse `json:"results,omitempty"`
}

type ErrorResponse struct {
	Error string `json:"error"`
}

func newQuestionnaireStateResponse(
	state *application.QuestionnaireState,
) QuestionnaireStateResponse {

	response :=
		QuestionnaireStateResponse{
			SessionID:
				state.Session.ID,

			Status:
				string(
					state.Session.Status,
				),
		}

	// =========================================================
	// QUESTION
	// =========================================================

	if state.Question != nil {

		question :=
			newQuestionResponse(
				state.Question,
				state.Options,
			)

		response.Question =
			&question
	}

	// =========================================================
	// TABLE
	// =========================================================

	if state.SelectedTable != nil {

		response.Table =
			&SelectedTableResponse{
				ID:
					state.SelectedTable.ID,

				Code:
					state.SelectedTable.Code,

				Title:
					state.SelectedTable.Title,
			}
	}

	// =========================================================
	// ROW
	// =========================================================

	if state.SelectedRow != nil {

		response.Row =
			&SelectedRowResponse{
				ID:
					state.SelectedRow.ID,

				SourceRowNo:
					state.SelectedRow.SourceRowNo,
			}
	}

	// =========================================================
	// QH RESULTS
	// =========================================================

	for _, result :=
		range state.Results {

		response.Results =
			append(
				response.Results,
				newQHResultResponse(
					result,
				),
			)
	}

	return response
}

func newQuestionResponse(
	question *domain.Question,
	options []application.QuestionnaireOption,
) QuestionResponse {

	var optionSource *string

	if question.OptionSource != nil {

		value :=
			string(
				*question.OptionSource,
			)

		optionSource =
			&value
	}

	response :=
		QuestionResponse{
			Code:
				question.Code,

			Label:
				question.Label,

			Description:
				question.Description,

			Phase:
				string(
					question.Phase,
				),

			InputType:
				string(
					question.InputType,
				),

			Unit:
				question.Unit,

			OptionSource:
				optionSource,
		}

	for _, option :=
		range options {

		response.Options =
			append(
				response.Options,
				QuestionOptionResponse{
					ValueText:
						option.ValueText,

					ValueNumeric:
						option.ValueNumeric,

					Label:
						option.Label,
				},
			)
	}

	return response
}

func newQHResultResponse(
	result domain.QHResult,
) QHResultResponse {

	return QHResultResponse{
		PipelineRole:
			string(
				result.PipelineRole,
			),

		CalculatedSupplyTemperatureC:
			result.CalculatedSupplyTemperatureC,

		CalculatedReturnTemperatureC:
			result.CalculatedReturnTemperatureC,

		BaseQHWPerM:
			result.BaseQHWPerM,

		AdjustedQHWPerM:
			result.AdjustedQHWPerM,
	}
}