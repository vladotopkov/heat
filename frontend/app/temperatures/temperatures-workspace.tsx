"use client";

import { useEffect, useRef, useState } from "react";

import { SiteHeader } from "../_components/site-header";

type TemperatureRow = {
  id: number | null;
  heat_network_id: number;
  heat_network_name: string;
  month: string;
  supply_t: number | null;
  return_t: number | null;
  ground_t: number | null;
  gvs_supply_t: number | null;
  gvs_return_t: number | null;
};

type TemperaturesResponse = {
  month: string;
  temperatures: TemperatureRow[];
};

type ErrorResponse = {
  error?: string;
};

type Draft = {
  supply: string;
  returnTemperature: string;
  ground: string;
  gvsSupply: string;
  gvsReturn: string;
};

type TemperatureColumn =
  | "network"
  | "supply"
  | "return"
  | "ground"
  | "gvsSupply"
  | "gvsReturn"
  | "actions";

const temperatureFormatter = new Intl.NumberFormat("ru-RU", {
  minimumFractionDigits: 0,
  maximumFractionDigits: 2,
});

export function TemperaturesWorkspace({
  initialMonth,
}: {
  initialMonth: string;
}) {
  const [month, setMonth] = useState(initialMonth);
  const [rows, setRows] = useState<TemperatureRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [reloadVersion, setReloadVersion] = useState(0);
  const [editingID, setEditingID] = useState<number | null>(null);
  const [savingID, setSavingID] = useState<number | null>(null);
  const [savedID, setSavedID] = useState<number | null>(null);
  const [draft, setDraft] = useState<Draft>(emptyDraft());
  const [editError, setEditError] = useState<string | null>(null);
  const [selectedColumn, setSelectedColumn] =
    useState<TemperatureColumn | null>(null);
  const stickyHeaderTrack = useRef<HTMLDivElement | null>(null);

  function toggleColumn(column: TemperatureColumn) {
    setSelectedColumn((current) => (current === column ? null : column));
  }

  function syncHeaderScroll(scrollLeft: number) {
    if (stickyHeaderTrack.current) {
      stickyHeaderTrack.current.style.transform = `translateX(-${scrollLeft}px)`;
    }
  }

  useEffect(() => {
    if (!month) return;

    const controller = new AbortController();

    async function loadTemperatures() {
      setLoading(true);
      setLoadError(null);
      setEditingID(null);
      setSavedID(null);

      try {
        const response = await requestJSON<TemperaturesResponse>(
          `/api/temperatures?month=${encodeURIComponent(month)}`,
          { signal: controller.signal },
        );

        setRows(response.temperatures ?? []);
      } catch (error) {
        if (!isAbortError(error)) {
          setLoadError(errorMessage(error));
          setRows([]);
        }
      } finally {
        if (!controller.signal.aborted) {
          setLoading(false);
        }
      }
    }

    void loadTemperatures();
    return () => controller.abort();
  }, [month, reloadVersion]);

  function startEditing(row: TemperatureRow) {
    setEditingID(row.heat_network_id);
    setSavedID(null);
    setEditError(null);
    setDraft({
      supply: inputValue(row.supply_t),
      returnTemperature: inputValue(row.return_t),
      ground: inputValue(row.ground_t),
      gvsSupply: inputValue(row.gvs_supply_t),
      gvsReturn: inputValue(row.gvs_return_t),
    });
  }

  function cancelEditing() {
    setEditingID(null);
    setEditError(null);
    setDraft(emptyDraft());
  }

  async function saveRow(row: TemperatureRow) {
    const supply = parseTemperature(draft.supply);
    const returnTemperature = parseTemperature(draft.returnTemperature);
    const ground = parseTemperature(draft.ground);

    if (supply === null || returnTemperature === null || ground === null) {
      setEditError("Заполните все температуры числами от −9999,99 до 9999,99");
      return;
    }

    const hasGVS = row.heat_network_id === 2 &&
      (draft.gvsSupply.trim() !== "" || draft.gvsReturn.trim() !== "");
    const gvsSupply = parseTemperature(draft.gvsSupply);
    const gvsReturn = parseTemperature(draft.gvsReturn);
    if (hasGVS && (gvsSupply === null || gvsReturn === null)) {
      setEditError("Заполните подачу и обратку ГВС числами от −9999,99 до 9999,99");
      return;
    }

    setSavingID(row.heat_network_id);
    setEditError(null);

    try {
      const saved = await requestJSON<TemperatureRow>(
        `/api/heat-networks/${row.heat_network_id}/temperatures/${month}`,
        {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            supply_t: supply,
            return_t: returnTemperature,
            ground_t: ground,
            ...(hasGVS ? { gvs_supply_t: gvsSupply, gvs_return_t: gvsReturn } : {}),
          }),
        },
      );

      setRows((current) =>
        current.map((item) =>
          item.heat_network_id === row.heat_network_id
            ? {
                ...item,
                ...saved,
                heat_network_name:
                  saved.heat_network_name || item.heat_network_name,
              }
            : item,
        ),
      );
      setEditingID(null);
      setSavedID(row.heat_network_id);
      setDraft(emptyDraft());
    } catch (error) {
      setEditError(errorMessage(error));
    } finally {
      setSavingID(null);
    }
  }

  return (
    <main className="relative min-h-screen overflow-x-clip bg-[#f2f5f1] text-[#17221f]">
      <div className="pointer-events-none absolute inset-x-0 top-0 h-[430px] bg-[radial-gradient(circle_at_82%_0%,rgba(61,121,97,0.17),transparent_38%),radial-gradient(circle_at_14%_8%,rgba(210,171,91,0.13),transparent_32%)]" />

      <SiteHeader />

      <div className="relative mx-auto w-[calc(100%-2rem)] py-9 sm:w-[90%] sm:py-12 xl:w-[85%]">
        <section className="mb-7 flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="text-4xl font-semibold tracking-[-0.045em] text-[#17221f]">
              Температуры
            </h1>
            
          </div>

          <label className="w-full rounded-2xl border border-[#d8e2da] bg-white px-4 py-3 shadow-sm sm:w-60">
            <span className="block text-[11px] font-bold tracking-[0.08em] text-[#64746c] uppercase">
              Месяц
            </span>
            <input
              type="month"
              value={month}
              disabled={savingID !== null}
              onChange={(event) => setMonth(event.target.value)}
              className="mt-1.5 w-full bg-transparent text-base font-semibold text-[#1d2b26] outline-none disabled:cursor-not-allowed disabled:opacity-60"
            />
          </label>
        </section>

        <section className="rounded-[22px] border border-[#dce4dd] bg-white shadow-[0_16px_45px_rgba(30,55,45,0.055)]">
          

          {loading ? (
            <TableSkeleton />
          ) : loadError ? (
            <div className="grid min-h-72 place-items-center px-6 py-12 text-center">
              <div className="max-w-md">
                <p className="font-semibold text-[#a14c38]">{loadError}</p>
                <button
                  type="button"
                  onClick={() => setReloadVersion((current) => current + 1)}
                  className="mt-4 rounded-xl bg-[#245f4a] px-4 py-2.5 text-sm font-semibold text-white"
                >
                  Повторить
                </button>
              </div>
            </div>
          ) : rows.length === 0 ? (
            <div className="grid min-h-72 place-items-center px-6 py-12 text-center text-sm text-[#718078]">
              В базе нет теплосетей для отображения.
            </div>
          ) : (
            <>
              <div className="sticky top-0 z-30 overflow-hidden rounded-t-[20px] border-y border-[#194a38] bg-[#225e49] shadow-[0_8px_18px_rgba(28,52,43,0.18)]">
                <div ref={stickyHeaderTrack} className="will-change-transform">
                  <table className="w-full min-w-[1120px] table-fixed border-collapse text-left">
                    <TemperatureColumnWidths />
                    <thead>
                      <TemperatureHeaderRow
                        selectedColumn={selectedColumn}
                        onSelect={toggleColumn}
                      />
                    </thead>
                  </table>
                </div>
              </div>

              <div
                className="overflow-x-auto"
                onScroll={(event) =>
                  syncHeaderScroll(event.currentTarget.scrollLeft)
                }
              >
                <table className="w-full min-w-[1120px] table-fixed border-collapse text-left">
                  <TemperatureColumnWidths />
                  <thead className="sr-only">
                    <tr>
                      <th>Теплосеть</th>
                      <th>Температура подачи, °C</th>
                      <th>Температура обратки, °C</th>
                      <th>Температура грунта, °C</th>
                      <th>Подача ГВС, °C</th>
                      <th>Обратка ГВС, °C</th>
                      <th>Действия</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#e8ede9]">
                  {rows.map((row) => {
                    const editing = editingID === row.heat_network_id;
                    const saving = savingID === row.heat_network_id;

                    return (
                      <tr
                        key={row.heat_network_id}
                        className={`transition-colors ${
                          editing ? "bg-[#eaf4ed]" : "hover:bg-[#f8faf8]"
                        }`}
                      >
                        <td
                          className={`px-3 py-4 text-center transition-colors ${
                            selectedColumn === "network" ? "bg-[#eaf4ed]" : ""
                          }`}
                        >
                          <div className="flex items-center justify-center gap-2.5">
                            <span className="inline-flex rounded-lg bg-[#edf3ef] px-2.5 py-1.5 text-xs font-bold text-[#356851] tabular-nums">
                              #{row.heat_network_id}
                            </span>
                            <p className="text-sm font-semibold text-[#26332e]">
                              {row.heat_network_name}
                            </p>
                          </div>
                          {row.heat_network_id === 2 && editing ? (
                            <p className="mt-2 text-xs text-[#64746c]">
                              Для ГВС заполните оба поля. Температура грунта общая.
                            </p>
                          ) : null}
                          {editing && editError ? (
                            <p className="mt-2 text-xs font-medium text-[#a14c38]">
                              {editError}
                            </p>
                          ) : null}
                          {savedID === row.heat_network_id ? (
                            <p className="mt-2 text-xs font-semibold text-[#2c7658]">
                              Сохранено в базе данных
                            </p>
                          ) : null}
                        </td>
                        <TemperatureCell
                          editing={editing}
                          disabled={saving}
                          selected={selectedColumn === "supply"}
                          label={`Температура подачи, ${row.heat_network_name}`}
                          value={row.supply_t}
                          draftValue={draft.supply}
                          onChange={(value) =>
                            setDraft((current) => ({
                              ...current,
                              supply: value,
                            }))
                          }
                        />
                        <TemperatureCell
                          editing={editing}
                          disabled={saving}
                          selected={selectedColumn === "return"}
                          label={`Температура обратки, ${row.heat_network_name}`}
                          value={row.return_t}
                          draftValue={draft.returnTemperature}
                          onChange={(value) =>
                            setDraft((current) => ({
                              ...current,
                              returnTemperature: value,
                            }))
                          }
                        />
                        <TemperatureCell
                          editing={editing}
                          disabled={saving}
                          selected={selectedColumn === "ground"}
                          label={`Температура грунта, ${row.heat_network_name}`}
                          value={row.ground_t}
                          draftValue={draft.ground}
                          onChange={(value) =>
                            setDraft((current) => ({
                              ...current,
                              ground: value,
                            }))
                          }
                        />
                        <TemperatureCell
                          editing={editing && row.heat_network_id === 2}
                          disabled={saving}
                          selected={selectedColumn === "gvsSupply"}
                          label={`Подача ГВС, ${row.heat_network_name}`}
                          value={row.heat_network_id === 2 ? row.gvs_supply_t : null}
                          draftValue={draft.gvsSupply}
                          onChange={(value) =>
                            setDraft((current) => ({ ...current, gvsSupply: value }))
                          }
                        />
                        <TemperatureCell
                          editing={editing && row.heat_network_id === 2}
                          disabled={saving}
                          selected={selectedColumn === "gvsReturn"}
                          label={`Обратка ГВС, ${row.heat_network_name}`}
                          value={row.heat_network_id === 2 ? row.gvs_return_t : null}
                          draftValue={draft.gvsReturn}
                          onChange={(value) =>
                            setDraft((current) => ({ ...current, gvsReturn: value }))
                          }
                        />
                        <td
                          className={`px-3 py-4 text-center transition-colors ${
                            selectedColumn === "actions" ? "bg-[#eaf4ed]" : ""
                          }`}
                        >
                          {editing ? (
                            <div className="flex justify-center gap-2">
                              <button
                                type="button"
                                disabled={saving}
                                onClick={cancelEditing}
                                className="rounded-xl border border-[#d6dfd8] px-3 py-2 text-xs font-semibold text-[#5c6c64] transition hover:bg-white disabled:opacity-50"
                              >
                                Отмена
                              </button>
                              <button
                                type="button"
                                disabled={saving}
                                onClick={() => void saveRow(row)}
                                className="min-w-24 rounded-xl bg-[#245f4a] px-3 py-2 text-xs font-semibold text-white transition hover:bg-[#194b39] disabled:cursor-wait disabled:opacity-65"
                              >
                                {saving ? "Сохранение…" : "Сохранить"}
                              </button>
                            </div>
                          ) : (
                            <button
                              type="button"
                              disabled={savingID !== null}
                              onClick={() => startEditing(row)}
                              className="rounded-xl border border-[#cfdcd3] bg-white px-3.5 py-2 text-xs font-semibold text-[#315f4d] transition hover:border-[#9db7a7] hover:bg-[#f4f8f5] disabled:opacity-50"
                            >
                              Редактировать
                            </button>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </section>
      </div>
    </main>
  );
}

function TemperatureColumnWidths() {
  return (
    <colgroup>
      <col className="w-[24%]" />
      <col />
      <col />
      <col />
      <col />
      <col />
      <col className="w-44" />
    </colgroup>
  );
}

function TemperatureHeaderRow({
  selectedColumn,
  onSelect,
}: {
  selectedColumn: TemperatureColumn | null;
  onSelect: (column: TemperatureColumn) => void;
}) {
  return (
    <tr className="bg-[#225e49] text-sm font-semibold tracking-[-0.01em] text-white">
      <TemperatureColumnHeader
        column="network"
        label="Теплосеть"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <TemperatureColumnHeader
        column="supply"
        label="Темп. подачи"
        unit="°C"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <TemperatureColumnHeader
        column="return"
        label="Темп. обратки"
        unit="°C"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <TemperatureColumnHeader
        column="ground"
        label="Темп. грунта"
        unit="°C"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <TemperatureColumnHeader
        column="gvsSupply"
        label="Подача ГВС"
        unit="°C"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <TemperatureColumnHeader
        column="gvsReturn"
        label="Обратка ГВС"
        unit="°C"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <TemperatureColumnHeader
        column="actions"
        label="Действия"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
    </tr>
  );
}

function TemperatureColumnHeader({
  column,
  label,
  unit,
  selectedColumn,
  onSelect,
}: {
  column: TemperatureColumn;
  label: string;
  unit?: string;
  selectedColumn: TemperatureColumn | null;
  onSelect: (column: TemperatureColumn) => void;
}) {
  const selected = selectedColumn === column;

  return (
    <th
      scope="col"
      className={`p-0 transition-colors ${
        selected ? "bg-[#174936] text-white" : "hover:bg-[#2d7057]"
      }`}
    >
      <button
        type="button"
        aria-pressed={selected}
        aria-label={
          selected
            ? `Снять выделение столбца «${label}»`
            : `Выделить столбец «${label}»`
        }
        title="Нажмите, чтобы выделить столбец"
        onClick={() => onSelect(column)}
        className="flex min-h-[76px] w-full cursor-pointer flex-col items-center justify-center px-3 py-5 text-center leading-tight text-white transition-colors focus-visible:relative focus-visible:z-10 focus-visible:outline-2 focus-visible:outline-inset focus-visible:outline-white"
      >
        <span>{label}</span>
        {unit ? (
          <span
            className="mt-1 block text-[11px] font-medium tracking-normal text-white normal-case"
          >
            {unit}
          </span>
        ) : null}
      </button>
    </th>
  );
}

function TemperatureCell({
  editing,
  disabled,
  selected,
  label,
  value,
  draftValue,
  onChange,
}: {
  editing: boolean;
  disabled: boolean;
  selected: boolean;
  label: string;
  value: number | null;
  draftValue: string;
  onChange: (value: string) => void;
}) {
  return (
    <td
      className={`px-3 py-4 text-center transition-colors ${
        selected ? "bg-[#eaf4ed]" : ""
      }`}
    >
      {editing ? (
        <div className="relative mx-auto w-28">
          <input
            type="text"
            inputMode="decimal"
            aria-label={label}
            value={draftValue}
            disabled={disabled}
            onChange={(event) => onChange(event.target.value)}
            className="w-full rounded-xl border border-[#b9cbbf] bg-white py-2 pr-8 pl-3 text-right text-sm font-semibold tabular-nums outline-none transition focus:border-[#4f866d] focus:ring-3 focus:ring-[#4f866d]/12"
          />
          <span className="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2 text-xs text-[#84928b]">
            °C
          </span>
        </div>
      ) : (
        <span className="font-semibold text-[#34433d] tabular-nums">
          {value === null ? "—" : `${temperatureFormatter.format(value)} °C`}
        </span>
      )}
    </td>
  );
}

function TableSkeleton() {
  return (
    <div className="animate-pulse p-5 sm:p-6">
      {[0, 1, 2, 3].map((item) => (
        <div
          key={item}
          className="grid grid-cols-7 gap-4 border-b border-[#edf0ed] py-4"
        >
          <div className="h-8 rounded-lg bg-[#e5ebe6]" />
          <div className="h-8 rounded-lg bg-[#eef2ee]" />
          <div className="h-8 rounded-lg bg-[#e5ebe6]" />
          <div className="h-8 rounded-lg bg-[#eef2ee]" />
          <div className="h-8 rounded-lg bg-[#e5ebe6]" />
          <div className="h-8 rounded-lg bg-[#eef2ee]" />
          <div className="h-8 rounded-lg bg-[#e5ebe6]" />
        </div>
      ))}
    </div>
  );
}

async function requestJSON<T>(url: string, init: RequestInit = {}) {
  const response = await fetch(url, { ...init, cache: "no-store" });
  const body = (await response.json().catch(() => ({}))) as ErrorResponse & T;

  if (!response.ok) {
    throw new Error(body.error ?? `Ошибка запроса: ${response.status}`);
  }

  return body;
}

function inputValue(value: number | null | undefined) {
  return value == null ? "" : String(value).replace(".", ",");
}

function parseTemperature(value: string) {
  const normalized = value.trim().replace(",", ".");
  if (!normalized) return null;

  const parsed = Number(normalized);
  if (!Number.isFinite(parsed) || Math.abs(parsed) > 9999.99) return null;

  return parsed;
}

function emptyDraft(): Draft {
  return { supply: "", returnTemperature: "", ground: "", gvsSupply: "", gvsReturn: "" };
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : "Неизвестная ошибка";
}

function isAbortError(error: unknown) {
  return error instanceof DOMException && error.name === "AbortError";
}
