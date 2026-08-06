function getBackendURL(): string {
  const backendURL =
    process.env.BACKEND_INTERNAL_URL;

  if (!backendURL) {
    throw new Error(
      "BACKEND_INTERNAL_URL is not configured",
    );
  }

  return backendURL;
}

export async function POST(
  request: Request,
): Promise<Response> {
  let requestBody: unknown;

  try {
    requestBody = await request.json();
  } catch {
    return Response.json(
      {
        error: {
          code: "invalid_json",
          message: "Некорректное тело запроса",
        },
      },
      {
        status: 400,
      },
    );
  }

  try {
    const backendResponse = await fetch(
      new URL(
        "/api/v1/calculations",
        getBackendURL(),
      ),
      {
        method: "POST",

        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },

        body: JSON.stringify(requestBody),

        cache: "no-store",
      },
    );

    const responseBody =
      await backendResponse.text();

    return new Response(responseBody, {
      status: backendResponse.status,

      headers: {
        "Content-Type":
          backendResponse.headers.get(
            "Content-Type",
          ) ??
          "application/json; charset=utf-8",
      },
    });
  } catch (error) {
    console.error(
      "Failed to send calculation request to backend",
      error,
    );

    return Response.json(
      {
        error: {
          code: "backend_unavailable",
          message:
            "Сервер расчётов временно недоступен",
        },
      },
      {
        status: 502,
      },
    );
  }
}