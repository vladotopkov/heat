"use client";

import Link from "next/link";
import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

export default function RegisterPage() {
  const router = useRouter();

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    setError("");
    setIsLoading(true);

    try {
      const response = await fetch("/api/auth/register", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          name,
          email,
          password,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error ?? "Не удалось зарегистрироваться");
      }

      router.push("/login");
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
      <h1 className="text-3xl font-bold">Регистрация</h1>

      <form
        onSubmit={handleSubmit}
        className="mt-8 flex flex-col gap-5"
      >
        <label className="flex flex-col gap-2">
          <span>Имя</span>

          <input
            required
            type="text"
            value={name}
            onChange={(event) => setName(event.target.value)}
            className="rounded-lg border px-4 py-3 text-black"
          />
        </label>

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
            minLength={8}
            type="password"
            autoComplete="new-password"
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
          {isLoading ? "Регистрация..." : "Зарегистрироваться"}
        </button>
      </form>

      <p className="mt-6">
        Уже есть аккаунт?{" "}
        <Link href="/login" className="underline">
          Войти
        </Link>
      </p>
    </main>
  );
}