"use client";

import {
  type PointerEvent as ReactPointerEvent,
  useEffect,
  useRef,
  useState,
} from "react";

import { SiteHeader } from "../_components/site-header";

type HeatNetwork = {
  id: number;
  name: string;
};

type NetworkSection = {
  id: number;
  supply_outer_diameter_mm: number | null;
  laying_type: string | null;
  underground_laying_type: string | null;
  supply_temperature_c: number | null;
  return_temperature_c: number | null;
  length_m: number | null;
  project_date: string | null;
  qh_value: number | null;
  qh_error?: string;
  beta: number | null;
  beta_error?: string;
};

type HeatNetworksResponse = {
  heat_networks: HeatNetwork[];
};

type NetworkSectionsResponse = {
  heat_network: HeatNetwork;
  sections: NetworkSection[];
};

type ErrorResponse = {
  error?: string;
};

type SectionColumn =
  | "id"
  | "supplyOuterDiameter"
  | "layingType"
  | "undergroundLayingType"
  | "supplyTemperature"
  | "returnTemperature"
  | "length"
  | "projectDate"
  | "qh"
  | "beta"
  | "normalizedHeatLossPerHour";

const numberFormatter = new Intl.NumberFormat("ru-RU", {
  maximumFractionDigits: 3,
});

const dateFormatter = new Intl.DateTimeFormat("ru-RU", {
  day: "2-digit",
  month: "2-digit",
  year: "numeric",
});

