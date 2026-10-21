import { proxyBackendGet } from "../../../_shared/backend";

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ heatNetworkID: string }> },
) {
  const { heatNetworkID } = await params;

  if (!/^\d+$/.test(heatNetworkID) || heatNetworkID === "0") {
    return Response.json(
      { error: "Некорректный идентификатор теплосети" },
      { status: 400 },
    );
  }

  return proxyBackendGet(
    `/api/v1/heat-networks/${heatNetworkID}/sections`,
  );
}
