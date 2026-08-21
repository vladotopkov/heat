"use client";

import { useState, type FormEvent } from "react";

type QuestionInputType = "text" | "number" | "date" | "boolean" | "select";

type QuestionOption = {
  value: string;
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

type QuestionnaireState = {
  session_id: number;
  status: string;
  question?: Question | null;
  table?: SelectedTable | null;
};

type ErrorResponse = {
  error?: string;
};

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
    title: "Не удалось подобрать таблицу",
    description:
      "Для указанной комбинации параметров пока нет подходящей нормативной таблицы.",
  },
  AMBIGUOUS: {
    title: "Нужно уточнить правила подбора",
    description:
      "Ответы подходят сразу к нескольким таблицам. Проверьте правила выбора на сервере.",
  },
  ERROR: {
    title: "Расчёт завершился с ошибкой",
    description: "Создайте новую сессию и попробуйте заполнить опросник ещё раз.",
  },
};

function isQuestionOption(value: unknown): value is QuestionOption {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const option = value as Record<string, unknown>;

  return typeof option.value === "string" && typeof option.label === "string";
}

function isQuestion(value: unknown): value is Question {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const question = value as Record<string, unknown>;

  return (
    typeof question.code === "string" &&
    typeof question.label === "string" &&
    typeof question.phase === "string" &&
    typeof question.input_type === "string" &&
    questionInputTypes.includes(question.input_type as QuestionInputType) &&
    (question.description === undefined ||
      question.description === null ||
      typeof question.description === "string") &&
    (question.unit === undefined ||
      question.unit === null ||
      typeof question.unit === "string") &&
    (question.option_source === undefined ||
      question.option_source === null ||
      typeof question.option_source === "string") &&
    (question.options === undefined ||
      (Array.isArray(question.options) &&
        question.options.every(isQuestionOption)))
  );
}

function isSelectedTable(value: unknown): value is SelectedTable {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const table = value as Record<string, unknown>;

  return (
    typeof table.id === "number" &&
    typeof table.code === "string" &&
    typeof table.title === "string"
  );
}

function isQuestionnaireState(value: unknown): value is QuestionnaireState {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const state = value as Record<string, unknown>;

  return (
    typeof state.session_id === "number" &&
    typeof state.status === "string" &&
    (state.question === undefined ||
      state.question === null ||
      isQuestion(state.question)) &&
    (state.table === undefined ||
      state.table === null ||
      isSelectedTable(state.table))
  );
}

