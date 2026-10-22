import React, { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { api } from "../services/api";
import Navbar from "../components/Navbar";
import { Users, Clock, ArrowRight, ShieldCheck, RefreshCw, AlertCircle, Sparkles } from "lucide-react";

export default function ColaVirtualPage() {
  const { setView } = useAuth();
  const [posicion, setPosicion] = useState(null);
  const [esperaEstimada, setEsperaEstimada] = useState("Calculando...");
  const [turnoActivo, setTurnoActivo] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [pollingCount, setPollingCount] = useState(0);

  // 1. Inscribir en cola al montar
  useEffect(() => {
    const registrarEnCola = async () => {
      try {
        setLoading(true);
        const res = await api.ingresarCola();
        setPosicion(res.posicion);
        if (res.turno_activo) {
          setTurnoActivo(true);
        }
      } catch (err) {
        setError(err.message || "Error al acceder a la sala de espera.");
      } finally {
        setLoading(false);
      }
    };

    registrarEnCola();
  }, []);

  // 2. Polling periódico cada 5 segundos
  useEffect(() => {
    if (turnoActivo) return; // Si ya tiene turno activo, detener sondeo

    const intervalo = setInterval(async () => {
      try {
        const res = await api.getPosicionCola();
        setPosicion(res.posicion);
        setEsperaEstimada(res.espera_estimada);
        setPollingCount((prev) => prev + 1);

        if (res.turno_activo) {
          setError("");
          setTurnoActivo(true);
        }
      } catch (err) {
        if (err.data?.redirect === "/portafolio") {
          setView("portafolio");
        } else {
          setError(err.message);
        }
      }
    }, 5000);

    return () => clearInterval(intervalo);
  }, [turnoActivo, setView]);

  return (
    <div style={{ minHeight: "100vh", background: "#f8fafc" }}>
      <Navbar />

      <main style={{ maxWidth: "680px", margin: "40px auto", padding: "0 20px" }} className="fade-in">
        {error && (
          <div style={{ background: "#fee2e2", borderLeft: "4px solid #ef4444", color: "#991b1b", padding: "14px", borderRadius: "8px", marginBottom: "20px", display: "flex", gap: "10px" }}>
            <AlertCircle size={20} color="#dc2626" style={{ flexShrink: 0 }} />
            <span>{error}</span>
          </div>
        )}

        <div style={{
          background: "#ffffff",
          borderRadius: "20px",
          border: "1px solid #e2e8f0",
          boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.05)",
          overflow: "hidden",
          textAlign: "center"
        }}>
          {/* Header Banner */}
          <div style={{
            background: turnoActivo
              ? "linear-gradient(135deg, #10b981 0%, #059669 100%)"
              : "linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%)",
            color: "#ffffff",
            padding: "36px 20px",
            transition: "all 0.5s ease"
          }}>
            <div style={{
              display: "inline-flex",
              background: "rgba(255, 255, 255, 0.2)",
              padding: "16px",
              borderRadius: "50%",
              marginBottom: "14px"
            }}>
              {turnoActivo ? <Sparkles size={48} color="#ffffff" /> : <Users size={48} color="#ffffff" />}
            </div>
            <h2 style={{ fontSize: "24px", color: "#ffffff", margin: 0 }}>
              {turnoActivo ? "¡ES TU TURNO DE MATRÍCULA!" : "SALA DE ESPERA VIRTUAL"}
            </h2>
            <p style={{ margin: "8px 0 0", color: "rgba(255,255,255,0.85)", fontSize: "14px" }}>
              {turnoActivo
                ? "El servidor ha habilitado su acceso. Dispone de 5 minutos para seleccionar y confirmar."
                : "Regulando el tráfico concurrente para garantizar alta disponibilidad y evitar caídas."}
            </p>
          </div>

          {/* Cuerpo Central */}
          <div style={{ padding: "40px 30px" }}>
            {loading ? (
              <div style={{ padding: "20px", color: "#64748b" }}>Ingresando a la cola virtual...</div>
            ) : turnoActivo ? (
              <div className="fade-in">
                <div style={{
                  background: "#ecfdf5",
                  border: "2px solid #10b981",
                  borderRadius: "16px",
                  padding: "24px",
                  marginBottom: "26px"
                }}>
                  <div style={{ fontSize: "15px", color: "#065f46", fontWeight: "600", marginBottom: "6px" }}>
                    TURNO HABILITADO
                  </div>
                  <div style={{ fontSize: "40px", fontWeight: "800", color: "#047857", letterSpacing: "1px" }}>
                    TURNO ACTIVO #01
                  </div>
                  <div style={{ fontSize: "13px", color: "#059669", marginTop: "8px" }}>
                    ⏱️ Temporizador de reserva activado: <strong>5 minutos de permanencia</strong>
                  </div>
                </div>

                <button
                  onClick={() => setView("matricula")}
                  style={{
                    background: "linear-gradient(135deg, #10b981 0%, #059669 100%)",
                    color: "#ffffff",
                    border: "none",
                    padding: "16px 36px",
                    borderRadius: "10px",
                    fontSize: "16px",
                    fontWeight: "700",
                    cursor: "pointer",
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "10px",
                    boxShadow: "0 10px 15px -3px rgba(16,185,129,0.4)",
                    animation: "bounceFadeIn 0.5s ease"
                  }}
                >
                  <span>Ingresar a Selección de Cursos</span>
                  <ArrowRight size={20} />
                </button>
              </div>
            ) : (
              <div>
                <div style={{
                  background: "#f8fafc",
                  border: "2px dashed #cbd5e1",
                  borderRadius: "16px",
                  padding: "28px",
                  marginBottom: "24px"
                }}>
                  <div style={{ fontSize: "13px", color: "#64748b", fontWeight: "600", textTransform: "uppercase", letterSpacing: "1px" }}>
                    Tu Posición en la Fila
                  </div>
                  <div style={{ fontSize: "56px", fontWeight: "900", color: "#1e3a8a", margin: "6px 0" }}>
                    #{String(posicion || "--").padStart(2, "0")}
                  </div>
                  <div style={{ display: "inline-flex", alignItems: "center", gap: "6px", background: "#e0f2fe", color: "#0369a1", padding: "6px 16px", borderRadius: "20px", fontSize: "13px", fontWeight: "600" }}>
                    <Clock size={16} />
                    <span>Tiempo estimado de espera: {esperaEstimada}</span>
                  </div>
                </div>

                <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "8px", fontSize: "12px", color: "#94a3b8" }}>
                  <RefreshCw size={14} className="spin" style={{ animation: "spin 2s linear infinite" }} />
                  <span>Actualizando automáticamente cada 5 segundos (Sondeo #{pollingCount})...</span>
                </div>
              </div>
            )}

            {/* Aviso inferior */}
            <div style={{
              marginTop: "30px",
              paddingTop: "20px",
              borderTop: "1px solid #f1f5f9",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: "8px",
              fontSize: "12px",
              color: "#64748b"
            }}>
              <ShieldCheck size={16} color="#10b981" />
              <span>Por favor, mantenga abierta esta ventana. El sistema lo redirigirá en cuanto llegue su turno.</span>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
