import type { Metadata } from "next";

import { TablesWorkspace } from "./tables-workspace";

export const metadata: Metadata = {
  title: "Участки теплосетей",
  description:
    "Реестр теплосетей и нормативных значений qh по участкам",
};

export default function TablesPage() {
  return <TablesWorkspace />;
}