function getErrorMessage(value: unknown, fallback: string) {
  if (typeof value !== "object" || value === null) {
    return fallback;
  }

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

  if (question.input_type === "select" && question.options?.length) {
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
          {question.options.map((option) => (
            <option key={option.value} value={option.value}>
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
        placeholder={
          question.input_type === "select"
            ? "Введите значение"
            : question.input_type === "text"
              ? "Введите ответ"
              : undefined
        }
        className="mt-3 min-h-12 w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-base text-slate-950 outline-none transition placeholder:text-slate-400 hover:border-slate-300 focus:border-orange-500 focus:ring-4 focus:ring-orange-100"
      />
    </label>
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
  if (state.table) {
    return (
      <section className="w-full" aria-labelledby="result-title">
        <p className="text-sm font-semibold text-emerald-700">
          Таблица определена · сессия № {state.session_id}
        </p>
        <h2
          id="result-title"
          className="mt-2 text-3xl font-semibold tracking-tight text-slate-950"
        >
          Результат подбора
        </h2>

        <div className="mt-7 overflow-hidden rounded-2xl border border-emerald-200 bg-emerald-50">
          <div className="border-b border-emerald-200 px-5 py-3 text-xs font-semibold tracking-[0.14em] text-emerald-700 uppercase">
            Нормативная таблица
          </div>
          <div className="p-5 sm:p-6">
            <span className="inline-flex rounded-full bg-emerald-700 px-3 py-1 text-xs font-bold tracking-wide text-white">
              {state.table.code}
            </span>
            <p className="mt-4 text-xl font-semibold leading-8 text-emerald-950">
              {state.table.title}
            </p>
            <p className="mt-2 text-sm text-emerald-800">
              Идентификатор таблицы: {state.table.id}
            </p>
          </div>
        </div>

        <RestartButton isLoading={isLoading} onRestart={onRestart} />
        {error && <ErrorMessage message={error} />}
      </section>
    );
  }

  const content = terminalStatusContent[state.status] ?? {
    title: "Опросник завершён",
    description: `Сервер завершил сессию со статусом ${state.status}, но не вернул выбранную таблицу.`,
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
        "Начать новый подбор"
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
      const response = await fetch("/api/qh/sessions", {
        method: "POST",
      });
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

    if (!questionnaire?.question) {
      return;
    }

    const currentQuestion = questionnaire.question;
    const normalizedAnswer = answer.trim();
    const payload: Record<string, string | number | boolean> = {
      question_code: currentQuestion.code,
    };

    switch (currentQuestion.input_type) {
      case "text":
      case "select":
        if (!normalizedAnswer) {
          setError(
            currentQuestion.input_type === "select"
              ? "Выберите вариант ответа"
              : "Введите ответ",
          );
          return;
        }
        payload.value_text = normalizedAnswer;
        break;
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
          headers: {
            "Content-Type": "application/json",
          },
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

  const hasResult = Boolean(questionnaire && !questionnaire.question);

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
                questionnaire.table
                  ? "bg-emerald-50 text-emerald-700"
                  : hasResult
                    ? "bg-amber-50 text-amber-700"
                    : "bg-orange-50 text-orange-700"
              }`}
            >
              <span
                className={`size-1.5 rounded-full ${
                  questionnaire.table
                    ? "bg-emerald-500"
                    : hasResult
                      ? "bg-amber-500"
                      : "bg-orange-500"
                }`}
              />
              {questionnaire.table
                ? "Таблица выбрана"
                : hasResult
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
                Подбор нормативной таблицы
              </p>
              <h1 className="max-w-md text-3xl font-semibold tracking-tight sm:text-4xl sm:leading-[1.12]">
                Ответьте на вопросы о тепловой сети
              </h1>
              <p className="mt-5 max-w-md text-sm leading-6 text-slate-300 sm:text-base sm:leading-7">
                Система будет задавать только те вопросы, которые нужны для
                выбора подходящей нормативной таблицы.
              </p>
            </div>

            <div className="relative mt-10 grid grid-cols-3 gap-3">
              {[
                ["01", "Запуск"],
                ["02", "Вопросы"],
                ["03", "Таблица"],
              ].map(([number, label], index) => (
                <div
                  key={number}
                  className={`border-t pt-3 ${
                    index === 0 ||
                    (index === 1 && questionnaire) ||
                    (index === 2 && hasResult)
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
                  Вопрос {answeredQuestions + 1} · сессия № {questionnaire.session_id}
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
                    onChange={(value) => {
                      setAnswer(value);
                      setError(null);
                    }}
                  />

                  {error && <ErrorMessage message={error} />}

                  <button
                    type="submit"
                    disabled={isSubmitting}
                    className="mt-6 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-xl bg-orange-500 px-6 py-3.5 text-sm font-semibold text-white shadow-lg shadow-orange-500/20 transition hover:bg-orange-600 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-orange-500 disabled:cursor-wait disabled:opacity-65 sm:w-auto"
                  >
                    {isSubmitting ? (
                      <>
                        <LoadingSpinner />
                        Получаем следующий шаг…
                      </>
                    ) : (
                      <>
                        Ответить
                        <svg
                          viewBox="0 0 20 20"
                          fill="none"
                          className="size-4"
                          aria-hidden="true"
                        >
                          <path
                            d="M4 10h12m-4-4 4 4-4 4"
                            stroke="currentColor"
                            strokeWidth="1.8"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          />
                        </svg>
                      </>
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
                <p className="text-sm font-semibold text-orange-600">Шаг 1 из 3</p>
                <h2
                  id="start-title"
                  className="mt-2 text-3xl font-semibold tracking-tight text-slate-950"
                >
                  Начните новый подбор
                </h2>
                <p className="mt-4 max-w-lg leading-7 text-slate-600">
                  Мы создадим отдельную сессию, последовательно соберём ответы и
                  покажем выбранную нормативную таблицу.
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
                    <>
                      Начать подбор
                      <svg
                        viewBox="0 0 20 20"
                        fill="none"
                        className="size-4"
                        aria-hidden="true"
                      >
                        <path
                          d="M4 10h12m-4-4 4 4-4 4"
                          stroke="currentColor"
                          strokeWidth="1.8"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        />
                      </svg>
                    </>
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
