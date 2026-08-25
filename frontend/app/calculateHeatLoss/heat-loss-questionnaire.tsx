"use client";

import { useState, type FormEvent } from "react";

type QuestionInputType = "text" | "number" | "date" | "boolean" | "select";

type QuestionOption = {
  value_text?: string | null;
  value_numeric?: number | null;
  label: string;
};

type Question = {
  code: string;
  label: string;
  description?: string | null;
  phase: string;
  input_type: QuestionInputType;
  unit?: string | null;
  option_source?: string | null;
  options?: QuestionOption[];
};

type SelectedTable = {
  id: number;
  code: string;
  title: string;
};

type SelectedRow = {
  id: number;
  source_row_no: number;
};

type QHResult = {
  pipeline_role: string;
  calculated_supply_temperature_c?: number | null;
  calculated_return_temperature_c?: number | null;
  base_qh_w_per_m: number;
  adjusted_qh_w_per_m: number;
};

type QuestionnaireState = {
  session_id: number;
  status: string;
  question?: Question | null;
  table?: SelectedTable | null;
  row?: SelectedRow | null;
  results?: QHResult[];
};

type ErrorResponse = { error?: string };

const questionInputTypes: readonly QuestionInputType[] = [
  "text",
  "number",
  "date",
  "boolean",
  "select",
];

const terminalStatusContent: Record<
  string,
  { title: string; description: string }
> = {
  UNSUPPORTED: {
    title: "Не удалось подобрать нормативную таблицу",
    description:
      "Для указанной комбинации параметров на сервере нет подходящей нормативной таблицы.",
  },
  AMBIGUOUS: {
    title: "Подходят несколько таблиц",
    description:
      "Ответы соответствуют нескольким правилам подбора. Проверьте настройки правил на сервере.",
  },
  ERROR: {
    title: "Расчёт завершился с ошибкой",
    description: "Начните новый подбор и заполните опросник ещё раз.",
  },
  COMPLETED: {
    title: "Результат расчёта не получен",
    description:
      "Сервер завершил сессию, но не вернул значения удельных тепловых потерь.",
  },
};

const pipelineRoleLabels: Record<string, string> = {
  RETURN: "Обратный трубопровод",
  SUPPLY: "Подающий трубопровод",
  TWO_PIPE_TOTAL: "Двухтрубная сеть",
  DHW_SUPPLY: "Подающий трубопровод ГВС",
  DHW_CIRCULATION: "Циркуляционный трубопровод ГВС",
  SINGLE: "Трубопровод",
};

const numberFormatter = new Intl.NumberFormat("ru-RU", {
  maximumFractionDigits: 3,
});

function isFiniteNumber(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
}

function isOptionalString(value: unknown) {
  return value === undefined || value === null || typeof value === "string";
}

function isOptionalNumber(value: unknown) {
  return value === undefined || value === null || isFiniteNumber(value);
}

function isQuestionOption(value: unknown): value is QuestionOption {
  if (typeof value !== "object" || value === null) return false;

  const option = value as Record<string, unknown>;
  const hasTextValue = typeof option.value_text === "string";
  const hasNumericValue = isFiniteNumber(option.value_numeric);

  return (
    typeof option.label === "string" &&
    isOptionalString(option.value_text) &&
    isOptionalNumber(option.value_numeric) &&
    hasTextValue !== hasNumericValue
  );
}

function isQuestion(value: unknown): value is Question {
  if (typeof value !== "object" || value === null) return false;

  const question = value as Record<string, unknown>;

  return (
    typeof question.code === "string" &&
    typeof question.label === "string" &&
    typeof question.phase === "string" &&
    typeof question.input_type === "string" &&
    questionInputTypes.includes(question.input_type as QuestionInputType) &&
    isOptionalString(question.description) &&
    isOptionalString(question.unit) &&
    isOptionalString(question.option_source) &&
    (question.options === undefined ||
      (Array.isArray(question.options) &&
        question.options.every(isQuestionOption)))
  );
}

