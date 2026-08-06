"use client";

import type { CalculationFormOptions } from "@/types/heatsource";
import { FieldHelp } from "./field-help";
import { type FormEvent, useState } from "react";

interface CalculationFormProps {
  options: CalculationFormOptions;
}

interface CalculationResponse {
  operationCode: string;

  periodStart: string;
  periodEnd: string;
  periodHours: number;

  insulationResistanceMKPerW: number;
  soilResistanceMKPerW: number;
  totalResistanceMKPerW: number;

  deltaTemperatureK: number;
  heatFlowWPerM: number;
  heatLossPowerW: number;

  energyKWh: number;
}

interface APIErrorResponse {
  error?: {
    code?: string;
    message?: string;
  };
}

function requiredString(formData: FormData, fieldName: string): string {
  const value = formData.get(fieldName);

  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`Поле "${fieldName}" обязательно`);
  }

  return value.trim();
}

function optionalString(formData: FormData, fieldName: string): string | null {
  const value = formData.get(fieldName);

  if (typeof value !== "string" || value.trim() === "") {
    return null;
  }

  return value.trim();
}

function requiredNumber(formData: FormData, fieldName: string): number {
  const rawValue = requiredString(formData, fieldName);

  const value = Number(rawValue);

  if (!Number.isFinite(value)) {
    throw new Error(`Поле "${fieldName}" должно быть числом`);
  }

  return value;
}

function optionalNumber(formData: FormData, fieldName: string): number | null {
  const rawValue = optionalString(formData, fieldName);

  if (rawValue === null) {
    return null;
  }

  const value = Number(rawValue);

  if (!Number.isFinite(value)) {
    throw new Error(`Поле "${fieldName}" должно быть числом`);
  }

  return value;
}

const inputClassName =
  "mt-2 w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-[15px] text-slate-900 outline-none transition placeholder:text-slate-400 hover:border-slate-300 focus:border-sky-500 focus:ring-4 focus:ring-sky-100";

const selectClassName = `${inputClassName} appearance-none bg-[url("data:image/svg+xml,%3Csvg_xmlns='http://www.w3.org/2000/svg'_viewBox='0_0_20_20'_fill='none'%3E%3Cpath_d='m6_8_4_4_4-4'_stroke='%2364748b'_stroke-width='1.5'_stroke-linecap='round'_stroke-linejoin='round'/%3E%3C/svg%3E")] bg-[length:20px] bg-[right_12px_center] bg-no-repeat pr-10`;

