interface ListResponse<T> {
  items: T[];
}

function getBackendURL(): string {
  const backendURL = process.env.BACKEND_INTERNAL_URL;

  if (!backendURL) {
    throw new Error(
      "BACKEND_INTERNAL_URL environment variable is required",
    );
  }

  return backendURL;
}

export async function getList<T>(path: string): Promise<T[]> {
  const backendURL = getBackendURL();
  const url = new URL(path, backendURL);

  const response = await fetch(url, {
    cache: "no-store",
    headers: {
      Accept: "application/json",
    },
  });

  if (!response.ok) {
    throw new Error(
      `Backend request failed: GET ${path}, status ${response.status}`,
    );
  }

  const data = (await response.json()) as ListResponse<T>;

  if (!Array.isArray(data.items)) {
    throw new Error(
      `Backend returned invalid list response for ${path}`,
    );
  }

  return data.items;
}