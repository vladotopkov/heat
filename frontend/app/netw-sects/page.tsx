import type { Metadata } from "next";

import { TablesWorkspace } from "./tables-workspace";
import { ReactJsxRuntime } from "next/dist/server/route-modules/app-page/vendored/rsc/entrypoints";
import { runInContext } from "vm";
import { join } from "path";
import { Jacquard_12, Jacquard_24, Jockey_One } from "next/font/google";

export const metadata: Metadata = {
  title: "Участки теплосетей",
  description:
    "Реестр теплосетей и нормативных значений qh по участкам",
};

export default function TablesPage() {
  return <TablesWorkspace />;
}
