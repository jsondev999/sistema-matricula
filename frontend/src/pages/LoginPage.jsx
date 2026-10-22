import React, { useState } from "react";
import { useAuth } from "../context/AuthContext";
import { api } from "../services/api";
import { GraduationCap, Lock, User, AlertCircle, ArrowRight, KeyRound, CheckCircle2 } from "lucide-react";

export default function LoginPage() {
  const { login } = useAuth();
  const [codigo, setCodigo] = useState("2023-119010"); // Alumno regular por defecto
  const [password, setPassword] = useState("123456");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [modalRecuperar, setModalRecuperar] = useState(false);
  const [recupCodigo, setRecupCodigo] = useState("");
  const [recupCorreo, setRecupCorreo] = useState("");
  const [recupMensaje, setRecupMensaje] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      await login(codigo, password);
    } catch (err) {
      setError(err.message || "Error al iniciar sesión.");
    } finally {
      setLoading(false);
    }
  };

  const handleRecuperar = async (e) => {
    e.preventDefault();
    try {
      const res = await api.recuperar(recupCodigo, recupCorreo);
      setRecupMensaje(res.mensaje);
    } catch (err) {
      setRecupMensaje(err.message);
    }
  };

  const seleccionarCuentaPrueba = (cod, pass = "123456") => {
    setCodigo(cod);
    setPassword(pass);
    setError("");
  };

  return (
    <div style={{
      minHeight: "100vh",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      background: "radial-gradient(circle at top left, #1e3a8a 0%, #0f172a 100%)",
      padding: "20px"
    }}>
      <div style={{
        width: "100%",
        maxWidth: "460px",
        background: "#ffffff",
        borderRadius: "16px",
        boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.35)",
        overflow: "hidden"
      }} className="fade-in">
        
        {/* Cabecera institucional */}
        <div style={{
          background: "linear-gradient(135deg, #1e3a8a 0%, #1e40af 100%)",
          color: "#ffffff",
          padding: "36px 30px 28px",
          textAlign: "center"
        }}>
          <div style={{
            display: "inline-flex",
            background: "rgba(255, 255, 255, 0.15)",
            padding: "12px",
            borderRadius: "16px",
            marginBottom: "14px"
          }}>
            <GraduationCap size={40} color="#93c5fd" />
          </div>
          <h2 style={{ fontSize: "20px", color: "#ffffff", margin: 0, letterSpacing: "0.5px" }}>
            UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN
          </h2>
          <p style={{ margin: "6px 0 0", color: "#bfdbfe", fontSize: "13px" }}>
            Sistema Web de Matrícula • Semestre 2026-II
          </p>
        </div>

        {/* Formulario */}
        <div style={{ padding: "30px" }}>
          {error && (
            <div style={{
              background: "#fee2e2",
              borderLeft: "4px solid #ef4444",
              color: "#991b1b",
              padding: "12px 14px",
              borderRadius: "6px",
              marginBottom: "20px",
              fontSize: "13px",
              display: "flex",
              alignItems: "flex-start",
              gap: "8px"
            }}>
              <AlertCircle size={18} color="#ef4444" style={{ flexShrink: 0, marginTop: "2px" }} />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div style={{ marginBottom: "18px" }}>
              <label style={{ display: "block", fontSize: "13px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                Código Universitario
              </label>
              <div style={{ position: "relative" }}>
                <User size={18} color="#94a3b8" style={{ position: "absolute", left: "12px", top: "12px" }} />
                <input
                  type="text"
                  required
                  placeholder="Ej: 2023-119010"
                  value={codigo}
                  onChange={(e) => setCodigo(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "10px 14px 10px 38px",
                    borderRadius: "8px",
                    border: "1px solid #cbd5e1",
                    fontSize: "14px",
                    outline: "none",
                    fontFamily: "inherit"
                  }}
                  onFocus={(e) => e.target.style.borderColor = "#2563eb"}
                  onBlur={(e) => e.target.style.borderColor = "#cbd5e1"}
                />
              </div>
            </div>

            <div style={{ marginBottom: "22px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "6px" }}>
                <label style={{ fontSize: "13px", fontWeight: "600", color: "#334155" }}>
                  Contraseña Institucional
                </label>
                <button
                  type="button"
                  onClick={() => { setModalRecuperar(true); setRecupMensaje(""); }}
                  style={{
                    background: "none",
                    border: "none",
                    color: "#2563eb",
                    fontSize: "12px",
                    cursor: "pointer",
                    fontWeight: "500"
                  }}
                >
                  ¿Olvidó su contraseña?
                </button>
              </div>
              <div style={{ position: "relative" }}>
                <Lock size={18} color="#94a3b8" style={{ position: "absolute", left: "12px", top: "12px" }} />
                <input
                  type="password"
                  required
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "10px 14px 10px 38px",
                    borderRadius: "8px",
                    border: "1px solid #cbd5e1",
                    fontSize: "14px",
                    outline: "none",
                    fontFamily: "inherit"
                  }}
                  onFocus={(e) => e.target.style.borderColor = "#2563eb"}
                  onBlur={(e) => e.target.style.borderColor = "#cbd5e1"}
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              style={{
                width: "100%",
                background: "linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%)",
                color: "#ffffff",
                padding: "12px",
                border: "none",
                borderRadius: "8px",
                fontSize: "15px",
                fontWeight: "700",
                cursor: loading ? "not-allowed" : "pointer",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: "8px",
                boxShadow: "0 4px 12px rgba(37,99,235,0.3)"
              }}
            >
              {loading ? "Validando credenciales..." : "Ingresar a Matrícula"}
              {!loading && <ArrowRight size={18} />}
            </button>
          </form>

          {/* Selector Rápido de Cuentas para la Exposición */}
          <div style={{ marginTop: "24px", paddingTop: "18px", borderTop: "1px solid #e2e8f0" }}>
            <span style={{ fontSize: "11px", fontWeight: "700", color: "#64748b", textTransform: "uppercase", letterSpacing: "0.5px", display: "block", marginBottom: "8px" }}>
              Cuentas de Prueba para Demostración:
            </span>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: "6px" }}>
              <button
                type="button"
                onClick={() => seleccionarCuentaPrueba("2023-119010")}
                style={{ background: "#f1f5f9", border: "1px solid #cbd5e1", borderRadius: "6px", padding: "6px 8px", fontSize: "11px", textAlign: "left", cursor: "pointer" }}
              >
                👤 <strong>2023-119010</strong><br/><span style={{ color: "#0369a1" }}>Regular (23 cr.)</span>
              </button>
              <button
                type="button"
                onClick={() => seleccionarCuentaPrueba("2022-119005")}
                style={{ background: "#fef3c7", border: "1px solid #fde68a", borderRadius: "6px", padding: "6px 8px", fontSize: "11px", textAlign: "left", cursor: "pointer" }}
              >
                ⭐ <strong>2022-119005</strong><br/><span style={{ color: "#b45309" }}>Destacado (28 cr.)</span>
              </button>
              <button
                type="button"
                onClick={() => seleccionarCuentaPrueba("2026-119001")}
                style={{ background: "#fee2e2", border: "1px solid #fecaca", borderRadius: "6px", padding: "6px 8px", fontSize: "11px", textAlign: "left", cursor: "pointer" }}
              >
                📄 <strong>2026-119001</strong><br/><span style={{ color: "#b91c1c" }}>Ingresante (Sin docs)</span>
              </button>
              <button
                type="button"
                onClick={() => seleccionarCuentaPrueba("2026-119002")}
                style={{ background: "#ecfdf5", border: "1px solid #a7f3d0", borderRadius: "6px", padding: "6px 8px", fontSize: "11px", textAlign: "left", cursor: "pointer" }}
              >
                ✅ <strong>2026-119002</strong><br/><span style={{ color: "#047857" }}>Ingresante (Con docs)</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Modal de Recuperación de Contraseña */}
      {modalRecuperar && (
        <div style={{
          position: "fixed",
          top: 0, left: 0, right: 0, bottom: 0,
          background: "rgba(15, 23, 42, 0.75)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          padding: "20px",
          zIndex: 1000
        }}>
          <div style={{
            background: "#ffffff",
            padding: "26px",
            borderRadius: "14px",
            maxWidth: "400px",
            width: "100%",
            boxShadow: "0 20px 25px -5px rgba(0,0,0,0.3)"
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "14px" }}>
              <KeyRound size={22} color="#2563eb" />
              <h3 style={{ margin: 0, fontSize: "17px", color: "#1e3a8a" }}>Restablecer Contraseña</h3>
            </div>
            
            {recupMensaje ? (
              <div style={{ background: "#ecfdf5", color: "#065f46", padding: "14px", borderRadius: "8px", fontSize: "13px", display: "flex", gap: "8px" }}>
                <CheckCircle2 size={18} color="#10b981" />
                <span>{recupMensaje}</span>
              </div>
            ) : (
              <form onSubmit={handleRecuperar}>
                <div style={{ marginBottom: "12px" }}>
                  <label style={{ fontSize: "12px", fontWeight: "600", color: "#475569" }}>Código Universitario</label>
                  <input
                    type="text"
                    required
                    value={recupCodigo}
                    onChange={(e) => setRecupCodigo(e.target.value)}
                    placeholder="Ej: 2023-119010"
                    style={{ width: "100%", padding: "8px 10px", borderRadius: "6px", border: "1px solid #cbd5e1", marginTop: "4px" }}
                  />
                </div>
                <div style={{ marginBottom: "18px" }}>
                  <label style={{ fontSize: "12px", fontWeight: "600", color: "#475569" }}>Correo Institucional</label>
                  <input
                    type="email"
                    required
                    value={recupCorreo}
                    onChange={(e) => setRecupCorreo(e.target.value)}
                    placeholder="usuario@unjbg.edu.pe"
                    style={{ width: "100%", padding: "8px 10px", borderRadius: "6px", border: "1px solid #cbd5e1", marginTop: "4px" }}
                  />
                </div>
                <div style={{ display: "flex", justifyContent: "flex-end", gap: "10px" }}>
                  <button
                    type="button"
                    onClick={() => setModalRecuperar(false)}
                    style={{ background: "#f1f5f9", border: "1px solid #cbd5e1", padding: "8px 16px", borderRadius: "6px", cursor: "pointer", fontSize: "13px" }}
                  >
                    Cerrar
                  </button>
                  <button
                    type="submit"
                    style={{ background: "#2563eb", color: "#ffffff", border: "none", padding: "8px 16px", borderRadius: "6px", cursor: "pointer", fontSize: "13px", fontWeight: "600" }}
                  >
                    Enviar Enlace
                  </button>
                </div>
              </form>
            )}
            {recupMensaje && (
              <button
                onClick={() => setModalRecuperar(false)}
                style={{ width: "100%", marginTop: "14px", background: "#1e3a8a", color: "#ffffff", border: "none", padding: "8px", borderRadius: "6px", cursor: "pointer" }}
              >
                Volver al Login
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
