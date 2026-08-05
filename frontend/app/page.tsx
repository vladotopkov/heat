const inputClassName =
  "mt-2 w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-[15px] text-slate-900 outline-none transition placeholder:text-slate-400 hover:border-slate-300 focus:border-sky-500 focus:ring-4 focus:ring-sky-100";

const selectClassName = `${inputClassName} appearance-none bg-[url("data:image/svg+xml,%3Csvg_xmlns='http://www.w3.org/2000/svg'_viewBox='0_0_20_20'_fill='none'%3E%3Cpath_d='m6_8_4_4_4-4'_stroke='%2364748b'_stroke-width='1.5'_stroke-linecap='round'_stroke-linejoin='round'/%3E%3C/svg%3E")] bg-[length:20px] bg-[right_12px_center] bg-no-repeat pr-10`;

export default function Home() {
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
            Укажите сведения об участке сети, параметры трубопровода и условия
            прокладки.
          </p>
        </header>

        <form className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-[0_18px_55px_rgba(15,23,42,0.06)]">
          <div className="space-y-10 p-5 sm:p-8 lg:p-10">
            <fieldset>
              <legend className="flex items-center gap-3 text-lg font-semibold">
                <span className="flex size-8 items-center justify-center rounded-full bg-sky-100 text-sm text-sky-700">
                  1
                </span>
                Объект и период
              </legend>

              <div className="mt-6 grid gap-5 md:grid-cols-2">
                <label className="md:col-span-2">
                  <span className="text-sm font-medium text-slate-700">
                    Название
                  </span>
                  <input
                    required
                    type="text"
                    name="name"
                    placeholder="Например, тепловая магистраль № 4"
                    className={inputClassName}
                  />
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Участок
                  </span>
                  <input
                    required
                    type="text"
                    name="section"
                    placeholder="Начальная и конечная точки"
                    className={inputClassName}
                  />
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Расчётный период
                  </span>
                  <select
                    required
                    name="calculationPeriod"
                    defaultValue=""
                    className={selectClassName}
                  >
                    <option value="" disabled>
                      Выберите расчётный период
                    </option>
                    <option value="week">Неделя</option>
                    <option value="month">Месяц</option>
                    <option value="year">Год</option>
                  </select>
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Год ввода
                  </span>
                  <input
                    required
                    type="number"
                    name="commissioningYear"
                    min="1900"
                    max="2100"
                    inputMode="numeric"
                    placeholder="Например, 2018"
                    className={inputClassName}
                  />
                </label>
              </div>
            </fieldset>

            <div className="h-px bg-slate-100" />

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
                    name="networkType"
                    defaultValue=""
                    className={selectClassName}
                  >
                    <option value="" disabled>
                      Выберите тип сети
                    </option>
                    <option value="single-pipe">Однотрубная</option>
                    <option value="two-pipe">Двухтрубная</option>
                    <option value="four-pipe">Четырёхтрубная</option>
                  </select>
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Способ прокладки
                  </span>
                  <select
                    required
                    name="layingMethod"
                    defaultValue=""
                    className={selectClassName}
                  >
                    <option value="" disabled>
                      Выберите способ прокладки
                    </option>
                    <option value="above-ground">Надземная</option>
                    <option value="underground-duct">
                      Подземная канальная
                    </option>
                    <option value="underground-ductless">
                      Подземная бесканальная
                    </option>
                  </select>
                </label>
              </div>
            </fieldset>

            <div className="h-px bg-slate-100" />

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
                    Длина, м
                  </span>
                  <input
                    required
                    type="number"
                    name="length"
                    min="0"
                    step="0.01"
                    inputMode="decimal"
                    placeholder="0,00"
                    className={inputClassName}
                  />
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Глубина заложения, мм
                  </span>
                  <input
                    required
                    type="number"
                    name="burialDepth"
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
                    name="diameter"
                    min="0"
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
                    name="returnPipeDiameter"
                    min="0"
                    step="1"
                    inputMode="numeric"
                    placeholder="0"
                    className={inputClassName}
                  />
                </label>
              </div>
            </fieldset>

            <div className="h-px bg-slate-100" />

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
                    name="insulationMaterial"
                    defaultValue=""
                    className={selectClassName}
                  >
                    <option value="" disabled>
                      Выберите материал
                    </option>
                    <option value="ppu">Пенополиуретан</option>
                    <option value="ppm">Пенополимерминерал</option>
                    <option value="mineral-wool">Минеральная вата</option>
                    <option value="other">Другой материал</option>
                  </select>
                </label>

                <label>
                  <span className="text-sm font-medium text-slate-700">
                    Тип грунта
                  </span>
                  <select
                    required
                    name="soilType"
                    defaultValue=""
                    className={selectClassName}
                  >
                    <option value="" disabled>
                      Выберите тип грунта
                    </option>
                    <option value="sand">Песок</option>
                    <option value="sandy-loam">Супесь</option>
                    <option value="loam">Суглинок</option>
                    <option value="clay">Глина</option>
                  </select>
                </label>
              </div>
            </fieldset>
          </div>

          <div className="flex flex-col-reverse gap-3 border-t border-slate-200 bg-slate-50 px-5 py-5 sm:flex-row sm:justify-end sm:px-8 lg:px-10">
            <button
              type="reset"
              className="rounded-xl border border-slate-300 bg-white px-5 py-3 text-sm font-semibold text-slate-700 transition hover:border-slate-400 hover:bg-slate-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-500"
            >
              Очистить
            </button>
            <button
              type="submit"
              className="rounded-xl bg-sky-600 px-6 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-sky-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-600"
            >
              Создать расчёт
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}
