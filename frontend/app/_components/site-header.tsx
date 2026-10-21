"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

const menuItems = [
  { href: "/", label: "Потери" },
  { href: "/temperatures", label: "Температуры" },
  { href: "/uptime", label: "Часы работы" },
  { href: "/netw-sects", label: "Участки теплосетей" },
] as const;

export function SiteHeader() {
  const pathname = usePathname();
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    if (!isOpen) return;

    function closeOnEscape(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setIsOpen(false);
      }
    }

    document.addEventListener("keydown", closeOnEscape);
    return () => document.removeEventListener("keydown", closeOnEscape);
  }, [isOpen]);

  return (
    <header className="relative z-50 border-b border-[#dbe3dc] bg-[#f8faf7]/90 backdrop-blur-xl">
      <div className="flex min-h-18 items-center justify-center px-4 py-3">
        <button
          type="button"
          aria-expanded={isOpen}
          aria-controls="site-navigation"
          onClick={() => setIsOpen((current) => !current)}
          className="inline-flex min-w-32 items-center justify-center gap-2.5 rounded-xl border border-[#cfdad2] bg-white px-5 py-2.5 text-sm font-bold text-[#234f3e] shadow-sm transition hover:border-[#aebfb3] hover:bg-[#f7faf7] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#2d7458]"
        >
          <span className="relative block size-4" aria-hidden="true">
            <span
              className={`absolute left-0 top-[3px] h-0.5 w-4 rounded-full bg-current transition duration-200 ${
                isOpen ? "translate-y-[5px] rotate-45" : ""
              }`}
            />
            <span
              className={`absolute left-0 top-[8px] h-0.5 w-4 rounded-full bg-current transition duration-200 ${
                isOpen ? "opacity-0" : "opacity-100"
              }`}
            />
            <span
              className={`absolute left-0 top-[13px] h-0.5 w-4 rounded-full bg-current transition duration-200 ${
                isOpen ? "-translate-y-[5px] -rotate-45" : ""
              }`}
            />
          </span>
          Меню
        </button>
      </div>

      <div
        id="site-navigation"
        className={`absolute inset-x-0 top-full overflow-hidden border-t border-white/10 bg-[#225e49] text-white shadow-[0_22px_40px_rgba(22,55,42,0.25)] transition-[max-height,opacity,visibility] duration-300 ease-out ${
          isOpen
            ? "visible max-h-96 opacity-100"
            : "invisible max-h-0 opacity-0"
        }`}
      >
        <nav
          aria-label="Основная навигация"
          className="mx-auto grid w-[calc(100%-2rem)] gap-2 py-5 sm:w-[90%] sm:grid-cols-2 lg:grid-cols-4 xl:w-[85%]"
        >
          {menuItems.map((item) => {
            const isCurrent = pathname === item.href;

            return (
              <Link
                key={item.href}
                href={item.href}
                aria-current={isCurrent ? "page" : undefined}
                onClick={() => setIsOpen(false)}
                className={`rounded-xl px-4 py-3.5 text-center text-sm font-bold transition focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white ${
                  isCurrent
                    ? "bg-white text-[#225e49] shadow-sm"
                    : "bg-white/10 text-white hover:bg-white/20"
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>
      </div>
    </header>
  );
}
