"use client";

import { type MouseEvent, useRef } from "react";

type MonthPickerProps = {
  label: string;
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean;
  variant?: "card" | "compact";
  className?: string;
};

export function MonthPicker({
  label,
  value,
  onChange,
  disabled = false,
  variant = "card",
  className = "",
}: MonthPickerProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const isCard = variant === "card";

  function openPicker(event: MouseEvent<HTMLLabelElement>) {
    if (disabled) return;

    const input = inputRef.current;
    if (!input || typeof input.showPicker !== "function") return;

    event.preventDefault();

    try {
      input.showPicker();
    } catch {
      // Keep the native input behavior if the browser declines to open its picker.
    }
  }

  return (
    <label
      onClick={openPicker}
      className={`${
        isCard
          ? "group w-full rounded-2xl border border-[#d8e2da] bg-white px-4 py-3 shadow-sm transition-colors sm:w-60"
          : "group block sm:w-56"
      } ${
        disabled
          ? "cursor-not-allowed"
          : isCard
            ? "cursor-pointer hover:bg-[#f7faf7]"
            : "cursor-pointer"
      } ${className}`}
    >
      <span
        className={
          isCard
            ? "block text-[11px] font-bold tracking-[0.08em] text-[#64746c] uppercase"
            : "mb-2 block text-xs font-semibold text-[#66766e]"
        }
      >
        {label}
      </span>
      <input
        ref={inputRef}
        type="month"
        value={value}
        disabled={disabled}
        onChange={(event) => onChange(event.target.value)}
        className={
          isCard
            ? "mt-1.5 w-full cursor-pointer bg-transparent text-base font-semibold text-[#1d2b26] outline-none disabled:cursor-not-allowed disabled:opacity-60"
            : "h-11 w-full cursor-pointer rounded-xl border border-[#cfd9d1] bg-white px-3 text-sm font-semibold text-[#24322d] outline-none transition-colors group-hover:bg-[#f7faf7] focus:border-[#39715b] focus:ring-2 focus:ring-[#39715b]/15 disabled:cursor-not-allowed disabled:opacity-60"
        }
      />
    </label>
  );
}
