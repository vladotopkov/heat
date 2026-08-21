const BACKEND_URL = process.env.BACKEND_INTERNAL_URL ?? "http://localhost:8080";

export async function POST(
  request: Request,
  { params }: { params: Promise<{ sessionID: string }> },
) {
  const { sessionID } = await params;

  if (!/^\d+$/.test(sessionID) || sessionID === "0") {
    return Response.json(
      { error: "Некорректный идентификатор сессии" },
      { status: 400 },
    );
  }

  try {
    const body = await request.text();
    const response = await fetch(
      `${BACKEND_URL}/api/v1/qh/sessions/${sessionID}/answers`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body,
        cache: "no-store",
      },
    );
    const responseBody = await response.text();

    return new Response(responseBody, {
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
