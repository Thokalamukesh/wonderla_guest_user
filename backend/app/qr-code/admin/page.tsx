"use client";
import React, { useEffect, useState } from "react";
import LoginForm from "./_components/LoginForm";
import Dashboard from "./_components/Dashboard";

type Role = "superadmin" | "park";
interface SessionUser {
  username: string;
  role: Role;
  parkSlug?: string;
}

/** Admin entry: resolve the session, then show login or the dashboard. */
const AdminPage = () => {
  const [user, setUser] = useState<SessionUser | null | undefined>(undefined);

  const check = async () => {
    try {
      const res = await fetch("/qr-code/api/auth/session", { cache: "no-store" });
      const json = await res.json();
      setUser(json.authenticated && json.user ? json.user : null);
    } catch {
      setUser(null);
    }
  };

  useEffect(() => {
    check();
  }, []);

  if (user === undefined) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-100">
        <p className="text-sm text-slate-500">Loading…</p>
      </div>
    );
  }

  return user ? (
    <Dashboard user={user} onLogout={() => setUser(null)} />
  ) : (
    <LoginForm onSuccess={setUser} />
  );
};

export default AdminPage;
