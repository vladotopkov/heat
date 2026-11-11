import { proxyBackendGet } from "../../../_shared/backend";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ heatNetworkID: string }> },
) {
  const { heatNetworkID } = await params;

  if (!/^\d+$/.test(heatNetworkID) || heatNetworkID === "0") {
    return Response.json(
      { error: "Некорректный идентификатор теплосети" },
      { status: 400 },
    );
  }

  const month = new URL(request.url).searchParams.get("month");
  if (month !== null && !/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) {
    return Response.json(
      { error: "Месяц должен быть указан в формате ГГГГ-ММ" },
      { status: 400 },
    );
  }

  const query = month === null ? "" : `?month=${encodeURIComponent(month)}`;
  return proxyBackendGet(
    `/api/v1/heat-networks/${heatNetworkID}/sections${query}`,
  );
}
