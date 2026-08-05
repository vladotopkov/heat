import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import LogoutButton from "./LogoutButton";


type User = {
  id: number;
  name: string;
  email: string;
  createdAt: string;
};

async function getCurrentUser(): Promise<User | null> {
  const backendUrl = process.env.BACKEND_URL;
  const cookieStore = await cookies();
  const token = cookieStore.get("auth_token")?.value;

  if (!backendUrl || !token) {
    return null;
  }

  try {
    const response = await fetch(`${backendUrl}/auth/me`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
      cache: "no-store",
    });

    if (!response.ok) {
      return null;
    }

    return response.json();
  } catch {
    return null;
  }
}

export default async function DashboardPage() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/login");
  }

  return (
    <main className="mx-auto max-w-2xl px-6 py-20">
      <h1 className="text-3xl font-bold">
        Личный кабинет
      </h1>

      <div className="mt-8 rounded-xl border p-6">
        <p>
          <strong>ID:</strong> {user.id}
        </p>

        <p className="mt-2">
          <strong>Имя:</strong> {user.name}
        </p>

        <p className="mt-2">
          <strong>Email:</strong> {user.email}
        </p>

        <p className="mt-2">
          <strong>Дата регистрации:</strong>{" "}
          {new Date(user.createdAt).toLocaleString("ru-RU")}
        </p>
      </div>

      <div className="mt-8">
        <LogoutButton />
      </div>
    </main>
  );
}