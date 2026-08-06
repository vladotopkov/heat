"use client";

import type { ReactNode } from "react";
import { useEffect, useId, useRef, useState } from "react";

interface FieldHelpProps {
  children: ReactNode;
  ariaLabel?: string;
}

export function FieldHelp({
  children,
  ariaLabel = "Показать подсказку",
}: FieldHelpProps) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const tooltipId = useId();

  useEffect(() => {
    if (!isOpen) return;

    function handlePointerDown(event: PointerEvent) {
      if (!containerRef.current?.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setIsOpen(false);
      }
    }

    document.addEventListener("pointerdown", handlePointerDown);
    document.addEventListener("keydown", handleKeyDown);

    return () => {
      document.removeEventListener("pointerdown", handlePointerDown);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [isOpen]);

  return (
    <div ref={containerRef} className="relative inline-flex">
      <button
        type="button"
        aria-label={ariaLabel}
        aria-expanded={isOpen}
        aria-controls={tooltipId}
        onClick={() => setIsOpen((current) => !current)}
        className="flex size-4 items-center justify-center rounded-full border border-slate-400 text-[11px] font-semibold leading-none text-slate-500 transition hover:border-sky-600 hover:bg-sky-50 hover:text-sky-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-600"
      >
        <span aria-hidden="true">?</span>
      </button>

      {isOpen && (
        <div
          id={tooltipId}
          role="tooltip"
          className="absolute bottom-0 left-full z-20 ml-2 w-72 rounded-xl border border-slate-200 bg-white p-4 pr-10 text-sm leading-5 font-normal text-slate-700 shadow-lg"
        >
          {children}

          <button
            type="button"
            aria-label="Закрыть подсказку"
            onClick={() => setIsOpen(false)}
            className="absolute top-2.5 right-2.5 flex size-6 items-center justify-center rounded-md text-lg leading-none text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-sky-600"
          >
            <span aria-hidden="true">×</span>
          </button>
        </div>
      )}
    </div>
  );
}
