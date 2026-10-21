"use client";

import { useEffect, useRef, useState } from "react";

import { SiteHeader } from "../_components/site-header";

type LossRow = {
  heat_network_id: number;
  heat_network_name: string;
  month: string;
  total_normalized_heat_loss_per_hour: number | null;
  loss_gj: number | null;
  calculation_error?: string;
};

type LossesResponse = {
  month: string;
  losses: LossRow[];
};

type ErrorResponse = {
  error?: string;
};

type LossColumn = "network" | "loss_gj" | "loss_gcal";

const lossFormatter = new Intl.NumberFormat("ru-RU", {
  minimumFractionDigits: 3,
  maximumFractionDigits: 6,
});

export function LossesWorkspace({ initialMonth }: { initialMonth: string }) {
  const [month, setMonth] = useState(initialMonth);
  const [rows, setRows] = useState<LossRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [reloadVersion, setReloadVersion] = useState(0);
  const [selectedColumn, setSelectedColumn] = useState<LossColumn | null>(null);
  const stickyHeaderTrack = useRef<HTMLDivElement | null>(null);

  function toggleColumn(column: LossColumn) {
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

    async function loadLosses() {
      setLoading(true);
      setLoadError(null);

      try {
        const response = await requestJSON<LossesResponse>(
          `/api/losses?month=${encodeURIComponent(month)}`,
          controller.signal,
        );
        setRows(response.losses ?? []);
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

    void loadLosses();
    return () => controller.abort();
  }, [month, reloadVersion]);

  return (
    <main className="relative min-h-screen overflow-x-clip bg-[#f2f5f1] text-[#17221f]">
      <div className="pointer-events-none absolute inset-x-0 top-0 h-[430px] bg-[radial-gradient(circle_at_82%_0%,rgba(61,121,97,0.17),transparent_38%),radial-gradient(circle_at_14%_8%,rgba(210,171,91,0.13),transparent_32%)]" />

      <SiteHeader />

      <div className="relative mx-auto w-[calc(100%-2rem)] py-9 sm:w-[90%] sm:py-12 xl:w-[85%]">
        <section className="mb-7 flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="max-w-4xl text-3xl font-semibold tracking-[-0.045em] text-[#17221f] ">
              Потери теплосети за расчётный период
            </h1>
           
          </div>

          <label className="w-full shrink-0 rounded-2xl border border-[#d8e2da] bg-white px-4 py-3 shadow-sm sm:w-60">
            <span className="block text-[11px] font-bold tracking-[0.08em] text-[#64746c] uppercase">
              Расчётный месяц
            </span>
            <input
              type="month"
              value={month}
              onChange={(event) => setMonth(event.target.value)}
              className="mt-1.5 w-full bg-transparent text-base font-semibold text-[#1d2b26] outline-none"
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
                  className="mt-4 rounded-xl bg-[#245f4a] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#1d503e] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#2d7458]"
                >
                  Повторить
                </button>
              </div>
            </div>
          ) : rows.length === 0 ? (
            <div className="grid min-h-72 place-items-center px-6 py-12 text-center text-sm text-[#718078]">
              В базе пока нет теплосетей
            </div>
          ) : (
            <>
              <div className="sticky top-0 z-30 overflow-hidden rounded-t-[20px] border-y border-[#194a38] bg-[#225e49] shadow-[0_8px_18px_rgba(28,52,43,0.18)]">
                <div ref={stickyHeaderTrack} className="will-change-transform">
                  <table className="w-full min-w-[680px] table-fixed border-collapse text-left">
                    <LossColumnWidths />
                    <thead>
                      <LossHeaderRows
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
                <table className="w-full min-w-[680px] table-fixed border-collapse text-left">
                  <LossColumnWidths />
                  <thead className="sr-only">
                    <tr>
                      <th scope="col" rowSpan={2}>Название теплосети</th>
                      <th scope="colgroup" colSpan={2}>Потери за расчётный период</th>
                    </tr>
                    <tr>
                      <th scope="col">ГДж</th>
                      <th scope="col">Гкал</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#e8ede9]">
                    {rows.map((row) => (
                      <tr
                        key={row.heat_network_id}
                        className="group transition-colors hover:bg-[#f8faf8]"
                      >
                        <th
                          scope="row"
                          className={`px-3 py-4 text-center transition-colors ${
                            selectedColumn === "network" ? "bg-[#eaf4ed]" : ""
                          }`}
                        >
                          <div className="flex items-center justify-center gap-2.5">
                            <span className="inline-flex rounded-lg bg-[#edf3ef] px-2.5 py-1.5 text-xs font-bold text-[#356851] tabular-nums">
                              #{row.heat_network_id}
                            </span>
                            <span className="text-sm font-semibold text-[#26332e]">
                              {row.heat_network_name}
                            </span>
                          </div>
                        </th>
                        <LossValueCell
                          value={row.loss_gj}
                          unit="ГДж"
                          calculationError={row.calculation_error}
                          selected={selectedColumn === "loss_gj"}
                        />
                        <LossValueCell
                          value={row.loss_gj === null ? null : row.loss_gj / 4.184}
                          unit="Гкал"
                          calculationError={row.calculation_error}
                          selected={selectedColumn === "loss_gcal"}
                        />
                      </tr>
                    ))}
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

function LossValueCell({
  value,
  unit,
  calculationError,
  selected,
}: {
  value: number | null;
  unit: string;
  calculationError?: string;
  selected: boolean;
}) {
  return (
    <td
      className={`px-3 py-4 text-center transition-colors ${
        selected ? "bg-[#eaf4ed]" : ""
      }`}
    >
      {value === null ? (
        <div title={calculationError} className="text-sm text-[#a14c38]">
          <p className="inline-flex rounded-full bg-[#f9ebe6] px-2.5 py-1 text-xs font-semibold text-[#a14c38]">
            Недостаточно данных
          </p>
          {calculationError ? (
            <p className="mx-auto mt-1 max-w-md text-xs leading-5 text-[#87655d]">
              {calculationError}
            </p>
          ) : null}
        </div>
      ) : (
        <span className="text-sm font-bold text-[#704f20] tabular-nums">
          {lossFormatter.format(value)}
          <span className="ml-1.5 text-xs font-semibold text-[#718078]">
            {unit}
          </span>
        </span>
      )}
    </td>
  );
}

function LossColumnWidths() {
  return (
    <>
      <colgroup>
        <col className="w-1/2" />
      </colgroup>
      <colgroup>
        <col className="w-1/4" />
        <col className="w-1/4" />
      </colgroup>
    </>
  );
}

function LossHeaderRows({
  selectedColumn,
  onSelect,
}: {
  selectedColumn: LossColumn | null;
  onSelect: (column: LossColumn) => void;
}) {
  return (
    <>
      <tr className="bg-[#225e49] text-sm font-semibold tracking-[-0.01em] text-white">
        <LossColumnHeader
          column="network"
          label="Название теплосети"
          rowSpan={2}
          selectedColumn={selectedColumn}
          onSelect={onSelect}
        />
        <th
          scope="colgroup"
          colSpan={2}
          className="border-l border-white/15 px-3 py-3 text-center"
        >
          Потери за расчётный период
        </th>
      </tr>
      <tr className="bg-[#225e49] text-sm font-semibold tracking-[-0.01em] text-white">
        <LossColumnHeader
          column="loss_gj"
          label="Потери за расчётный период"
          unit="ГДж"
          selectedColumn={selectedColumn}
          onSelect={onSelect}
        />
        <LossColumnHeader
          column="loss_gcal"
          label="Потери за расчётный период"
          unit="Гкал"
          selectedColumn={selectedColumn}
          onSelect={onSelect}
        />
      </tr>
    </>
  );
}

function LossColumnHeader({
  column,
  label,
  unit,
  rowSpan = 1,
  selectedColumn,
  onSelect,
}: {
  column: LossColumn;
  label: string;
  unit?: string;
  rowSpan?: number;
  selectedColumn: LossColumn | null;
  onSelect: (column: LossColumn) => void;
}) {
  const selected = selectedColumn === column;
  const accessibleLabel = unit ? `${label}, ${unit}` : label;

  return (
    <th
      scope="col"
      rowSpan={rowSpan}
      className={`p-0 transition-colors ${
        selected ? "bg-[#174936] text-white" : "hover:bg-[#2d7057]"
      } ${unit ? "border-t border-l border-white/15" : ""}`}
    >
      <button
        type="button"
        aria-pressed={selected}
        aria-label={
          selected
            ? `Снять выделение столбца «${accessibleLabel}»`
            : `Выделить столбец «${accessibleLabel}»`
        }
        title="Нажмите, чтобы выделить столбец"
        onClick={() => onSelect(column)}
        className={`flex w-full cursor-pointer items-center justify-center px-3 text-center leading-tight text-white transition-colors focus-visible:relative focus-visible:z-10 focus-visible:outline-2 focus-visible:outline-inset focus-visible:outline-white ${
          unit ? "min-h-10 py-2.5" : "min-h-[84px] py-5"
        }`}
      >
        <span>{unit ?? label}</span>
      </button>
    </th>
  );
}

function TableSkeleton() {
  return (
    <div className="animate-pulse">
      <div className="grid min-h-[84px] grid-cols-[2fr_1fr_1fr] grid-rows-2 items-center gap-x-6 gap-y-3 border-y border-[#dfe6e0] bg-[#f6f8f6] px-5 py-3">
        <div className="row-span-2 mx-auto h-4 w-36 max-w-full rounded bg-[#dce6df]" />
        <div className="col-span-2 mx-auto h-4 w-44 max-w-full rounded bg-[#dce6df]" />
        <div className="mx-auto h-4 w-12 max-w-full rounded bg-[#dce6df]" />
        <div className="mx-auto h-4 w-12 max-w-full rounded bg-[#dce6df]" />
      </div>
      {Array.from({ length: 4 }, (_, index) => (
        <div
          key={index}
          className="grid grid-cols-[2fr_1fr_1fr] gap-6 border-t border-[#e8ede9] px-5 py-5"
        >
          <div className="mx-auto h-4 w-40 max-w-full rounded bg-[#edf1ee]" />
          <div className="mx-auto h-4 w-24 max-w-full rounded bg-[#edf1ee]" />
          <div className="mx-auto h-4 w-24 max-w-full rounded bg-[#edf1ee]" />
        </div>
      ))}
    </div>
  );
}

async function requestJSON<T>(url: string, signal: AbortSignal): Promise<T> {
  const response = await fetch(url, {
    signal,
    headers: { Accept: "application/json" },
    cache: "no-store",
  });
  const body = (await response.json().catch(() => ({}))) as T & ErrorResponse;

  if (!response.ok) {
    throw new Error(body.error || `Ошибка запроса: ${response.status}`);
  }

  return body;
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : "Неизвестная ошибка";
}

function isAbortError(error: unknown) {
  return error instanceof DOMException && error.name === "AbortError";
}