export function CalculationForm({ options }: CalculationFormProps) {
  const [result, setResult] = useState<CalculationResponse | null>(null);

  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(
    event: FormEvent<HTMLFormElement>,
  ): Promise<void> {
    event.preventDefault();

    setIsSubmitting(true);
    setErrorMessage(null);
    setResult(null);

    try {
      const formData = new FormData(event.currentTarget);

      const requestData = {
        name: requiredString(formData, "name"),

        calculationOperationId: requiredString(
          formData,
          "calculationOperationId",
        ),

        boilerHouseId: requiredString(formData, "boilerHouseId"),

        section: requiredString(formData, "section"),

        // Преобразуем названия полей формы
        // в названия, ожидаемые Go backend.
        periodStart: requiredString(formData, "calculationPeriodFrom"),

        periodEnd: requiredString(formData, "calculationPeriodTo"),

        commissioningYear: requiredNumber(formData, "commissioningYear"),

        networkTypeId: requiredString(formData, "networkTypeId"),

        layingMethodId: requiredString(formData, "layingMethodId"),

        lengthM: requiredNumber(formData, "lengthM"),

        burialDepthM: optionalNumber(formData, "burialDepthM"),

        supplyPipeDiameterMm: requiredNumber(formData, "supplyPipeDiameterMm"),

        returnPipeDiameterMm: requiredNumber(formData, "returnPipeDiameterMm"),

        waterTemperatureC: requiredNumber(formData, "waterTemperatureC"),

        insulationMaterialId: requiredString(formData, "insulationMaterialId"),

        soilTypeId: optionalString(formData, "soilTypeId"),

        soilTemperatureC: requiredNumber(formData, "soilTemperatureC"),
      };

      const response = await fetch("/api/calculations", {
        method: "POST",

        headers: {
          "Content-Type": "application/json",

          Accept: "application/json",
        },

        body: JSON.stringify(requestData),
      });

      const responseData = (await response.json()) as
        | CalculationResponse
        | APIErrorResponse;

      if (!response.ok) {
        const errorResponse = responseData as APIErrorResponse;

        throw new Error(
          errorResponse.error?.message ?? "Не удалось выполнить расчёт",
        );
      }

      setResult(responseData as CalculationResponse);
    } catch (error) {
      setErrorMessage(
        error instanceof Error ? error.message : "Произошла неизвестная ошибка",
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  function handleReset(): void {
    setResult(null);
    setErrorMessage(null);
  }

  return (
    <main className="min-h-screen bg-slate-50 px-4 py-10 text-slate-950 sm:px-6 sm:py-14">
      <div className="mx-auto max-w-5xl">
        <header className="mb-8">
          <p className="mb-3 text-sm font-semibold tracking-wide text-sky-700 uppercase">
            Тепловая сеть
          </p>

          <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">
            Новый расчёт
          </h1>

          <p className="mt-3 max-w-2xl text-base leading-7 text-slate-600">
            Укажите операцию, объект расчёта, параметры трубопровода и условия
            прокладки.
          </p>
        </header>

        <form
          onSubmit={handleSubmit}
          onReset={handleReset}
          className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-[0_18px_55px_rgba(15,23,42,0.06)]"
        >
          <div className="space-y-10 p-5 sm:p-8 lg:p-10">
            {/* Операция и объект */}
            <fieldset>
              <legend className="flex items-center gap-3 text-lg font-semibold">
                <span className="flex size-8 items-center justify-center rounded-full bg-sky-100 text-sm text-sky-700">
                  1
                </span>
                Операция и объект
              </legend>

              <div className="mt-6 grid gap-5 md:grid-cols-2">
                <label className="md:col-span-2">
                  <span className="text-sm font-medium text-slate-700">
                    Название расчёта
                  </span>

                  <input
                    required
                    type="text"
                    name="name"
                    placeholder="Например, расчёт тепловых потерь участка № 4"
                    className={inputClassName}
                  />
                </label>

                <label className="md:col-span-2">
                  <span className="text-sm font-medium text-slate-700">
                    Операция
                  </span>

                  <select
                    required
                    name="calculationOperationId"
                    defaultValue=""
                    className={selectClassName}
                  >
                    <option value="" disabled>
                      Выберите операцию
                    </option>

                    {options.calculationOperations.map((operation) => (
                      <option key={operation.id} value={operation.id}>
                        {operation.name}
                      </option>
                    ))}
                  </select>
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Котельная
                  </span>

                  <select
                    required
                    name="boilerHouseId"
                    defaultValue=""
                    className={selectClassName}
                  >
                    <option value="" disabled>
                      Выберите котельную
                    </option>

                    {options.boilerHouses.map((boilerHouse) => (
                      <option key={boilerHouse.id} value={boilerHouse.id}>
                        {boilerHouse.name} — {boilerHouse.address}
                      </option>
                    ))}
                  </select>
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Участок
                  </span>

                  <input
                    required
                    type="text"
                    name="section"
                    placeholder="Например, от ТК-1 до жилого квартала"
                    className={inputClassName}
                  />
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Расчётный период — от
                  </span>

                  <input
                    required
                    type="date"
                    name="calculationPeriodFrom"
                    className={inputClassName}
                  />
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Расчётный период — до
                  </span>

                  <input
                    required
                    type="date"
                    name="calculationPeriodTo"
                    className={inputClassName}
                  />
                </label>

                <div>
                  <span className="inline-flex items-center gap-1.5">
                    <label
                      htmlFor="commissioningYear"
                      className="text-sm font-medium text-slate-700"
                    >
                      Год ввода участка
                    </label>
                    <FieldHelp ariaLabel="Что означает год ввода участка">
                      Когда конкретный участок тепловой сети фактически начали
                      эксплуатировать
                    </FieldHelp>
                  </span>

                  <input
                    id="commissioningYear"
                    required
                    type="number"
                    name="commissioningYear"
                    min="1900"
                    max="2100"
                    inputMode="numeric"
                    placeholder="Например, 2018"
                    className={inputClassName}
                  />
                </div>
              </div>
            </fieldset>

            <div className="h-px bg-slate-100" />

            {/* Конфигурация сети */}
            <fieldset>
              <legend className="flex items-center gap-3 text-lg font-semibold">
                <span className="flex size-8 items-center justify-center rounded-full bg-sky-100 text-sm text-sky-700">
                  2
                </span>
                Конфигурация сети
              </legend>

              <div className="mt-6 grid gap-5 md:grid-cols-2">
                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Тип сети
                  </span>

                  <select
                    required
                    name="networkTypeId"
                    defaultValue=""
                    className={selectClassName}
                  >
                    <option value="" disabled>
                      Выберите тип сети
                    </option>

                    {options.networkTypes.map((networkType) => (
                      <option key={networkType.id} value={networkType.id}>
                        {networkType.name}
                      </option>
                    ))}
                  </select>
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Способ прокладки
                  </span>

                  <select
                    required
                    name="layingMethodId"
                    defaultValue=""
                    className={selectClassName}
                  >
                    <option value="" disabled>
                      Выберите способ прокладки
                    </option>

                    {options.layingMethods.map((layingMethod) => (
                      <option key={layingMethod.id} value={layingMethod.id}>
                        {layingMethod.name}
                      </option>
                    ))}
                  </select>
                </label>
              </div>
            </fieldset>

            <div className="h-px bg-slate-100" />

            {/* Параметры трубопровода */}
            <fieldset>
              <legend className="flex items-center gap-3 text-lg font-semibold">
                <span className="flex size-8 items-center justify-center rounded-full bg-sky-100 text-sm text-sky-700">
                  3
                </span>
                Параметры трубопровода
              </legend>

              <div className="mt-6 grid gap-5 md:grid-cols-2">
                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Длина участка, м
                  </span>

                  <input
                    required
                    type="number"
                    name="lengthM"
                    min="0.01"
                    step="0.01"
                    inputMode="decimal"
                    placeholder="0,00"
                    className={inputClassName}
                  />
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Глубина заложения, м
                  </span>

                  <input
                    type="number"
                    name="burialDepthM"
                    min="0"
                    step="1"
                    inputMode="numeric"
                    placeholder="0"
                    className={inputClassName}
                  />
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Диаметр подающей трубы, мм
                  </span>

                  <input
                    required
                    type="number"
                    name="supplyPipeDiameterMm"
                    min="1"
                    step="1"
                    inputMode="numeric"
                    placeholder="0"
                    className={inputClassName}
                  />
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Диаметр обратной трубы, мм
                  </span>

                  <input
                    required
                    type="number"
                    name="returnPipeDiameterMm"
                    min="1"
                    step="1"
                    inputMode="numeric"
                    placeholder="0"
                    className={inputClassName}
                  />
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Температура воды в трубе, °C
                  </span>

                  <input
                    required
                    type="number"
                    name="waterTemperatureC"
                    step="0.1"
                    inputMode="decimal"
                    placeholder="0,0"
                    className={inputClassName}
                  />
                </label>
              </div>
            </fieldset>

            <div className="h-px bg-slate-100" />

            {/* Материалы и грунт */}
            <fieldset>
              <legend className="flex items-center gap-3 text-lg font-semibold">
                <span className="flex size-8 items-center justify-center rounded-full bg-sky-100 text-sm text-sky-700">
                  4
                </span>
                Материалы и грунт
              </legend>

              <div className="mt-6 grid gap-5 md:grid-cols-2">
                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Материал изоляции
                  </span>

                  <select
                    required
                    name="insulationMaterialId"
                    defaultValue=""
                    className={selectClassName}
                  >
                    <option value="" disabled>
                      Выберите материал
                    </option>

                    {options.insulationMaterials.map((insulationMaterial) => (
                      <option
                        key={insulationMaterial.id}
                        value={insulationMaterial.id}
                      >
                        {insulationMaterial.name}
                      </option>
                    ))}
                  </select>
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Тип грунта
                  </span>

                  <select
                    name="soilTypeId"
                    defaultValue=""
                    className={selectClassName}
                  >
                    <option value="">Не применяется</option>

                    {options.soilTypes.map((soilType) => (
                      <option key={soilType.id} value={soilType.id}>
                        {soilType.name}
                      </option>
                    ))}
                  </select>
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Температура грунта, °C
                  </span>

                  <input
                    required
                    type="number"
                    name="soilTemperatureC"
                    step="0.1"
                    inputMode="decimal"
                    placeholder="0,0"
                    className={inputClassName}
                  />
                </label>
              </div>
            </fieldset>
          </div>

          {/* Кнопки */}
          <div className="flex flex-col-reverse gap-3 border-t border-slate-200 bg-slate-50 px-5 py-5 sm:flex-row sm:justify-end sm:px-8 lg:px-10">
            <button
              type="reset"
              className="rounded-xl border border-slate-300 bg-white px-5 py-3 text-sm font-semibold text-slate-700 transition hover:border-slate-400 hover:bg-slate-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-500"
              disabled={isSubmitting}
            >
              Очистить
            </button>

            <button
              type="submit"
              disabled={isSubmitting}
              className="rounded-xl bg-sky-600 px-6 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-sky-700 disabled:cursor-not-allowed disabled:opacity-60 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-600"
            >
              {isSubmitting ? "Выполняется…" : "Рассчитать"}
            </button>
          </div>
        </form>

        {/* вывод ошибки и результата */}

        {errorMessage && (
          <div
            role="alert"
            className="mt-6 rounded-2xl border border-red-200 bg-red-50 p-5 text-sm text-red-700"
          >
            {errorMessage}
          </div>
        )}

        {result && (
          <section className="mt-6 rounded-3xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
            <h2 className="text-2xl font-semibold">Результат расчёта</h2>

            <dl className="mt-6 grid gap-5 sm:grid-cols-2">
              <div>
                <dt className="text-sm text-slate-500">Период</dt>

                <dd className="mt-1 font-semibold">
                  {result.periodStart} — {result.periodEnd}
                </dd>
              </div>

              <div>
                <dt className="text-sm text-slate-500">Продолжительность</dt>

                <dd className="mt-1 font-semibold">{result.periodHours} ч</dd>
              </div>

              <div>
                <dt className="text-sm text-slate-500">Общее сопротивление</dt>

                <dd className="mt-1 font-semibold">
                  {result.totalResistanceMKPerW.toFixed(6)} м·К/Вт
                </dd>
              </div>

              <div>
                <dt className="text-sm text-slate-500">
                  Удельные тепловые потери
                </dt>

                <dd className="mt-1 font-semibold">
                  {result.heatFlowWPerM.toFixed(2)} Вт/м
                </dd>
              </div>

              <div>
                <dt className="text-sm text-slate-500">
                  Мощность тепловых потерь
                </dt>

                <dd className="mt-1 font-semibold">
                  {result.heatLossPowerW.toFixed(2)} Вт
                </dd>
              </div>

              <div className="rounded-2xl bg-sky-50 p-4">
                <dt className="text-sm font-medium text-sky-700">
                  Потери за период
                </dt>

                <dd className="mt-1 text-2xl font-semibold text-sky-950">
                  {result.energyKWh.toLocaleString("ru-RU", {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2,
                  })}{" "}
                  кВт·ч
                </dd>
              </div>
            </dl>
          </section>
        )}
      </div>
    </main>
  );
}
