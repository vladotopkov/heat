import { proxyBackendGet } from "../_shared/backend";

const monthPattern = /^\d{4}-(0[1-9]|1[0-2])$/;

export async function GET(request: Request) {
  const month = new URL(request.url).searchParams.get("month") ?? "";

  if (!monthPattern.test(month)) {
    return Response.json(
      { error: "Месяц должен быть указан в формате ГГГГ-ММ" },
      { status: 400 },
    );
  }

  return proxyBackendGet(`/api/v1/losses?month=${encodeURIComponent(month)}`);
}