const betaFormatter = new Intl.NumberFormat("ru-RU", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

export function TablesWorkspace() {
  const [networks, setNetworks] = useState<HeatNetwork[]>([]);
  const [networksLoading, setNetworksLoading] = useState(true);
  const [networksError, setNetworksError] = useState<string | null>(null);
  const [selectedNetworkID, setSelectedNetworkID] = useState<number | null>(
    null,
  );
  const [sectionsData, setSectionsData] =
    useState<NetworkSectionsResponse | null>(null);
  const [sectionsLoading, setSectionsLoading] = useState(false);
  const [sectionsError, setSectionsError] = useState<string | null>(null);
  const sectionsRequest = useRef<AbortController | null>(null);

  async function reloadNetworks() {
    setNetworksLoading(true);
    setNetworksError(null);

    try {
      const response = await requestJSON<HeatNetworksResponse>(
        "/api/heat-networks",
      );
      setNetworks(response.heat_networks ?? []);
    } catch (error) {
      setNetworksError(errorMessage(error));
    } finally {
      setNetworksLoading(false);
    }
  }

  useEffect(() => {
    const controller = new AbortController();

    async function initializeNetworks() {
      try {
        const response = await requestJSON<HeatNetworksResponse>(
          "/api/heat-networks",
          controller.signal,
        );
        setNetworks(response.heat_networks ?? []);
      } catch (error) {
        if (!isAbortError(error)) {
          setNetworksError(errorMessage(error));
        }
      } finally {
        if (!controller.signal.aborted) {
          setNetworksLoading(false);
        }
      }
    }

    void initializeNetworks();

    return () => controller.abort();
  }, []);

  useEffect(() => {
    return () => sectionsRequest.current?.abort();
  }, []);

  async function selectNetwork(network: HeatNetwork) {
    sectionsRequest.current?.abort();
    const controller = new AbortController();
    sectionsRequest.current = controller;

    setSelectedNetworkID(network.id);
    setSectionsData(null);
    setSectionsError(null);
    setSectionsLoading(true);

    try {
      const response = await requestJSON<NetworkSectionsResponse>(
        `/api/heat-networks/${network.id}/sections`,
        controller.signal,
      );
      setSectionsData(response);
    } catch (error) {
      if (!isAbortError(error)) {
        setSectionsError(errorMessage(error));
      }
    } finally {
      if (!controller.signal.aborted) {
        setSectionsLoading(false);
      }
    }
  }

  return (
    <main className="relative min-h-screen overflow-x-clip bg-[#f2f5f1] text-[#17221f]">
      <div className="pointer-events-none absolute inset-x-0 top-0 h-[420px] bg-[radial-gradient(circle_at_82%_0%,rgba(61,121,97,0.16),transparent_38%),radial-gradient(circle_at_15%_8%,rgba(210,171,91,0.12),transparent_32%)]" />

      <SiteHeader />

      <div className="relative mx-auto w-[calc(100%-2rem)] py-9 sm:w-[90%] sm:py-12 xl:w-[85%]">
        <section className="mb-7">
          <h1 className="text-4xl font-semibold tracking-[-0.045em] text-[#17221f]">
            Участки теплосетей
          </h1>
        </section>

        <div className="space-y-5">
          <section className="overflow-hidden rounded-[22px] border border-[#dce4dd] bg-white shadow-[0_16px_45px_rgba(30,55,45,0.055)]">
            <div className="border-b border-[#e4e9e5] px-5 py-4 sm:px-6">
              <p className="text-[11px] font-bold tracking-[0.14em] text-[#829087] uppercase">
                Тепловые сети
              </p>
              <h2 className="mt-1 text-lg font-semibold tracking-[-0.02em]">
                Выберите объект
              </h2>
            </div>

            <div className="p-3 sm:p-4">
              {networksLoading ? (
                <NetworkListSkeleton />
              ) : networksError ? (
                <InlineError
				  message={networksError}
				  onRetry={() => void reloadNetworks()}
                />
              ) : networks.length === 0 ? (
                <p className="px-3 py-8 text-center text-sm leading-6 text-[#718078]">
                  В базе пока нет теплосетей
                </p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {networks.map((network, index) => {
                    const selected = selectedNetworkID === network.id;

                    return (
                      <button
                        key={network.id}
                        type="button"
                        aria-pressed={selected}
                        onClick={() => void selectNetwork(network)}
                        className={`group flex min-w-56 items-center gap-3 rounded-2xl px-3 py-3 text-left transition duration-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#2d7458] ${
                          selected
                            ? "bg-[#245f4a] text-white shadow-[0_8px_22px_rgba(36,95,74,0.2)]"
                            : "text-[#24322d] hover:bg-[#f1f5f1]"
                        }`}
                      >
                        <span
                          className={`grid size-9 shrink-0 place-items-center rounded-xl text-xs font-bold tabular-nums ${
                            selected
                              ? "bg-white/13 text-white"
                              : "bg-[#e9f0eb] text-[#39715b]"
                          }`}
                        >
                          {String(index + 1).padStart(2, "0")}
                        </span>
                        <span className="min-w-0 flex-1">
                          <span className="block truncate text-sm font-semibold">
                            {network.name}
                          </span>
                          <span
                            className={`mt-0.5 block text-[11px] ${
                              selected ? "text-white/65" : "text-[#8a9790]"
                            }`}
                          >
                            ID {network.id}
                          </span>
                        </span>
                        <ArrowIcon selected={selected} />
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          </section>

          <section className="min-w-0">
            {selectedNetworkID === null ? (
              <EmptySelection />
            ) : sectionsLoading ? (
              <TableLoading />
            ) : sectionsError ? (
              <section className="grid min-h-[420px] place-items-center rounded-[22px] border border-[#dce4dd] bg-white p-8 shadow-[0_16px_45px_rgba(30,55,45,0.055)]">
                <div className="max-w-md text-center">
                  <div className="mx-auto grid size-12 place-items-center rounded-full bg-[#fbeae5] text-[#a94e39]">
                    <ErrorIcon />
                  </div>
                  <h2 className="mt-4 text-xl font-semibold">
                    Не удалось загрузить участки
                  </h2>
                  <p className="mt-2 text-sm leading-6 text-[#718078]">
                    {sectionsError}
                  </p>
                  <button
                    type="button"
                    onClick={() => {
                      const network = networks.find(
                        (item) => item.id === selectedNetworkID,
                      );
                      if (network) void selectNetwork(network);
                    }}
                    className="mt-5 rounded-xl bg-[#245f4a] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#194b39] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#245f4a]"
                  >
                    Повторить
                  </button>
                </div>
              </section>
            ) : sectionsData ? (
              <SectionsTable data={sectionsData} />
            ) : null}
          </section>
        </div>
      </div>
    </main>
  );
}

function SectionsTable({ data }: { data: NetworkSectionsResponse }) {
  const [selectedColumn, setSelectedColumn] = useState<SectionColumn | null>(
    null,
  );
  const stickyHeaderTrack = useRef<HTMLDivElement | null>(null);
  const horizontalDrag = useRef<{
    pointerID: number | null;
    startX: number;
    scrollLeft: number;
  }>({
    pointerID: null,
    startX: 0,
    scrollLeft: 0,
  });
  const totalNormalizedHeatLossPerHour =
    calculateTotalNormalizedHeatLossPerHour(data.sections);
  const showOuterDiameter = data.heat_network.name === "Еремичи";
  const tableClassName = `${showOuterDiameter ? "w-[1485px]" : "w-[1340px]"} table-fixed border-collapse text-left`;

  function toggleColumn(column: SectionColumn) {
    setSelectedColumn((current) => (current === column ? null : column));
  }

  function syncHeaderScroll(scrollLeft: number) {
    if (stickyHeaderTrack.current) {
      stickyHeaderTrack.current.style.transform = `translateX(-${scrollLeft}px)`;
    }
  }

  function startHorizontalDrag(event: ReactPointerEvent<HTMLDivElement>) {
    if (event.pointerType !== "mouse" || event.button !== 0) return;

    horizontalDrag.current = {
      pointerID: event.pointerId,
      startX: event.clientX,
      scrollLeft: event.currentTarget.scrollLeft,
    };
    event.currentTarget.setPointerCapture(event.pointerId);
  }

  function moveHorizontalDrag(event: ReactPointerEvent<HTMLDivElement>) {
    const drag = horizontalDrag.current;
    if (drag.pointerID !== event.pointerId) return;

    event.preventDefault();
    event.currentTarget.scrollLeft =
      drag.scrollLeft - (event.clientX - drag.startX);
  }

  function stopHorizontalDrag(event: ReactPointerEvent<HTMLDivElement>) {
    if (horizontalDrag.current.pointerID !== event.pointerId) return;

    horizontalDrag.current.pointerID = null;
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
  }

  return (
    <section className="rounded-[22px] border border-[#dce4dd] bg-white shadow-[0_16px_45px_rgba(30,55,45,0.055)]">
      <div className="flex flex-col gap-4 border-b border-[#e2e8e3] px-5 py-5 sm:flex-row sm:items-end sm:justify-between sm:px-6">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold text-[#39715b]">
            <span className="size-1.5 rounded-full bg-[#3b8c69]" />
            Выбранная теплосеть
          </div>
          <h2 className="mt-1.5 text-2xl font-semibold tracking-[-0.035em]">
            {data.heat_network.name}
          </h2>
        </div>

        <div className="shrink-0 rounded-2xl border border-[#dce6df] bg-[#f3f7f4] px-4 py-3 sm:text-right">
          <p className="text-[11px] font-bold tracking-[0.08em] text-[#66766e] uppercase">
            ΣQнорм:
          </p>
          {totalNormalizedHeatLossPerHour === null ? (
            <p
              title="Для расчёта суммы необходимы qh, β и длина каждого участка"
              className="mt-1 text-sm font-semibold text-[#a14c38]"
            >
              Недостаточно данных
            </p>
          ) : (
            <p className="mt-1 text-lg font-bold text-[#245f4a] tabular-nums">
              {formatNumber(totalNormalizedHeatLossPerHour)}
              <span className="ml-1 text-xs font-semibold text-[#718078]">
                кДж/ч
              </span>
            </p>
          )}
        </div>
      </div>

      {data.sections.length === 0 ? (
        <div className="grid min-h-[330px] place-items-center px-6 py-12 text-center">
          <div>
            <div className="mx-auto grid size-12 place-items-center rounded-full bg-[#eef3ef] text-[#547064]">
              <NetworkMark />
            </div>
            <h3 className="mt-4 text-lg font-semibold">Участков пока нет</h3>
            <p className="mt-1.5 text-sm text-[#718078]">
              Для этой теплосети в базе не найдено участков.
            </p>
          </div>
        </div>
      ) : (
        <>
          <div className="sticky top-0 z-30 overflow-hidden border-y border-[#dfe6e0] bg-[#f6f8f6] shadow-[0_8px_18px_rgba(28,52,43,0.12)]">
            <div ref={stickyHeaderTrack} className="will-change-transform">
              <table className={tableClassName}>
                <SectionsColumnWidths showOuterDiameter={showOuterDiameter} />
                <thead>
                  <SectionsHeaderRow
                    showOuterDiameter={showOuterDiameter}
                    selectedColumn={selectedColumn}
                    onSelect={toggleColumn}
                  />
                </thead>
              </table>
            </div>
          </div>

          <div
            className="cursor-grab select-none overflow-x-auto active:cursor-grabbing"
            title="Зажмите левую кнопку мыши и перетащите таблицу в сторону"
            onPointerDown={startHorizontalDrag}
            onPointerMove={moveHorizontalDrag}
            onPointerUp={stopHorizontalDrag}
            onPointerCancel={stopHorizontalDrag}
            onLostPointerCapture={stopHorizontalDrag}
            onScroll={(event) =>
              syncHeaderScroll(event.currentTarget.scrollLeft)
            }
          >
          <table className={tableClassName}>
            <SectionsColumnWidths showOuterDiameter={showOuterDiameter} />
            <thead className="sr-only">
              <tr className="border-b border-[#dfe6e0] bg-[#f6f8f6] text-[11px] font-bold tracking-[0.065em] text-[#66766e] uppercase">
                <th className="w-28 px-5 py-4 sm:px-6">ID участка</th>
                {showOuterDiameter ? (
                  <th scope="col" className="px-4 py-4 text-center">
                    Наружный диаметр
                    <span className="mt-0.5 block font-medium tracking-normal text-[#95a199] normal-case">
                      мм
                    </span>
                  </th>
                ) : null}
                <th className="min-w-32 px-5 py-4 text-right sm:px-6">
                  qh
                  <span className="mt-0.5 block font-medium tracking-normal text-[#95a199] normal-case">
                    Вт/м
                  </span>
                </th>
                <th className="min-w-28 px-5 py-4 text-right sm:px-6">
                  β
                  <span className="mt-0.5 block font-medium tracking-normal text-[#95a199] normal-case">
                    коэффициент
                  </span>
                </th>
                <th className="min-w-40 px-5 py-4 text-right sm:px-6">
                  Q_норм/ч
                  <span className="mt-0.5 block font-medium tracking-normal text-[#95a199] normal-case">
                    кДж/ч
                  </span>
                </th>
                <th className="min-w-44 px-4 py-4">Тип прокладки</th>
                <th className="min-w-52 px-4 py-4">
                  Подземная прокладка
                </th>
                <th className="min-w-36 px-4 py-4 text-right">
                  Температура подачи
                  <span className="mt-0.5 block font-medium tracking-normal text-[#95a199] normal-case">
                    °C
                  </span>
                </th>
                <th className="min-w-36 px-4 py-4 text-right">
                  Температура обратки
                  <span className="mt-0.5 block font-medium tracking-normal text-[#95a199] normal-case">
                    °C
                  </span>
                </th>
                <th className="min-w-28 px-4 py-4 text-right">
                  Длина
                  <span className="mt-0.5 block font-medium tracking-normal text-[#95a199] normal-case">
                    м
                  </span>
                </th>
                <th className="min-w-36 px-4 py-4">Дата проекта</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#e8ede9]">
              {data.sections.map((section) => (
                <tr
                  key={section.id}
                  className="group transition-colors hover:bg-[#f8faf8]"
                >
                  <td
                    className={`px-3 py-4 text-center transition-colors ${
                      selectedColumn === "id" ? "bg-[#eaf4ed]" : ""
                    }`}
                  >
                    <span className="inline-flex rounded-lg bg-[#edf3ef] px-2.5 py-1.5 text-xs font-bold text-[#356851] tabular-nums">
                      #{section.id}
                    </span>
                  </td>
                  {showOuterDiameter ? (
                    <td
                      className={`px-3 py-4 text-center text-sm font-medium tabular-nums transition-colors ${
                        selectedColumn === "supplyOuterDiameter"
                          ? "bg-[#eaf4ed]"
                          : ""
                      }`}
                    >
                      {formatNullableNumber(section.supply_outer_diameter_mm)}
                    </td>
                  ) : null}
                  <td
                    className={`px-3 py-4 text-center transition-colors ${
                      selectedColumn === "qh" ? "bg-[#eaf4ed]" : ""
                    }`}
                  >
                    {section.qh_value === null ? (
                      <span
                        title={section.qh_error}
                        className="inline-flex rounded-full bg-[#f9ebe6] px-2.5 py-1 text-xs font-semibold text-[#a14c38]"
                      >
                        Не найдено
                      </span>
                    ) : (
                      <span className="inline-flex rounded-full bg-[#e5f2ea] px-2.5 py-1 text-sm font-bold text-[#246047] tabular-nums">
                        {formatNumber(section.qh_value)}
                      </span>
                    )}
                  </td>
                  <td
                    className={`px-3 py-4 text-center transition-colors ${
                      selectedColumn === "beta" ? "bg-[#eaf4ed]" : ""
                    }`}
                  >
                    {section.beta === null ? (
                      <span
                        title={section.beta_error}
                        className="inline-flex rounded-full bg-[#f9ebe6] px-2.5 py-1 text-xs font-semibold text-[#a14c38]"
                      >
                        Не найдено
                      </span>
                    ) : (
                      <span className="inline-flex rounded-full bg-[#e8eef8] px-2.5 py-1 text-sm font-bold text-[#3b5983] tabular-nums">
                        {betaFormatter.format(section.beta)}
                      </span>
                    )}
                  </td>
                  <td
                    className={`px-3 py-4 text-center transition-colors ${
                      selectedColumn === "normalizedHeatLossPerHour"
                        ? "bg-[#eaf4ed]"
                        : ""
                    }`}
                  >
                    {calculateNormalizedHeatLossPerHour(section) === null ? (
                      <span
                        title="Для расчёта необходимы qh, β и длина участка"
                        className="text-sm font-medium text-[#8a9790]"
                      >
                        —
                      </span>
                    ) : (
                      <span className="text-sm font-bold text-[#704f20] tabular-nums">
                        {formatNumber(
                          calculateNormalizedHeatLossPerHour(section)!,
                        )}
                      </span>
                    )}
                  </td>
                  <td
                    className={`px-3 py-4 text-center text-sm font-medium text-[#2c3934] transition-colors ${
                      selectedColumn === "layingType" ? "bg-[#eaf4ed]" : ""
                    }`}
                  >
                    {displayText(section.laying_type)}
                  </td>
                  <td
                    className={`px-3 py-4 text-center text-sm text-[#5d6c65] transition-colors ${
                      selectedColumn === "undergroundLayingType"
                        ? "bg-[#eaf4ed]"
                        : ""
                    }`}
                  >
                    {displayText(section.underground_laying_type)}
                  </td>
                  <td
                    className={`px-3 py-4 text-center text-sm font-medium tabular-nums transition-colors ${
                      selectedColumn === "supplyTemperature"
                        ? "bg-[#eaf4ed]"
                        : ""
                    }`}
                  >
                    {formatNullableNumber(section.supply_temperature_c)}
                  </td>
                  <td
                    className={`px-3 py-4 text-center text-sm font-medium tabular-nums transition-colors ${
                      selectedColumn === "returnTemperature"
                        ? "bg-[#eaf4ed]"
                        : ""
                    }`}
                  >
                    {formatNullableNumber(section.return_temperature_c)}
                  </td>
                  <td
                    className={`px-3 py-4 text-center text-sm font-medium tabular-nums transition-colors ${
                      selectedColumn === "length" ? "bg-[#eaf4ed]" : ""
                    }`}
                  >
                    {formatNullableNumber(section.length_m)}
                  </td>
                  <td
                    className={`px-3 py-4 text-center text-sm text-[#526159] tabular-nums transition-colors ${
                      selectedColumn === "projectDate" ? "bg-[#eaf4ed]" : ""
                    }`}
                  >
                    {formatDate(section.project_date)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          </div>
        </>
      )}

     
    </section>
  );
}

function SectionsColumnWidths({
  showOuterDiameter,
}: {
  showOuterDiameter: boolean;
}) {
  return (
    <colgroup>
      <col className="w-[105px]" />
      {showOuterDiameter ? <col className="w-[145px]" /> : null}
      <col className="w-[115px]" />
      <col className="w-[115px]" />
      <col className="w-[140px]" />
      <col className="w-[145px]" />
      <col className="w-[185px]" />
      <col className="w-[155px]" />
      <col className="w-[155px]" />
      <col className="w-[95px]" />
      <col className="w-[130px]" />
    </colgroup>
  );
}

function SectionsHeaderRow({
  showOuterDiameter,
  selectedColumn,
  onSelect,
}: {
  showOuterDiameter: boolean;
  selectedColumn: SectionColumn | null;
  onSelect: (column: SectionColumn) => void;
}) {
  return (
    <tr className="bg-[#f6f8f6] text-sm font-semibold tracking-[-0.01em] text-[#17221f]">
      <SectionColumnHeader
        column="id"
        label="ID участка"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      {showOuterDiameter ? (
        <SectionColumnHeader
          column="supplyOuterDiameter"
          label="Наружный диаметр"
          unit="мм"
          selectedColumn={selectedColumn}
          onSelect={onSelect}
        />
      ) : null}
      <SectionColumnHeader
        column="qh"
        label="qh"
        unit="Вт/м"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <SectionColumnHeader
        column="beta"
        label="β"
        unit="коэффициент"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <SectionColumnHeader
        column="normalizedHeatLossPerHour"
        label="Q_норм/ч"
        unit="кДж/ч"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <SectionColumnHeader
        column="layingType"
        label="Тип прокладки"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <SectionColumnHeader
        column="undergroundLayingType"
        label="Подземная прокладка"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <SectionColumnHeader
        column="supplyTemperature"
        label="Температура подачи"
        unit="°C"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <SectionColumnHeader
        column="returnTemperature"
        label="Температура обратки"
        unit="°C"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <SectionColumnHeader
        column="length"
        label="Длина"
        unit="м"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
      <SectionColumnHeader
        column="projectDate"
        label="Дата проекта"
        selectedColumn={selectedColumn}
        onSelect={onSelect}
      />
    </tr>
  );
}

function SectionColumnHeader({
  column,
  label,
  unit,
  selectedColumn,
  onSelect,
}: {
  column: SectionColumn;
  label: string;
  unit?: string;
  selectedColumn: SectionColumn | null;
  onSelect: (column: SectionColumn) => void;
}) {
  const selected = selectedColumn === column;

  return (
    <th
      scope="col"
      className={`p-0 transition-colors ${
        selected ? "bg-[#dcece3] text-[#17221f]" : "hover:bg-[#edf3ef]"
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
        className="flex min-h-[58px] w-full cursor-pointer flex-col items-center justify-center px-2 py-2.5 text-center leading-tight transition-colors focus-visible:relative focus-visible:z-10 focus-visible:outline-2 focus-visible:outline-inset focus-visible:outline-[#2d7458]"
      >
        <span>{label}</span>
        {unit ? (
          <span
            className={`mt-0.5 block text-[11px] font-medium tracking-normal normal-case ${
              selected ? "text-[#365f4d]" : "text-[#536159]"
            }`}
          >
            {unit}
          </span>
        ) : null}
      </button>
    </th>
  );
}

function EmptySelection() {
  return (
    <section className="relative grid min-h-[500px] place-items-center overflow-hidden rounded-[22px] border border-[#dce4dd] bg-white p-8 text-center shadow-[0_16px_45px_rgba(30,55,45,0.055)]">
      <div className="pointer-events-none absolute inset-0 bg-[linear-gradient(rgba(49,99,78,0.035)_1px,transparent_1px),linear-gradient(90deg,rgba(49,99,78,0.035)_1px,transparent_1px)] bg-[size:32px_32px] [mask-image:linear-gradient(to_bottom,black,transparent_80%)]" />
      <div className="relative max-w-md">
        <div className="mx-auto grid size-16 place-items-center rounded-[20px] border border-[#dce7df] bg-[#edf4ef] text-[#39715b] shadow-[0_10px_30px_rgba(47,100,79,0.1)]">
          <NetworkIllustration />
        </div>
        <h2 className="mt-6 text-2xl font-semibold tracking-[-0.035em]">
          Выберите теплосеть
        </h2>
        <p className="mt-3 text-sm leading-6 text-[#718078]">
          Нажмите на название сети выше — здесь появится таблица со всеми её
          участками и значениями qh.
        </p>
      </div>
    </section>
  );
}

function TableLoading() {
  return (
    <section className="overflow-hidden rounded-[22px] border border-[#dce4dd] bg-white shadow-[0_16px_45px_rgba(30,55,45,0.055)]">
      <div className="animate-pulse border-b border-[#e2e8e3] px-6 py-6">
        <div className="h-3 w-28 rounded-full bg-[#e5ebe6]" />
        <div className="mt-3 h-7 w-48 rounded-lg bg-[#dfe7e1]" />
      </div>
      <div className="animate-pulse p-6">
        <div className="h-11 rounded-xl bg-[#eff3ef]" />
        {[0, 1, 2, 3, 4, 5].map((item) => (
          <div
            key={item}
            className="mt-2 grid grid-cols-6 gap-4 border-b border-[#edf0ed] py-4"
          >
            <div className="h-5 rounded bg-[#e8ede9]" />
            <div className="h-5 rounded bg-[#eef2ee]" />
            <div className="h-5 rounded bg-[#e8ede9]" />
            <div className="h-5 rounded bg-[#eef2ee]" />
            <div className="h-5 rounded bg-[#e8ede9]" />
            <div className="h-5 rounded bg-[#eef2ee]" />
          </div>
        ))}
      </div>
    </section>
  );
}

function NetworkListSkeleton() {
  return (
    <div className="flex animate-pulse flex-wrap gap-2 p-1">
      {[0, 1, 2, 3].map((item) => (
        <div
          key={item}
          className="flex min-w-56 items-center gap-3 rounded-2xl p-3"
        >
          <div className="size-9 rounded-xl bg-[#e7ede8]" />
          <div className="flex-1">
            <div className="h-4 w-3/4 rounded bg-[#e5ebe6]" />
            <div className="mt-2 h-2.5 w-12 rounded bg-[#eff2ef]" />
          </div>
        </div>
      ))}
    </div>
  );
}

function InlineError({
  message,
  onRetry,
}: {
  message: string;
  onRetry: () => void;
}) {
  return (
    <div className="px-3 py-6 text-center">
      <p className="text-sm leading-6 text-[#9a4c3b]">{message}</p>
      <button
        type="button"
        onClick={onRetry}
        className="mt-3 text-xs font-bold text-[#2e7258] underline decoration-[#9cbaac] underline-offset-4"
      >
        Повторить
      </button>
    </div>
  );
}

async function requestJSON<T>(url: string, signal?: AbortSignal): Promise<T> {
  const response = await fetch(url, {
    cache: "no-store",
    signal,
  });
  const body = (await response.json().catch(() => ({}))) as ErrorResponse & T;

  if (!response.ok) {
    throw new Error(body.error ?? `Ошибка запроса: ${response.status}`);
  }

  return body;
}

function displayText(value: string | null) {
  return value?.trim() || "—";
}

function formatNumber(value: number) {
  return numberFormatter.format(value);
}

function formatNullableNumber(value: number | null) {
  return value === null ? "—" : formatNumber(value);
}

function calculateNormalizedHeatLossPerHour(section: NetworkSection) {
  if (
    section.qh_value === null ||
    section.beta === null ||
    section.length_m === null
  ) {
    return null;
  }

  return 3.6 * section.qh_value * section.beta * section.length_m;
}

function calculateTotalNormalizedHeatLossPerHour(
  sections: NetworkSection[],
) {
  let total = 0;

  for (const section of sections) {
    const sectionValue = calculateNormalizedHeatLossPerHour(section);

    if (sectionValue === null) {
      return null;
    }

    total += sectionValue;
  }

  return total;
}

function formatDate(value: string | null) {
  if (!value) return "—";

  const date = new Date(`${value}T00:00:00`);
  return Number.isNaN(date.getTime()) ? value : dateFormatter.format(date);
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : "Неизвестная ошибка";
}

function isAbortError(error: unknown) {
  return error instanceof DOMException && error.name === "AbortError";
}

function NetworkMark() {
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 24 24"
      className="size-5"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M4 7h7v5h9" />
      <path d="M4 17h7v-5" />
      <circle cx="4" cy="7" r="1.7" />
      <circle cx="4" cy="17" r="1.7" />
      <circle cx="20" cy="12" r="1.7" />
    </svg>
  );
}

function NetworkIllustration() {
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 48 48"
      className="size-9"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M8 13h15v11h17" />
      <path d="M8 35h15V24" />
      <circle cx="8" cy="13" r="4" />
      <circle cx="8" cy="35" r="4" />
      <circle cx="40" cy="24" r="4" />
      <path d="M23 18v12" opacity=".45" />
    </svg>
  );
}

function ArrowIcon({ selected }: { selected: boolean }) {
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 20 20"
      className={`size-4 shrink-0 transition-transform ${
        selected ? "translate-x-0.5 text-white" : "text-[#9aa59f]"
      }`}
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="m7 4 6 6-6 6" />
    </svg>
  );
}

function ErrorIcon() {
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 24 24"
      className="size-5"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
    >
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v6M12 17h.01" />
    </svg>
  );
}
