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
  const [segundosRestantes, setSegundosRestantes] = useState(300);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [pollingCount, setPollingCount] = useState(0);
  const [turnoExpirado, setTurnoExpirado] = useState(false);
  const [isMobile, setIsMobile] = useState(window.innerWidth < 640);

  // Detectar cambio de tamaño de pantalla
  useEffect(() => {
    const handleResize = () => setIsMobile(window.innerWidth < 640);
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  // Función reutilizable para registrar/re-registrar en cola
  const registrarEnCola = async () => {
    try {
      setLoading(true);
      setError("");
      setTurnoExpirado(false);
      setTurnoActivo(false);
      const res = await api.ingresarCola();
      setPosicion(res.posicion);
      if (res.turno_activo) {
        const seg = res.segundos_restantes ?? 300;
        setSegundosRestantes(seg);
        localStorage.setItem("turno_segundos", String(seg));
        setTurnoActivo(true);
      }
    } catch (err) {
      setError(err.message || "Error al acceder a la sala de espera.");
    } finally {
      setLoading(false);
    }
  };

  // 1. Inscribir en cola al montar
  useEffect(() => {
    registrarEnCola();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // 2. Polling periódico cada 5 segundos — SOLO cuando el turno NO está activo
  useEffect(() => {
    if (turnoActivo) return;

    const intervalo = setInterval(async () => {
      try {
        const res = await api.getPosicionCola();
        setPosicion(res.posicion);
        setEsperaEstimada(res.espera_estimada);
        setPollingCount((prev) => prev + 1);

        if (res.turno_activo) {
          setError("");
          const seg = res.segundos_restantes ?? 300;
          setSegundosRestantes(seg);
          localStorage.setItem("turno_segundos", String(seg));
          setTurnoActivo(true);
        }

        if (res.estado_turno === "FINALIZADO" || res.redirect === "/confirmacion") {
          clearInterval(intervalo);
          setView("confirmacion");
        }
      } catch (err) {
        const redirect = err.data?.redirect;
        if (redirect === "/portafolio") {
          setView("portafolio");
        } else if (redirect === "/confirmacion") {
          clearInterval(intervalo);
          setView("confirmacion");
        } else if (redirect === "/cola-virtual" || err.data?.expirado) {
          // Turno expirado en servidor → re-inscribir automáticamente sin recargar página
          clearInterval(intervalo);
          registrarEnCola();
        } else if (err.status === 404) {
          // No registrado en cola → re-inscribir automáticamente
          clearInterval(intervalo);
          registrarEnCola();
        } else {
          setError(err.message);
        }
      }
    }, 5000);

    return () => clearInterval(intervalo);
  }, [turnoActivo, setView]);

  // 3. Cronómetro que corre en la COLA cuando el turno está activo.
  //    El mismo tiempo sigue en MatriculaPage (cuenta continua, no reinicia).
  useEffect(() => {
    if (!turnoActivo) return;

    const tick = setInterval(() => {
      setSegundosRestantes((prev) => {
        const next = prev - 1;
        localStorage.setItem("turno_segundos", String(next));
        if (next <= 0) {
          clearInterval(tick);
          // Expiró en la cola → avisar al servidor y re-inscribir automáticamente
          api.timeoutMatricula()
            .catch(() => {})
            .finally(() => { registrarEnCola(); });
        }
        return Math.max(0, next);
      });
    }, 1000);

    return () => clearInterval(tick);
  }, [turnoActivo]);

  const formatTime = (secs) => {
    const m = Math.floor(Math.max(0, secs) / 60);
    const s = Math.max(0, secs) % 60;
    return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  };

  const isUrgent  = turnoActivo && segundosRestantes <= 60;
  const isMedium  = turnoActivo && segundosRestantes <= 120 && segundosRestantes > 60;
  const timerColor = isUrgent ? "#ef4444" : isMedium ? "#f59e0b" : "#10b981";
  const timerBg    = isUrgent ? "rgba(239,68,68,0.15)" : isMedium ? "rgba(245,158,11,0.15)" : "rgba(16,185,129,0.15)";

  return (
    <div style={{ minHeight: "100vh", background: "#f8fafc" }}>
      <Navbar />

      <main style={{
        maxWidth: "680px",
        margin: isMobile ? "16px auto" : "40px auto",
        padding: isMobile ? "0 12px" : "0 20px"
      }} className="fade-in">

        {/* Alerta de error / turno expirado */}
        {(error || turnoExpirado) && (
          <div style={{
            background: "#fee2e2",
            borderLeft: "4px solid #ef4444",
            color: "#991b1b",
            padding: isMobile ? "10px 12px" : "14px",
            borderRadius: "8px",
            marginBottom: "16px",
            display: "flex",
            gap: "8px",
            fontSize: isMobile ? "13px" : "14px",
            lineHeight: "1.5"
          }}>
            <AlertCircle size={18} color="#dc2626" style={{ flexShrink: 0, marginTop: "2px" }} />
            <span>
              {turnoExpirado
                ? "⏰ Tu tiempo expiró. Tus reservas fueron liberadas. Recarga para volver a la cola."
                : error}
            </span>
          </div>
        )}

        <div style={{
          background: "#ffffff",
          borderRadius: isMobile ? "16px" : "20px",
          border: "1px solid #e2e8f0",
          boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.05)",
          overflow: "hidden",
          textAlign: "center"
        }}>
          {/* Header Banner */}
          <div style={{
            background: turnoExpirado
              ? "linear-gradient(135deg, #dc2626 0%, #b91c1c 100%)"
              : turnoActivo
              ? "linear-gradient(135deg, #10b981 0%, #059669 100%)"
              : "linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%)",
            color: "#ffffff",
            padding: isMobile ? "24px 16px" : "36px 20px",
            transition: "all 0.5s ease"
          }}>
            <div style={{
              display: "inline-flex",
              background: "rgba(255, 255, 255, 0.2)",
              padding: isMobile ? "12px" : "16px",
              borderRadius: "50%",
              marginBottom: isMobile ? "10px" : "14px"
            }}>
              {turnoActivo
                ? <Sparkles size={isMobile ? 36 : 48} color="#ffffff" />
                : <Users    size={isMobile ? 36 : 48} color="#ffffff" />}
            </div>
            <h2 style={{
              fontSize: isMobile ? "17px" : "24px",
              color: "#ffffff",
              margin: 0,
              lineHeight: "1.3"
            }}>
              {turnoExpirado
                ? "TURNO EXPIRADO"
                : turnoActivo
                ? "¡ES TU TURNO DE MATRÍCULA!"
                : "SALA DE ESPERA VIRTUAL"}
            </h2>
            <p style={{
              margin: "6px 0 0",
              color: "rgba(255,255,255,0.85)",
              fontSize: isMobile ? "12px" : "14px",
              lineHeight: "1.5"
            }}>
              {turnoExpirado
                ? "Su tiempo se agotó. Puede reingresar a la cola recargando la página."
                : turnoActivo
                ? "El servidor ha habilitado su acceso. El cronómetro ya está corriendo."
                : "Regulando el tráfico concurrente para garantizar alta disponibilidad."}
            </p>
          </div>

          {/* Cuerpo Central */}
          <div style={{ padding: isMobile ? "24px 16px" : "40px 30px" }}>
            {loading ? (
              <div style={{ padding: "20px", color: "#64748b", fontSize: isMobile ? "14px" : "16px" }}>
                Ingresando a la cola virtual...
              </div>
            ) : turnoActivo ? (
              <div className="fade-in">
                {/* Tarjeta de turno activo */}
                <div style={{
                  background: "#ecfdf5",
                  border: `2px solid ${timerColor}`,
                  borderRadius: "16px",
                  padding: isMobile ? "18px 14px" : "24px",
                  marginBottom: isMobile ? "18px" : "26px",
                  transition: "border-color 0.5s"
                }}>
                  <div style={{
                    fontSize: isMobile ? "12px" : "15px",
                    color: "#065f46",
                    fontWeight: "600",
                    marginBottom: "4px",
                    letterSpacing: "0.5px"
                  }}>
                    TURNO HABILITADO
                  </div>
                  <div style={{
                    fontSize: isMobile ? "28px" : "40px",
                    fontWeight: "800",
                    color: "#047857",
                    letterSpacing: "1px"
                  }}>
                    TURNO ACTIVO #01
                  </div>

                  {/* ⏱️ CRONÓMETRO VISIBLE EN LA COLA — el mismo reloj continúa en matrícula */}
                  <div style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "6px",
                    background: timerBg,
                    border: `1px solid ${timerColor}`,
                    color: timerColor,
                    padding: isMobile ? "6px 16px" : "8px 24px",
                    borderRadius: "30px",
                    marginTop: "12px",
                    fontWeight: "800",
                    fontSize: isMobile ? "24px" : "28px",
                    fontFamily: "monospace",
                    animation: isUrgent ? "pulseRed 1s infinite" : "none"
                  }}>
                    <Clock size={isMobile ? 18 : 22} />
                    {formatTime(segundosRestantes)}
                  </div>
                  <div style={{ fontSize: "12px", color: "#6b7280", marginTop: "6px", lineHeight: "1.4" }}>
                    {isUrgent
                      ? "⚠️ ¡Tiempo casi agotado! Ingresa ya."
                      : "Este reloj continúa corriendo al ingresar a matricularte"}
                  </div>
                </div>

                {/* Botón de acción — ancho completo en móvil */}
                <button
                  onClick={() => setView("matricula")}
                  disabled={segundosRestantes <= 0}
                  style={{
                    background: segundosRestantes <= 0
                      ? "#9ca3af"
                      : "linear-gradient(135deg, #10b981 0%, #059669 100%)",
                    color: "#ffffff",
                    border: "none",
                    padding: isMobile ? "14px 20px" : "16px 36px",
                    borderRadius: "10px",
                    fontSize: isMobile ? "14px" : "16px",
                    fontWeight: "700",
                    cursor: segundosRestantes <= 0 ? "not-allowed" : "pointer",
                    display: isMobile ? "flex" : "inline-flex",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: "10px",
                    width: isMobile ? "100%" : "auto",
                    boxShadow: segundosRestantes > 0 ? "0 10px 15px -3px rgba(16,185,129,0.4)" : "none",
                    animation: segundosRestantes > 0 ? "bounceFadeIn 0.5s ease" : "none"
                  }}
                >
                  <span>{isMobile ? "Ingresar a Matricularme" : "Ingresar a Selección de Cursos"}</span>
                  <ArrowRight size={isMobile ? 18 : 20} />
                </button>
              </div>
            ) : !turnoExpirado ? (
              <div>
                {/* Tarjeta de posición en espera */}
                <div style={{
                  background: "#f8fafc",
                  border: "2px dashed #cbd5e1",
                  borderRadius: "16px",
                  padding: isMobile ? "20px 14px" : "28px",
                  marginBottom: isMobile ? "18px" : "24px"
                }}>
                  <div style={{
                    fontSize: "13px",
                    color: "#64748b",
                    fontWeight: "600",
                    textTransform: "uppercase",
                    letterSpacing: "1px"
                  }}>
                    Tu Posición en la Fila
                  </div>
                  <div style={{
                    fontSize: isMobile ? "44px" : "56px",
                    fontWeight: "900",
                    color: "#1e3a8a",
                    margin: "4px 0"
                  }}>
                    #{String(posicion || "--").padStart(2, "0")}
                  </div>
                  <div style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "6px",
                    background: "#e0f2fe",
                    color: "#0369a1",
                    padding: "6px 14px",
                    borderRadius: "20px",
                    fontSize: isMobile ? "12px" : "13px",
                    fontWeight: "600"
                  }}>
                    <Clock size={15} />
                    <span>Espera estimada: {esperaEstimada}</span>
                  </div>
                </div>

                {/* Indicador de actualización */}
                <div style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "6px",
                  fontSize: "12px",
                  color: "#94a3b8"
                }}>
                  <RefreshCw size={13} style={{ animation: "spin 2s linear infinite", flexShrink: 0 }} />
                  <span>
                    {isMobile
                      ? `Actualizando... (sondeo #${pollingCount})`
                      : `Actualizando automáticamente cada 5 segundos (Sondeo #${pollingCount})...`}
                  </span>
                </div>
              </div>
            ) : null}

            {/* Aviso inferior */}
            {!turnoExpirado && (
              <div style={{
                marginTop: "24px",
                paddingTop: "18px",
                borderTop: "1px solid #f1f5f9",
                display: "flex",
                alignItems: "flex-start",
                justifyContent: "center",
                gap: "8px",
                fontSize: "12px",
                color: "#64748b",
                lineHeight: "1.5"
              }}>
                <ShieldCheck size={15} color="#10b981" style={{ flexShrink: 0, marginTop: "1px" }} />
                <span>
                  {isMobile
                    ? "Mantenga esta ventana abierta. Lo redirigiremos en su turno."
                    : "Por favor, mantenga abierta esta ventana. El sistema lo redirigirá en cuanto llegue su turno."}
                </span>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
