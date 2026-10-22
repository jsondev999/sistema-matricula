import React from "react";
import { useAuth } from "../context/AuthContext";
import { GraduationCap, LogOut, User, Clock, Award } from "lucide-react";
import CountdownTimer from "./CountdownTimer";

export default function Navbar({ onTimeout }) {
  const { user, logout, view } = useAuth();

  if (!user) return null;

  const getCondicionBadge = (condicion) => {
    switch (condicion) {
      case "DESTACADO":
        return <span style={{ background: "#fef3c7", color: "#b45309", padding: "3px 10px", borderRadius: "12px", fontSize: "12px", fontWeight: "700" }}>⭐ DESTACADO</span>;
      case "ESPECIAL":
        return <span style={{ background: "#fee2e2", color: "#b91c1c", padding: "3px 10px", borderRadius: "12px", fontSize: "12px", fontWeight: "700" }}>⚠️ ESPECIAL</span>;
      default:
        return <span style={{ background: "#e0f2fe", color: "#0369a1", padding: "3px 10px", borderRadius: "12px", fontSize: "12px", fontWeight: "700" }}>✓ REGULAR</span>;
    }
  };

  return (
    <header style={{
      background: "linear-gradient(90deg, #0f172a 0%, #1e3a8a 100%)",
      color: "#ffffff",
      padding: "12px 24px",
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      boxShadow: "0 4px 12px rgba(0,0,0,0.15)",
      position: "sticky",
      top: 0,
      zIndex: 100
    }}>
      {/* Brand */}
      <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
        <div style={{ background: "rgba(255,255,255,0.15)", padding: "8px", borderRadius: "8px", display: "flex" }}>
          <GraduationCap size={26} color="#60a5fa" />
        </div>
        <div>
          <div style={{ fontWeight: "800", fontSize: "16px", letterSpacing: "0.5px" }}>UNJBG - MATRÍCULA WEB</div>
          <div style={{ fontSize: "11px", color: "#93c5fd" }}>ESIS • SEMESTRE ACADÉMICO 2026-II</div>
        </div>
      </div>

      {/* Temporizador en modo matrícula */}
      {view === "matricula" && (
        <CountdownTimer onTimeout={onTimeout} />
      )}

      {/* User Info & Logout */}
      <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
        <div style={{ textAlign: "right", display: "flex", flexDirection: "column", gap: "2px" }}>
          <div style={{ fontSize: "14px", fontWeight: "600", display: "flex", alignItems: "center", gap: "6px", justifyContent: "flex-end" }}>
            <User size={15} color="#93c5fd" />
            {user.nombres} {user.apellidos}
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "8px", justifyContent: "flex-end" }}>
            <span style={{ fontSize: "12px", color: "#cbd5e1" }}>Cód: {user.codigo}</span>
            {getCondicionBadge(user.condicion_academica)}
          </div>
        </div>

        <button
          onClick={logout}
          title="Cerrar Sesión"
          style={{
            background: "rgba(239, 68, 68, 0.2)",
            border: "1px solid rgba(239, 68, 68, 0.4)",
            color: "#fca5a5",
            padding: "8px 12px",
            borderRadius: "8px",
            display: "flex",
            alignItems: "center",
            gap: "6px",
            cursor: "pointer",
            fontSize: "13px",
            fontWeight: "600",
            transition: "all 0.2s ease"
          }}
          onMouseOver={(e) => { e.currentTarget.style.background = "#ef4444"; e.currentTarget.style.color = "#ffffff"; }}
          onMouseOut={(e) => { e.currentTarget.style.background = "rgba(239, 68, 68, 0.2)"; e.currentTarget.style.color = "#fca5a5"; }}
        >
          <LogOut size={16} />
          <span>Salir</span>
        </button>
      </div>
    </header>
  );
}