function isSelectedTable(value: unknown): value is SelectedTable {
  if (typeof value !== "object" || value === null) return false;

  const table = value as Record<string, unknown>;
  return (
    isFiniteNumber(table.id) &&
    typeof table.code === "string" &&
    typeof table.title === "string"
  );
}

function isSelectedRow(value: unknown): value is SelectedRow {
  if (typeof value !== "object" || value === null) return false;

  const row = value as Record<string, unknown>;
  return isFiniteNumber(row.id) && isFiniteNumber(row.source_row_no);
}

function isQHResult(value: unknown): value is QHResult {
  if (typeof value !== "object" || value === null) return false;

  const result = value as Record<string, unknown>;
  return (
    typeof result.pipeline_role === "string" &&
    isOptionalNumber(result.calculated_supply_temperature_c) &&
    isOptionalNumber(result.calculated_return_temperature_c) &&
    isFiniteNumber(result.base_qh_w_per_m) &&
    isFiniteNumber(result.adjusted_qh_w_per_m)
  );
}

function isQuestionnaireState(value: unknown): value is QuestionnaireState {
  if (typeof value !== "object" || value === null) return false;

  const state = value as Record<string, unknown>;
  return (
    isFiniteNumber(state.session_id) &&
    typeof state.status === "string" &&
    (state.question === undefined ||
      state.question === null ||
      isQuestion(state.question)) &&
    (state.table === undefined ||
      state.table === null ||
      isSelectedTable(state.table)) &&
    (state.row === undefined || state.row === null || isSelectedRow(state.row)) &&
    (state.results === undefined ||
      (Array.isArray(state.results) && state.results.every(isQHResult)))
  );
}

function getErrorMessage(value: unknown, fallback: string) {
  if (typeof value !== "object" || value === null) return fallback;

  const { error } = value as ErrorResponse;
  return typeof error === "string" && error ? error : fallback;
}

async function readJSON(response: Response): Promise<unknown> {
  try {
    return await response.json();
  } catch {
    return null;
  }
}

function formatNumber(value: number) {
  return numberFormatter.format(value);
}

function AnswerField({
  question,
  value,
  onChange,
}: {
  question: Question;
  value: string;
  onChange: (value: string) => void;
}) {
  if (question.input_type === "boolean") {
    return (
      <fieldset>
        <legend className="text-sm font-semibold text-slate-700">
          Ваш ответ
        </legend>
        <div className="mt-3 grid grid-cols-2 gap-3">
          {[
            ["true", "Да"],
            ["false", "Нет"],
          ].map(([optionValue, label]) => (
            <label
              key={optionValue}
              className={`cursor-pointer rounded-xl border px-4 py-3 text-center text-sm font-semibold transition ${
                value === optionValue
                  ? "border-orange-500 bg-orange-50 text-orange-700 ring-2 ring-orange-100"
                  : "border-slate-200 bg-white text-slate-700 hover:border-slate-300"
              }`}
            >
              <input
                required
                type="radio"
                name="answer"
                value={optionValue}
                checked={value === optionValue}
                onChange={(event) => onChange(event.target.value)}
                className="sr-only"
              />
              {label}
            </label>
          ))}
        </div>
      </fieldset>
    );
  }

  if (question.input_type === "select") {
    if (!question.options?.length) {
      return (
        <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm leading-6 text-amber-800">
          Сервер не вернул варианты ответа для этого вопроса.
        </div>
      );
    }

    return (
      <label className="block" htmlFor="question-answer">
        <span className="text-sm font-semibold text-slate-700">
          Выберите вариант
          {question.unit ? `, ${question.unit}` : ""}
        </span>
        <select
          required
          id="question-answer"
          name="answer"
          value={value}
          onChange={(event) => onChange(event.target.value)}
          className="mt-3 min-h-12 w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-base text-slate-950 outline-none transition hover:border-slate-300 focus:border-orange-500 focus:ring-4 focus:ring-orange-100"
        >
          <option value="" disabled>
            Выберите ответ
          </option>
          {question.options.map((option, index) => (
            <option key={`${question.code}-${index}`} value={String(index)}>
              {option.label}
            </option>
          ))}
        </select>
      </label>
    );
  }

  const inputType =
    question.input_type === "date"
      ? "date"
      : question.input_type === "number"
        ? "number"
        : "text";

  return (
    <label className="block" htmlFor="question-answer">
      <span className="text-sm font-semibold text-slate-700">
        Ваш ответ
        {question.unit ? `, ${question.unit}` : ""}
      </span>
      <input
        required
        id="question-answer"
        name="answer"
        type={inputType}
        step={inputType === "number" ? "any" : undefined}
        inputMode={inputType === "number" ? "decimal" : undefined}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder={question.input_type === "text" ? "Введите ответ" : undefined}
        className="mt-3 min-h-12 w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-base text-slate-950 outline-none transition placeholder:text-slate-400 hover:border-slate-300 focus:border-orange-500 focus:ring-4 focus:ring-orange-100"
      />
    </label>
  );
}

