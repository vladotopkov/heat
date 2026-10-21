import { proxyBackendRequest } from "../../../../_shared/backend";

const monthPattern = /^\d{4}-(0[1-9]|1[0-2])$/;

export async function PUT(
  request: Request,
  {
    params,
  }: {
    params: Promise<{ heatNetworkID: string; month: string }>;
  },
) {
  const { heatNetworkID, month } = await params;

  if (!/^\d+$/.test(heatNetworkID) || heatNetworkID === "0") {
    return Response.json(
      { error: "Некорректный идентификатор теплосети" },
      { status: 400 },
    );
  }
  if (!monthPattern.test(month)) {
    return Response.json(
      { error: "Месяц должен быть указан в формате ГГГГ-ММ" },
      { status: 400 },
    );
  }

  return proxyBackendRequest(
    `/api/v1/heat-networks/${heatNetworkID}/uptime/${month}`,
    {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: await request.text(),
    },
  );
}
