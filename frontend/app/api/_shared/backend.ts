const BACKEND_URL =
  process.env.BACKEND_INTERNAL_URL ?? "http://localhost:8080";

export async function proxyBackendRequest(
  path: string,
  init: RequestInit = {},
) {
  try {
    const headers = new Headers(init.headers);
    headers.set("Accept", "application/json");

    const response = await fetch(`${BACKEND_URL}${path}`, {
      ...init,
      headers,
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
      { error: "Сервер временно недоступен" },
      { status: 502 },
    );
  }
}

export function proxyBackendGet(path: string) {
  return proxyBackendRequest(path, { method: "GET" });
}
