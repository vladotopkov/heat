"use client";

import Link from "next/link";
import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    setError("");
    setIsLoading(true);

    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          email,
          password,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error ?? "Не удалось войти");
      }

      router.push("/dashboard");
      router.refresh();
    } catch (error) {
      setError(
        error instanceof Error
          ? error.message
          : "Произошла неизвестная ошибка",
      );
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <main className="mx-auto max-w-md px-6 py-20">
      <h1 className="text-3xl font-bold">Вход</h1>

      <form
        onSubmit={handleSubmit}
        className="mt-8 flex flex-col gap-5"
      >
        <label className="flex flex-col gap-2">
          <span>Email</span>

          <input
            required
            type="email"
            autoComplete="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className="rounded-lg border px-4 py-3 text-black"
          />
        </label>

        <label className="flex flex-col gap-2">
          <span>Пароль</span>

          <input
            required
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className="rounded-lg border px-4 py-3 text-black"
          />
        </label>

        {error && (
          <p className="rounded-lg bg-red-100 p-3 text-red-700">
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={isLoading}
          className="rounded-lg bg-black px-4 py-3 text-white disabled:opacity-50"
        >
          {isLoading ? "Вход..." : "Войти"}
        </button>
      </form>

      <p className="mt-6">
        Нет аккаунта?{" "}
        <Link href="/register" className="underline">
          Зарегистрироваться
        </Link>
      </p>
    </main>
  );
}