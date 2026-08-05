"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

export default function LogoutButton() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);

  async function logout() {
    setIsLoading(true);

    try {
      await fetch("/api/auth/logout", {
        method: "POST",
      });

      router.push("/login");
      router.refresh();
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <button
      type="button"
      onClick={logout}
      disabled={isLoading}
      className="rounded-lg bg-red-600 px-4 py-3 text-white disabled:opacity-50"
    >
      {isLoading ? "Выход..." : "Выйти"}
    </button>
  );
}