function TemperatureValue({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-xl bg-white/70 px-4 py-3">
      <dt className="text-xs font-medium text-slate-500">{label}</dt>
      <dd className="mt-1 font-semibold text-slate-900">
        {formatNumber(value)} °C
      </dd>
    </div>
  );
}

function QHResultCard({ result }: { result: QHResult }) {
  const role = pipelineRoleLabels[result.pipeline_role] ?? result.pipeline_role;

  return (
    <article className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 sm:p-6">
      <p className="text-sm font-semibold text-emerald-800">{role}</p>
      <div className="mt-3 flex flex-wrap items-baseline gap-x-2">
        <span className="text-3xl font-bold tracking-tight text-emerald-950">
          {formatNumber(result.adjusted_qh_w_per_m)}
        </span>
        <span className="font-semibold text-emerald-800">Вт/м</span>
      </div>
      <p className="mt-2 text-sm text-emerald-800">
        Базовое qh: {formatNumber(result.base_qh_w_per_m)} Вт/м
      </p>

      {(result.calculated_supply_temperature_c != null ||
        result.calculated_return_temperature_c != null) && (
        <dl className="mt-4 grid gap-2 sm:grid-cols-2">
          {result.calculated_supply_temperature_c != null && (
            <TemperatureValue
              label="Расчётная температура подачи"
              value={result.calculated_supply_temperature_c}
            />
          )}
          {result.calculated_return_temperature_c != null && (
            <TemperatureValue
              label="Расчётная температура обратки"
              value={result.calculated_return_temperature_c}
            />
          )}
        </dl>
      )}
    </article>
  );
}

function QuestionnaireResult({
  state,
  isLoading,
  error,
  onRestart,
}: {
  state: QuestionnaireState;
  isLoading: boolean;
  error: string | null;
  onRestart: () => void;
}) {
  const results = state.results ?? [];

  if (state.status === "COMPLETED" && results.length > 0) {
    return (
      <section className="w-full" aria-labelledby="result-title">
        <p className="text-sm font-semibold text-emerald-700">
          Расчёт завершён · сессия № {state.session_id}
        </p>
        <h2
          id="result-title"
          className="mt-2 text-3xl font-semibold tracking-tight text-slate-950"
        >
          Удельные тепловые потери qh
        </h2>

        {state.table && (
          <div className="mt-5 rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-600">
            Таблица{" "}
            <span className="font-semibold text-slate-900">
              {state.table.code} — {state.table.title}
            </span>
            {state.row && `, строка ${state.row.source_row_no}`}
          </div>
        )}

        <div className="mt-5 grid gap-4">
          {results.map((result, index) => (
            <QHResultCard
              key={`${result.pipeline_role}-${index}`}
              result={result}
            />
          ))}
        </div>

        <RestartButton isLoading={isLoading} onRestart={onRestart} />
        {error && <ErrorMessage message={error} />}
      </section>
    );
  }

  const content = terminalStatusContent[state.status] ?? {
    title: "Опросник завершён",
    description: `Сервер завершил сессию со статусом ${state.status}, но не вернул результат qh.`,
  };

  return (
    <section className="w-full" aria-labelledby="result-title">
      <p className="text-sm font-semibold text-amber-700">
        Сессия № {state.session_id} · {state.status}
      </p>
      <h2
        id="result-title"
        className="mt-2 text-3xl font-semibold tracking-tight text-slate-950"
      >
        {content.title}
      </h2>
      <p className="mt-4 max-w-lg leading-7 text-slate-600">
        {content.description}
      </p>
      <RestartButton isLoading={isLoading} onRestart={onRestart} />
      {error && <ErrorMessage message={error} />}
    </section>
  );
}

