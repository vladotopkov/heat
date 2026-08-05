"use client";

import { FormEvent, useState } from "react";

type CalculateResponse = {
  result: number;
};

export default function Home() {
  const [a, setA] = useState("10");
  const [b, setB] = useState("5");
  const [result, setResult] = useState<number | null>(null);
  const [error, setError] = useState("");

  async function calculate(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");

    try {
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_BACKEND_URL}/calculate`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            a: Number(a),
            b: Number(b),
          }),
        },
      );

      if (!response.ok) {
        throw new Error(await response.text());
      }

      const data: CalculateResponse = await response.json();
      setResult(data.result);
    } catch (error) {
      setError(
        error instanceof Error
          ? error.message
          : "Не удалось обратиться к Go backend",
      );
    }
  }

  return (
    <main style={{ maxWidth: 500, margin: "80px auto" }}>
      <h1>Next.js + Go + Docker</h1>

      <form onSubmit={calculate}>
        <input
          type="number"
          value={a}
          onChange={(event) => setA(event.target.value)}
        />

        <input
          type="number"
          value={b}
          onChange={(event) => setB(event.target.value)}
        />

        <button type="submit">Посчитать</button>
      </form>

      {result !== null && <p>Результат: {result}</p>}
      {error && <p>Ошибка: {error}</p>}
    </main>
  );
}