import { proxyBackendGet } from "../_shared/backend";

export async function GET() {
  return proxyBackendGet("/api/v1/heat-networks");
}
