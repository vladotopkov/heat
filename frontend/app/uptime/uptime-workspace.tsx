"use client";

import { useEffect, useRef, useState } from "react";

import { SiteHeader } from "../_components/site-header";

type UptimeRow = {
  id: number | null;
  heat_network_id: number;
  heat_network_name: string;
  month: string;
  hours_per_month: number | null;
};

type UptimeResponse = {
  month: string;
  uptime: UptimeRow[];
};

type ErrorResponse = {
  error?: string;
};

type UptimeColumn = "network" | "hours" | "actions";

const hoursFormatter = new Intl.NumberFormat("ru-RU", {
  maximumFractionDigits: 0,
});

export function UptimeWorkspace({ initialMonth }: { initialMonth: string }) {
  const [month, setMonth] = useState(initialMonth);
  const [rows, setRows] = useState<UptimeRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [reloadVersion, setReloadVersion] = useState(0);
  const [editingID, setEditingID] = useState<number | null>(null);
  const [savingID, setSavingID] = useState<number | null>(null);
  const [savedID, setSavedID] = useState<number | null>(null);
  const [draftHours, setDraftHours] = useState("");
  const [editError, setEditError] = useState<string | null>(null);
  const [selectedColumn, setSelectedColumn] =
    useState<UptimeColumn | null>(null);
  const stickyHeaderTrack = useRef<HTMLDivElement | null>(null);

  function toggleColumn(column: UptimeColumn) {
    setSelectedColumn((current) => (current === column ? null : column));
  }

  function syncHeaderScroll(scrollLeft: number) {
    if (stickyHeaderTrack.current) {
      stickyHeaderTrack.current.style.transform = `translateX(-${scrollLeft}px)`;
    }
  }

  useEffect(() => {
    const controller = new AbortController();

    async function loadUptime() {
      setLoading(true);
      setLoadError(null);
      setEditingID(null);
      setSavedID(null);

      try {
        const response = await requestJSON<UptimeResponse>(
          `/api/uptime?month=${encodeURIComponent(month)}`,
          { signal: controller.signal },
        );
        setRows(response.uptime ?? []);
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

    void loadUptime();
    return () => controller.abort();
  }, [month, reloadVersion]);

  function startEditing(row: UptimeRow) {
    setEditingID(row.heat_network_id);
    setSavedID(null);
    setEditError(null);
    setDraftHours(
      row.hours_per_month === null ? "" : String(row.hours_per_month),
    );
  }

  function cancelEditing() {
    setEditingID(null);
    setEditError(null);
    setDraftHours("");
  }

  async function saveRow(row: UptimeRow) {
    const hours = parseHours(draftHours);
    if (hours === null) {
      setEditError("Введите целое число часов от 0 до 744");
      return;
    }

    setSavingID(row.heat_network_id);
    setEditError(null);

    try {
      const saved = await requestJSON<UptimeRow>(
        `/api/heat-networks/${row.heat_network_id}/uptime/${month}`,
        {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ hours_per_month: hours }),
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
      setDraftHours("");
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
              Часы работы за месяц
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
                  <table className="w-full min-w-[660px] table-fixed border-collapse text-left">
                    <UptimeColumnWidths />
                    <thead>
                      <UptimeHeaderRow
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
                <table className="w-full min-w-[660px] table-fixed border-collapse text-left">
                  <UptimeColumnWidths />
                  <thead className="sr-only">
                    <tr>
                      <th>Теплосеть</th>
                      <th>Часы работы, ч/месяц</th>
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
                          className={`group transition-colors ${
                            editing ? "bg-[#eaf4ed]" : "hover:bg-[#f8faf8]"
                          }`}
                        >
                          <td
                            className={`px-3 py-4 text-center transition-colors ${
                              selectedColumn === "network"
                                ? "bg-[#eaf4ed]"
                                : ""
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
                          <td
                            className={`px-3 py-4 text-center transition-colors ${
                              selectedColumn === "hours"
                                ? "bg-[#eaf4ed]"
                                : ""
                            }`}
                          >
                            {editing ? (
                              <div className="relative mx-auto w-36">
                                <input
                                  type="text"
                                  inputMode="numeric"
                                  aria-label={`Часы работы, ${row.heat_network_name}`}
                                  value={draftHours}
                                  onChange={(event) =>
                                    setDraftHours(event.target.value)
                                  }
                                  className="w-full rounded-xl border border-[#b9cbbf] bg-white py-2 pr-14 pl-3 text-right text-sm font-semibold tabular-nums outline-none transition focus:border-[#4f866d] focus:ring-3 focus:ring-[#4f866d]/12"
                                />
                                <span className="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2 text-xs text-[#84928b]">
                                  часов
                                </span>
                              </div>
                            ) : (
                              <span className="font-semibold text-[#34433d] tabular-nums">
                                {row.hours_per_month === null
                                  ? "—"
                                  : `${hoursFormatter.format(row.hours_per_month)} ч`}
                              </span>
                            )}
                          </td>
                          <td
                            className={`px-3 py-4 text-center transition-colors ${
                              selectedColumn === "actions"
                                ? "bg-[#eaf4ed]"
                                : ""
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

function UptimeColumnWidths() {
  return (
    <colgroup>
      <col className="w-[42%]" />
      <col />
      <col className="w-44" />
    </colgroup>
  );
}

function UptimeHeaderRow({
  selectedColumn,
  onSelect,
}: {
  selectedColumn: UptimeColumn | null;
  onSelect: (column: UptimeColumn) => void;
}) {
  return (
    <tr className="bg-[#225e49] text-sm font-semibold tracking-[-0.01em] text-white">
      <UptimeColumnHeader
        column="network"
        label="Теплосеть"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <UptimeColumnHeader
        column="hours"
        label="Часы работы"
        unit="ч/месяц"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <UptimeColumnHeader
        column="actions"
        label="Действия"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
    </tr>
  );
}

function UptimeColumnHeader({
  column,
  label,
  unit,
  selectedColumn,
  onSelect,
}: {
  column: UptimeColumn;
  label: string;
  unit?: string;
  selectedColumn: UptimeColumn | null;
  onSelect: (column: UptimeColumn) => void;
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
          <span className="mt-1 block text-[11px] font-medium tracking-normal text-white normal-case">
            {unit}
          </span>
        ) : null}
      </button>
    </th>
  );
}

function TableSkeleton() {
  return (
    <div className="animate-pulse p-5 sm:p-6">
      {[0, 1, 2, 3].map((item) => (
        <div
          key={item}
          className="grid grid-cols-3 gap-4 border-b border-[#edf0ed] py-4"
        >
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

function parseHours(value: string) {
  const normalized = value.trim();
  if (!/^\d+$/.test(normalized)) return null;

  const parsed = Number(normalized);
  if (!Number.isInteger(parsed) || parsed < 0 || parsed > 744) return null;

  return parsed;
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : "Неизвестная ошибка";
}

function isAbortError(error: unknown) {
  return error instanceof DOMException && error.name === "AbortError";
}
