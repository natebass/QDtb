import React from "react";

export interface fProps {
  children: React.ReactNode;
}
export default function f({ children }: fProps) {
  return <div className="">{children}</div>;
}
