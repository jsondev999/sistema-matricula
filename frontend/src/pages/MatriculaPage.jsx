import React, { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { api } from "../services/api";
import Navbar from "../components/Navbar";
import ScheduleGrid from "../components/ScheduleGrid";
import {
  BookOpen, Plus, Trash2, Check, AlertTriangle,
  CreditCard, CheckCircle2, AlertCircle, ShieldAlert,
  ArrowRight, Users, Sparkles
} from "lucide-react";

const formatTurno = (t) => {
  if (!t) return "";
  return t.toUpperCase() === "MANANA" ? "MAÑANA" : t;
};

const formatDia = (d) => {
  if (!d) return "";
  switch (d.toUpperCase()) {
    case "MIERCOLES": return "MIÉRCOLES";
    case "SABADO": return "SÁBADO";
    default: return d;
  }
};

export default function MatriculaPage() {
  const { user, setView, setActiveMatriculaId } = useAuth();
  
  const [perfil, setPerfil] = useState(null);
  const [creditosInfo, setCreditosInfo] = useState(null);
  const [catalogo, setCatalogo] = useState([]);
  const [proforma, setProforma] = useState(null);
  
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [modalConfirmar, setModalConfirmar] = useState(false);

  // Cargar todos los datos del proceso
  const cargarDatos = async () => {
    try {
      setError("");
      const [resPerfil, resCreditos, resCatalogo, resProforma] = await Promise.all([
        api.getPerfil(),
        api.getCreditos(),
        api.getCatalogo(),
        api.getProforma(),
      ]);

      setPerfil(resPerfil);
      setCreditosInfo(resCreditos);
      setCatalogo(resCatalogo);
      setProforma(resProforma);

      if (resPerfil.matricula?.id_matricula) {
        setActiveMatriculaId(resPerfil.matricula.id_matricula);
      }
    } catch (err) {
      setError(err.message || "Error al sincronizar datos de matrícula.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    cargarDatos();
  }, []);

  // Manejo del Timeout de 5 minutos
  const handleTimeout = async () => {
    try {
      await api.timeoutMatricula();
    } catch (e) {
      // ignorar error de red
    }
    setError("Su tiempo de 5 minutos ha expirado. Las reservas temporales han sido liberadas.");
    setTimeout(() => setView("cola"), 2500);
  };

  // Agregar curso con bloqueo pesimista
  const handleAgregar = async (idSeccion) => {
    if (!perfil?.matricula?.id_matricula) return;
    setError("");
    setSuccess("");
    setActionLoading(true);

    try {
      const res = await api.agregarCurso(perfil.matricula.id_matricula, idSeccion);
      setSuccess(res.mensaje);
      await cargarDatos();
    } catch (err) {
      setError(err.message || "No se pudo agregar la asignatura.");
    } finally {
      setActionLoading(false);
    }
  };

  // Retirar curso y restituir vacante
  const handleRetirar = async (idSeccion) => {
    if (!perfil?.matricula?.id_matricula) return;
    setError("");
    setSuccess("");
    setActionLoading(true);

    try {
      const res = await api.retirarCurso(perfil.matricula.id_matricula, idSeccion);
      setSuccess(res.mensaje);
      await cargarDatos();
    } catch (err) {
      setError(err.message || "No se pudo retirar la asignatura.");
    } finally {
      setActionLoading(false);
    }
  };

  // Confirmar matrícula definitiva
  const handleConfirmar = async () => {
    if (!perfil?.matricula?.id_matricula) return;
    setError("");
    setActionLoading(true);

    try {
      const res = await api.confirmarMatricula(perfil.matricula.id_matricula);
      setModalConfirmar(false);
      setView("confirmacion");
    } catch (err) {
      setError(err.message || "Error al confirmar la matrícula.");
      setModalConfirmar(false);
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <div style={{ minHeight: "100vh", background: "#f8fafc" }}>
        <Navbar onTimeout={handleTimeout} />
        <div style={{ textAlign: "center", padding: "80px 20px", color: "#64748b" }}>
          Sincronizando oferta académica y cupos en tiempo real...
        </div>
      </div>
    );
  }

  const idMatricula = perfil?.matricula?.id_matricula;
  const cursosEnProforma = proforma?.cursos || [];
  const seccionesInscritasIds = cursosEnProforma.map((c) => c.id_seccion);
  const cursosInscritosIds = cursosEnProforma.map((c) => c.id_curso);

  const totalCreditos = proforma?.total_creditos || 0;
  const limiteMax = creditosInfo?.limite_max || 23;
  const limiteMin = creditosInfo?.limite_min || 12;
  const tieneCruces = proforma?.tiene_cruces || false;

  const cumpleCreditosMinimos = totalCreditos >= limiteMin;
  const puedeConfirmar =
    totalCreditos > 0 &&
    !tieneCruces &&
    cumpleCreditosMinimos &&
    perfil?.matricula?.estado === "PROFORMA";

  return (
    <div style={{ minHeight: "100vh", background: "#f8fafc", paddingBottom: "90px" }}>
      <Navbar onTimeout={handleTimeout} />

      {/* Banner Resumen Académico */}
      <div style={{ background: "#ffffff", borderBottom: "1px solid #e2e8f0", padding: "16px 24px" }}>
        <div style={{ maxWidth: "1400px", margin: "0 auto", display: "flex", flexWrap: "wrap", justifyContent: "space-between", alignItems: "center", gap: "16px" }}>
          <div>
            <h2 style={{ fontSize: "18px", color: "#1e3a8a", margin: 0 }}>
              Panel de Matrícula • {perfil?.estudiante?.escuela_profesional}
            </h2>
            <div style={{ fontSize: "12px", color: "#64748b", marginTop: "2px" }}>
              Sede: <strong>{perfil?.estudiante?.sede}</strong> • Periodo: <strong>{perfil?.periodo?.codigo}</strong> • Promedio: <strong>{perfil?.estudiante?.promedio_ponderado}</strong>
            </div>
          </div>

          {/* Bolsa de Créditos */}
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase" }}>
                Bolsa de Créditos Permitidos
              </div>
              <div style={{ fontSize: "18px", fontWeight: "800", color: totalCreditos > limiteMax ? "#dc2626" : "#1e3a8a" }}>
                {totalCreditos} <span style={{ fontSize: "14px", color: "#64748b", fontWeight: "500" }}>/ {limiteMax} créditos máx.</span>
              </div>
            </div>
            <div style={{
              background: cumpleCreditosMinimos ? "#ecfdf5" : "#fffbeb",
              color: cumpleCreditosMinimos ? "#065f46" : "#b45309",
              border: `1px solid ${cumpleCreditosMinimos ? "#a7f3d0" : "#fde68a"}`,
              padding: "6px 12px",
              borderRadius: "8px",
              fontSize: "12px",
              fontWeight: "600"
            }}>
              Mín: {limiteMin} cr.
            </div>
          </div>
        </div>
      </div>

      <div style={{ maxWidth: "1400px", margin: "24px auto", padding: "0 20px" }}>
        {/* Alertas Globales */}
        {error && (
          <div style={{ background: "#fee2e2", borderLeft: "4px solid #ef4444", color: "#991b1b", padding: "12px 16px", borderRadius: "8px", marginBottom: "16px", display: "flex", gap: "8px" }} className="fade-in">
            <AlertCircle size={18} color="#dc2626" style={{ flexShrink: 0 }} />
            <span>{error}</span>
          </div>
        )}

        {success && (
          <div style={{ background: "#ecfdf5", borderLeft: "4px solid #10b981", color: "#065f46", padding: "12px 16px", borderRadius: "8px", marginBottom: "16px", display: "flex", gap: "8px" }} className="fade-in">
            <CheckCircle2 size={18} color="#10b981" style={{ flexShrink: 0 }} />
            <span>{success}</span>
          </div>
        )}

        <div style={{ display: "grid", gridTemplateColumns: "1.1fr 0.9fr", gap: "24px" }}>
          
          {/* COLUMNA IZQUIERDA: Catálogo de Asignaturas Ofertadas */}
          <div>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "14px" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                <BookOpen size={20} color="#1e3a8a" />
                <h3 style={{ margin: 0, fontSize: "16px", color: "#1e3a8a" }}>Catálogo de Asignaturas Ofertadas</h3>
              </div>
              <span style={{ fontSize: "12px", color: "#64748b" }}>{catalogo.length} asignaturas disponibles</span>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "14px" }}>
              {catalogo.map((curso) => {
                const yaInscrito = cursosInscritosIds.includes(curso.id_curso);

                return (
                  <div
                    key={curso.id_curso}
                    style={{
                      background: "#ffffff",
                      borderRadius: "12px",
                      border: `1px solid ${yaInscrito ? "#93c5fd" : "#e2e8f0"}`,
                      boxShadow: yaInscrito ? "0 4px 12px rgba(59,130,246,0.12)" : "0 2px 4px rgba(0,0,0,0.03)",
                      padding: "16px",
                      transition: "all 0.2s ease"
                    }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "10px" }}>
                      <div>
                        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                          <span style={{ background: "#f1f5f9", color: "#475569", padding: "2px 8px", borderRadius: "4px", fontSize: "11px", fontWeight: "700" }}>
                            {curso.codigo}
                          </span>
                          <span style={{ fontSize: "11px", color: "#64748b" }}>Ciclo {curso.ciclo}</span>
                        </div>
                        <h4 style={{ margin: "4px 0 0", fontSize: "15px", color: "#1e293b" }}>
                          {curso.nombre}
                        </h4>
                      </div>
                      <span style={{ background: "#e0f2fe", color: "#0369a1", padding: "3px 10px", borderRadius: "12px", fontSize: "12px", fontWeight: "700" }}>
                        {curso.creditos} créditos
                      </span>
                    </div>

                    {/* Secciones Grupo A y Grupo B */}
                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "10px", marginTop: "12px" }}>
                      {curso.secciones?.map((sec) => {
                        const seleccionada = seccionesInscritasIds.includes(sec.id_seccion);
                        const sinVacantes = sec.vacantes_disponibles <= 0;
                        const puedeAgregar = !yaInscrito && !sinVacantes && (totalCreditos + curso.creditos <= limiteMax);

                        return (
                          <div
                            key={sec.id_seccion}
                            style={{
                              border: `1px solid ${seleccionada ? "#10b981" : "#e2e8f0"}`,
                              background: seleccionada ? "#f0fdf4" : "#f8fafc",
                              borderRadius: "8px",
                              padding: "10px",
                              display: "flex",
                              flexDirection: "column",
                              justifyContent: "space-between"
                            }}
                          >
                            <div>
                              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "4px" }}>
                                <strong style={{ fontSize: "13px", color: "#1e3a8a" }}>
                                  Grupo {sec.grupo} ({formatTurno(sec.turno)})
                                </strong>
                                <span style={{
                                  fontSize: "11px",
                                  fontWeight: "700",
                                  color: sinVacantes ? "#dc2626" : "#16a34a"
                                }}>
                                  {sinVacantes ? "0 vacantes" : `${sec.vacantes_disponibles} vac.`}
                                </span>
                              </div>

                              <div style={{ fontSize: "11px", color: "#475569", marginBottom: "6px" }}>
                                👨‍🏫 {sec.docente_nombre}
                              </div>

                              <div style={{ fontSize: "10px", color: "#64748b", marginBottom: "8px" }}>
                                {sec.horarios?.map((h, i) => (
                                  <div key={i}>
                                    {formatDia(h.dia_semana)} {h.hora_inicio}-{h.hora_fin} ({h.aula})
                                  </div>
                                ))}
                              </div>
                            </div>

                            {seleccionada ? (
                              <button
                                disabled={actionLoading}
                                onClick={() => handleRetirar(sec.id_seccion)}
                                style={{
                                  background: "#fee2e2",
                                  border: "1px solid #fca5a5",
                                  color: "#b91c1c",
                                  padding: "6px 10px",
                                  borderRadius: "6px",
                                  fontSize: "11px",
                                  fontWeight: "700",
                                  cursor: "pointer",
                                  display: "flex",
                                  alignItems: "center",
                                  justifyContent: "center",
                                  gap: "4px"
                                }}
                              >
                                <Trash2 size={13} />
                                <span>Retirar Curso</span>
                              </button>
                            ) : (
                              <button
                                disabled={actionLoading || !puedeAgregar}
                                onClick={() => handleAgregar(sec.id_seccion)}
                                style={{
                                  background: puedeAgregar ? "#2563eb" : "#cbd5e1",
                                  border: "none",
                                  color: "#ffffff",
                                  padding: "6px 10px",
                                  borderRadius: "6px",
                                  fontSize: "11px",
                                  fontWeight: "700",
                                  cursor: puedeAgregar ? "pointer" : "not-allowed",
                                  display: "flex",
                                  alignItems: "center",
                                  justifyContent: "center",
                                  gap: "4px"
                                }}
                              >
                                <Plus size={13} />
                                <span>
                                  {sinVacantes
                                    ? "Sin Vacantes"
                                    : yaInscrito
                                    ? "Ya en Proforma"
                                    : "Agregar a Proforma"}
                                </span>
                              </button>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* COLUMNA DERECHA: Horario Tentativo y Resumen de Proforma */}
          <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
            
            {/* Grilla Semanal */}
            <ScheduleGrid
              bloques={proforma?.bloques_horario || []}
              cruces={proforma?.cruces || []}
            />

            {/* Tabla Resumen de Cursos en Proforma */}
            <div style={{ background: "#ffffff", borderRadius: "12px", border: "1px solid #e2e8f0", padding: "18px", boxShadow: "0 2px 6px rgba(0,0,0,0.03)" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "12px" }}>
                <h4 style={{ margin: 0, fontSize: "15px", color: "#1e3a8a" }}>
                  Asignaturas en Proforma ({cursosEnProforma.length})
                </h4>
                <span style={{ fontSize: "13px", fontWeight: "700", color: "#1e40af" }}>
                  {totalCreditos} créditos
                </span>
              </div>

              {cursosEnProforma.length === 0 ? (
                <div style={{ textAlign: "center", padding: "24px", color: "#94a3b8", fontSize: "13px" }}>
                  No ha seleccionado ninguna asignatura aún.
                </div>
              ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                  {cursosEnProforma.map((item) => (
                    <div
                      key={item.id_detalle}
                      style={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        padding: "8px 12px",
                        background: "#f8fafc",
                        borderRadius: "8px",
                        border: "1px solid #e2e8f0",
                        fontSize: "12px"
                      }}
                    >
                      <div>
                        <strong>{item.curso_codigo}</strong> - {item.curso_nombre}{" "}
                        <span style={{ color: "#2563eb", fontWeight: "600" }}>(Grup. {item.grupo})</span>
                        <div style={{ fontSize: "11px", color: "#64748b" }}>
                          Prof. {item.docente_nombre} • {item.creditos} cr.
                        </div>
                      </div>
                      <button
                        onClick={() => handleRetirar(item.id_seccion)}
                        title="Quitar asignatura"
                        style={{
                          background: "none",
                          border: "none",
                          color: "#ef4444",
                          cursor: "pointer",
                          padding: "4px"
                        }}
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* BARRA INFERIOR FIJA: Confirmación y Liquidación */}
      <footer style={{
        position: "fixed",
        bottom: 0,
        left: 0,
        right: 0,
        background: "#ffffff",
        borderTop: "2px solid #e2e8f0",
        padding: "12px 24px",
        boxShadow: "0 -4px 16px rgba(0,0,0,0.08)",
        zIndex: 100
      }}>
        <div style={{ maxWidth: "1400px", margin: "0 auto", display: "flex", flexWrap: "wrap", justifyContent: "space-between", alignItems: "center", gap: "16px" }}>
          
          <div style={{ display: "flex", alignItems: "center", gap: "24px" }}>
            <div>
              <div style={{ fontSize: "11px", color: "#64748b", fontWeight: "600" }}>DERECHO DE MATRÍCULA</div>
              <div style={{ fontSize: "18px", fontWeight: "800", color: "#1e3a8a" }}>
                S/. {Number(proforma?.monto_total || 120).toFixed(2)}
              </div>
            </div>

            <div>
              <div style={{ fontSize: "11px", color: "#64748b", fontWeight: "600" }}>ESTADO DE PAGO</div>
              <span style={{
                background: proforma?.estado_pago === "PAGADO" ? "#dcfce7" : "#fee2e2",
                color: proforma?.estado_pago === "PAGADO" ? "#16a34a" : "#dc2626",
                padding: "3px 10px",
                borderRadius: "12px",
                fontSize: "12px",
                fontWeight: "700",
                display: "inline-flex",
                alignItems: "center",
                gap: "4px"
              }}>
                <Check size={13} /> {proforma?.estado_pago || "PAGADO"}
              </span>
            </div>

            <div>
              <div style={{ fontSize: "11px", color: "#64748b", fontWeight: "600" }}>CRÉDITOS SELECCIONADOS</div>
              <div style={{ fontSize: "14px", fontWeight: "700", color: cumpleCreditosMinimos ? "#16a34a" : "#b45309" }}>
                {totalCreditos} cr. {cumpleCreditosMinimos ? "✓ (Válido)" : `(Requiere mín. ${limiteMin})`}
              </div>
            </div>
          </div>

          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            {tieneCruces && (
              <span style={{ color: "#dc2626", fontSize: "13px", fontWeight: "600", display: "flex", alignItems: "center", gap: "4px" }}>
                <AlertTriangle size={16} /> Cruces detectados
              </span>
            )}

            <button
              disabled={!puedeConfirmar || actionLoading}
              onClick={() => setModalConfirmar(true)}
              style={{
                background: puedeConfirmar ? "linear-gradient(135deg, #10b981 0%, #059669 100%)" : "#cbd5e1",
                color: "#ffffff",
                border: "none",
                padding: "12px 28px",
                borderRadius: "8px",
                fontSize: "15px",
                fontWeight: "700",
                cursor: puedeConfirmar ? "pointer" : "not-allowed",
                display: "flex",
                alignItems: "center",
                gap: "8px",
                boxShadow: puedeConfirmar ? "0 4px 12px rgba(16,185,129,0.3)" : "none"
              }}
            >
              <span>Confirmar Matrícula</span>
              <ArrowRight size={18} />
            </button>
          </div>
        </div>
      </footer>

      {/* Modal de Advertencia de Confirmación */}
      {modalConfirmar && (
        <div style={{
          position: "fixed",
          top: 0, left: 0, right: 0, bottom: 0,
          background: "rgba(15, 23, 42, 0.7)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          padding: "20px",
          zIndex: 1000
        }}>
          <div style={{ background: "#ffffff", padding: "28px", borderRadius: "16px", maxWidth: "460px", width: "100%", boxShadow: "0 20px 25px -5px rgba(0,0,0,0.3)" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "10px", color: "#1e3a8a", marginBottom: "12px" }}>
              <ShieldAlert size={28} color="#2563eb" />
              <h3 style={{ margin: 0, fontSize: "18px" }}>¿Confirmar Matrícula Definitiva?</h3>
            </div>
            
            <p style={{ fontSize: "13px", color: "#475569", lineHeight: "1.6", margin: "0 0 20px" }}>
              Está a punto de formalizar su matrícula para el <strong>Periodo 2026-II</strong> con un total de <strong>{totalCreditos} créditos</strong>.
              <br/><br/>
              ⚠️ <em>De acuerdo con el Reglamento Académico, una vez confirmada la matrícula, el estado pasa a <strong>CONFIRMADA</strong> y el registro queda <strong>bloqueado para modificaciones</strong>.</em>
            </p>

            <div style={{ display: "flex", justifyContent: "flex-end", gap: "12px" }}>
              <button
                type="button"
                onClick={() => setModalConfirmar(false)}
                style={{ background: "#f1f5f9", border: "1px solid #cbd5e1", padding: "10px 18px", borderRadius: "8px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}
              >
                Seguir Editando
              </button>
              <button
                type="button"
                disabled={actionLoading}
                onClick={handleConfirmar}
                style={{ background: "linear-gradient(135deg, #10b981 0%, #059669 100%)", color: "#ffffff", border: "none", padding: "10px 22px", borderRadius: "8px", fontSize: "13px", fontWeight: "700", cursor: "pointer" }}
              >
                {actionLoading ? "Procesando Transacción..." : "Sí, Confirmar Definitivamente"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
