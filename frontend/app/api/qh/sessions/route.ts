const BACKEND_URL = process.env.BACKEND_INTERNAL_URL ?? "http://localhost:8080";

export async function POST() {
  try {
    const response = await fetch(`${BACKEND_URL}/api/v1/qh/sessions`, {
      method: "POST",
      cache: "no-store",
    });
    const body = await response.text();

    return new Response(body, {
      status: response.status,
      headers: {
        "Content-Type":
          response.headers.get("Content-Type") ?? "application/json",
      },
    });
  } catch {
    return Response.json(
      { error: "Сервис расчёта временно недоступен" },
      { status: 502 },
    );
  }
}