function RestartButton({
  isLoading,
  onRestart,
}: {
  isLoading: boolean;
  onRestart: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onRestart}
      disabled={isLoading}
      className="mt-7 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-xl border border-slate-300 bg-white px-6 py-3.5 text-sm font-semibold text-slate-800 transition hover:border-slate-400 hover:bg-slate-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-orange-500 disabled:cursor-wait disabled:opacity-65 sm:w-auto"
    >
      {isLoading ? (
        <>
          <LoadingSpinner />
          Создаём сессию…
        </>
      ) : (
        "Начать новый расчёт"
      )}
    </button>
  );
}

function ErrorMessage({ message }: { message: string }) {
  return (
    <div
      role="alert"
      className="mt-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm leading-6 text-red-700"
    >
      {message}
    </div>
  );
}

function LoadingSpinner() {
  return (
    <span
      className="size-4 animate-spin rounded-full border-2 border-current/30 border-t-current"
      aria-hidden="true"
    />
  );
}

export function HeatLossQuestionnaire() {
  const [questionnaire, setQuestionnaire] =
    useState<QuestionnaireState | null>(null);
  const [answer, setAnswer] = useState("");
  const [answeredQuestions, setAnsweredQuestions] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function startCalculation() {
    setIsLoading(true);
    setError(null);

    try {
      const response = await fetch("/api/qh/sessions", { method: "POST" });
      const data = await readJSON(response);

      if (!response.ok) {
        throw new Error(getErrorMessage(data, "Не удалось начать расчёт"));
      }
      if (!isQuestionnaireState(data)) {
        throw new Error("Сервер вернул некорректное состояние опросника");
      }

      setAnswer("");
      setAnsweredQuestions(0);
      setQuestionnaire(data);
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Не удалось начать расчёт",
      );
    } finally {
      setIsLoading(false);
    }
  }

  async function submitAnswer(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!questionnaire?.question || isSubmitting) return;

    const currentQuestion = questionnaire.question;
    const normalizedAnswer = answer.trim();
    const payload: Record<string, string | number | boolean> = {
      question_code: currentQuestion.code,
    };

    switch (currentQuestion.input_type) {
      case "text":
        if (!normalizedAnswer) {
          setError("Введите ответ");
          return;
        }
        payload.value_text = normalizedAnswer;
        break;
      case "select": {
        if (!normalizedAnswer) {
          setError("Выберите вариант ответа");
          return;
        }

        const optionIndex = Number(normalizedAnswer);
        const selectedOption = currentQuestion.options?.[optionIndex];

        if (!Number.isInteger(optionIndex) || !selectedOption) {
          setError("Выберите вариант ответа");
          return;
        }
        if (typeof selectedOption.value_text === "string") {
          payload.value_text = selectedOption.value_text;
        } else if (isFiniteNumber(selectedOption.value_numeric)) {
          payload.value_numeric = selectedOption.value_numeric;
        } else {
          setError("Выбранный вариант не содержит значения");
          return;
        }
        break;
      }
      case "number": {
        if (!normalizedAnswer) {
          setError("Введите числовое значение");
          return;
        }

        const numericAnswer = Number(normalizedAnswer.replace(",", "."));
        if (!Number.isFinite(numericAnswer)) {
          setError("Введите корректное числовое значение");
          return;
        }
        payload.value_numeric = numericAnswer;
        break;
      }
      case "date":
        if (!normalizedAnswer) {
          setError("Выберите дату");
          return;
        }
        payload.value_date = normalizedAnswer;
        break;
      case "boolean":
        if (answer !== "true" && answer !== "false") {
          setError("Выберите один из вариантов ответа");
          return;
        }
        payload.value_boolean = answer === "true";
        break;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const response = await fetch(
        `/api/qh/sessions/${questionnaire.session_id}/answers`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        },
      );
      const data = await readJSON(response);

      if (!response.ok) {
        throw new Error(getErrorMessage(data, "Не удалось сохранить ответ"));
      }
      if (!isQuestionnaireState(data)) {
        throw new Error("Сервер вернул некорректное состояние опросника");
      }

      setAnswer("");
      setAnsweredQuestions((count) => count + 1);
      setQuestionnaire(data);
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Не удалось сохранить ответ",
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  const results = questionnaire?.results ?? [];
  const hasResult =
    questionnaire?.status === "COMPLETED" && results.length > 0;
  const isTerminal = Boolean(questionnaire && !questionnaire.question);

  return (
    <main className="relative flex min-h-screen overflow-hidden bg-slate-950 px-4 py-8 text-slate-950 sm:px-6 sm:py-12">
      <div
        className="pointer-events-none absolute inset-0 opacity-80"
        aria-hidden="true"
      >
        <div className="absolute -left-32 top-16 size-80 rounded-full bg-orange-500/20 blur-3xl" />
        <div className="absolute -right-24 bottom-8 size-96 rounded-full bg-sky-500/15 blur-3xl" />
        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.035)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.035)_1px,transparent_1px)] bg-[size:48px_48px]" />
      </div>

      <section className="relative mx-auto flex w-full max-w-5xl flex-col overflow-hidden rounded-[2rem] border border-white/10 bg-slate-50 shadow-[0_32px_90px_rgba(0,0,0,0.45)]">
        <header className="flex items-center justify-between border-b border-slate-200/80 bg-white px-5 py-4 sm:px-8">
          <div className="flex items-center gap-3">
            <span className="flex size-10 items-center justify-center rounded-xl bg-orange-500 text-white shadow-lg shadow-orange-500/20">
              <svg
                viewBox="0 0 24 24"
                fill="none"
                className="size-5"
                aria-hidden="true"
              >
                <path
                  d="M13.4 2.8c.4 3.8-3.2 5.3-3.2 8 0 1.2.8 2 1.8 2.2-.3-2.2 1.4-3.4 2.5-4.8.8 1.4 2.5 3 2.5 5.7a5 5 0 0 1-10 0c0-4.8 3.8-7.8 6.4-11.1Z"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </span>
            <div>
              <p className="text-sm font-semibold tracking-tight text-slate-950">
                Тепловые потери
              </p>
              <p className="text-xs text-slate-500">Инженерный расчёт</p>
            </div>
          </div>

          {questionnaire && (
            <span
              className={`inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-xs font-semibold ${
                hasResult
                  ? "bg-emerald-50 text-emerald-700"
                  : isTerminal
                    ? "bg-amber-50 text-amber-700"
                    : "bg-orange-50 text-orange-700"
              }`}
            >
              <span
                className={`size-1.5 rounded-full ${
                  hasResult
                    ? "bg-emerald-500"
                    : isTerminal
                      ? "bg-amber-500"
                      : "bg-orange-500"
                }`}
              />
              {hasResult
                ? "qh рассчитан"
                : isTerminal
                  ? "Сессия завершена"
                  : "Сессия активна"}
            </span>
          )}
        </header>

        <div className="grid flex-1 lg:grid-cols-[0.9fr_1.1fr]">
          <div className="relative flex min-h-64 flex-col justify-between overflow-hidden bg-slate-900 p-6 text-white sm:p-10 lg:min-h-[590px]">
            <div
              className="absolute inset-0 bg-[radial-gradient(circle_at_10%_10%,rgba(249,115,22,0.25),transparent_35%),radial-gradient(circle_at_90%_85%,rgba(14,165,233,0.16),transparent_34%)]"
              aria-hidden="true"
            />
            <div className="relative">
              <p className="mb-5 text-xs font-semibold tracking-[0.18em] text-orange-400 uppercase">
                Поиск удельных тепловых потерь
              </p>
              <h1 className="max-w-md text-3xl font-semibold tracking-tight sm:text-4xl sm:leading-[1.12]">
                Ответьте на вопросы о тепловой сети
              </h1>
              <p className="mt-5 max-w-md text-sm leading-6 text-slate-300 sm:text-base sm:leading-7">
                Бэкенд задаст только необходимые вопросы, выберет нормативную
                таблицу и рассчитает qh для нужных трубопроводов.
              </p>
            </div>

            <div className="relative mt-10 grid grid-cols-3 gap-3">
              {[
                ["01", "Запуск"],
                ["02", "Вопросы"],
                ["03", "Результат"],
              ].map(([number, label], index) => (
                <div
                  key={number}
                  className={`border-t pt-3 ${
                    index === 0 ||
                    (index === 1 && questionnaire) ||
                    (index === 2 && isTerminal)
                      ? "border-orange-400 text-white"
                      : "border-slate-700 text-slate-500"
                  }`}
                >
                  <span className="block text-xs font-medium">{number}</span>
                  <span className="mt-1 block text-xs sm:text-sm">{label}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="flex min-h-80 items-center p-6 sm:p-10 lg:p-14">
            {questionnaire?.question ? (
              <section
                className="w-full"
                aria-labelledby="question-title"
                aria-live="polite"
              >
                <p className="text-sm font-semibold text-orange-600">
                  Вопрос {answeredQuestions + 1} · сессия №{" "}
                  {questionnaire.session_id}
                </p>
                <h2
                  id="question-title"
                  className="mt-2 text-2xl font-semibold tracking-tight text-slate-950 sm:text-3xl"
                >
                  {questionnaire.question.label}
                </h2>
                {questionnaire.question.description && (
                  <p className="mt-4 max-w-lg leading-7 text-slate-600">
                    {questionnaire.question.description}
                  </p>
                )}

                <form className="mt-8" onSubmit={submitAnswer}>
                  <AnswerField
                    question={questionnaire.question}
                    value={answer}
                    onChange={(nextAnswer) => {
                      setAnswer(nextAnswer);
                      setError(null);
                    }}
                  />
                  {error && <ErrorMessage message={error} />}

                  <button
                    type="submit"
                    disabled={
                      isSubmitting ||
                      (questionnaire.question.input_type === "select" &&
                        !questionnaire.question.options?.length)
                    }
                    className="mt-6 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-xl bg-orange-500 px-6 py-3.5 text-sm font-semibold text-white shadow-lg shadow-orange-500/20 transition hover:bg-orange-600 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-orange-500 disabled:cursor-wait disabled:opacity-65 sm:w-auto"
                  >
                    {isSubmitting ? (
                      <>
                        <LoadingSpinner />
                        Получаем следующий шаг…
                      </>
                    ) : (
                      "Ответить"
                    )}
                  </button>
                </form>
              </section>
            ) : questionnaire ? (
              <QuestionnaireResult
                state={questionnaire}
                isLoading={isLoading}
                error={error}
                onRestart={startCalculation}
              />
            ) : (
              <section className="w-full" aria-labelledby="start-title">
                <p className="text-sm font-semibold text-orange-600">
                  Шаг 1 из 3
                </p>
                <h2
                  id="start-title"
                  className="mt-2 text-3xl font-semibold tracking-tight text-slate-950"
                >
                  Начните новый расчёт
                </h2>
                <p className="mt-4 max-w-lg leading-7 text-slate-600">
                  Создадим сессию на бэкенде, последовательно соберём ответы и
                  покажем найденные значения qh.
                </p>

                <button
                  type="button"
                  onClick={startCalculation}
                  disabled={isLoading}
                  className="mt-8 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-xl bg-orange-500 px-6 py-3.5 text-sm font-semibold text-white shadow-lg shadow-orange-500/20 transition hover:bg-orange-600 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-orange-500 disabled:cursor-wait disabled:opacity-65 sm:w-auto"
                >
                  {isLoading ? (
                    <>
                      <LoadingSpinner />
                      Создаём сессию…
                    </>
                  ) : (
                    "Начать расчёт"
                  )}
                </button>
                {error && <ErrorMessage message={error} />}
              </section>
            )}
          </div>
        </div>
      </section>
    </main>
  );
}
