import React from "react";
import { AlertCircle, Calendar, Clock } from "lucide-react";

const DIAS = ["LUNES", "MARTES", "MIERCOLES", "JUEVES", "VIERNES", "SABADO"];
const HORAS = [
  "08:00", "09:00", "10:00", "11:00", "12:00",
  "13:00", "14:00", "15:00", "16:00", "17:00", "18:00"
];

// Colores consistentes para los bloques de cursos
const PALETA_CURSOS = [
  { bg: "#dbeafe", border: "#3b82f6", text: "#1e40af" },
  { bg: "#e0e7ff", border: "#6366f1", text: "#3730a3" },
  { bg: "#f3e8ff", border: "#a855f7", text: "#6b21a8" },
  { bg: "#dcfce7", border: "#22c55e", text: "#15803d" },
  { bg: "#fef3c7", border: "#f59e0b", text: "#92400e" },
  { bg: "#ffedd5", border: "#f97316", text: "#9a3412" }
];

export default function ScheduleGrid({ bloques = [], cruces = [] }) {
  const tieneCruces = cruces && cruces.length > 0;

  // Extraer IDs de secciones en conflicto
  const seccionesEnConflicto = [];
  cruces.forEach((c) => {
    if (c.seccion_1) seccionesEnConflicto.push(c.seccion_1);
    if (c.seccion_2) seccionesEnConflicto.push(c.seccion_2);
  });

  // Mapear cada curso a un color único
  const cursoColorMap = {};
  let colorIdx = 0;
  bloques.forEach((b) => {
    if (!cursoColorMap[b.curso_codigo]) {
      cursoColorMap[b.curso_codigo] = PALETA_CURSOS[colorIdx % PALETA_CURSOS.length];
      colorIdx++;
    }
  });

  return (
    <div style={{ background: "#ffffff", borderRadius: "12px", border: "1px solid #e2e8f0", padding: "20px", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "16px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
          <Calendar size={20} color="#1e3a8a" />
          <h3 style={{ margin: 0, fontSize: "16px", color: "#1e3a8a" }}>Horario Semanal Tentativo</h3>
        </div>
        <span style={{ fontSize: "12px", color: "#64748b" }}>
          {bloques.length} bloque(s) programado(s)
        </span>
      </div>

      {/* Alerta si existen cruces de horario */}
      {tieneCruces && (
        <div
          className="conflict-pulse"
          style={{
            padding: "12px 16px",
            borderRadius: "8px",
            marginBottom: "16px",
            display: "flex",
            alignItems: "flex-start",
            gap: "10px",
            color: "#991b1b",
            fontSize: "13px",
            fontWeight: "500",
          }}
        >
          <AlertCircle size={20} color="#dc2626" style={{ flexShrink: 0, marginTop: "2px" }} />
          <div>
            <strong>¡Cruce de horarios detectado!</strong>
            <ul style={{ margin: "4px 0 0 16px", padding: 0 }}>
              {cruces.map((c, idx) => (
                <li key={idx}>
                  Conflicto el <strong>{c.dia === "MIERCOLES" ? "MIÉRCOLES" : c.dia === "SABADO" ? "SÁBADO" : c.dia}</strong> entre <strong>{c.curso_1}</strong> y <strong>{c.curso_2}</strong> ({c.rango}).
                </li>
              ))}
            </ul>
            <div style={{ marginTop: "4px", fontSize: "12px", fontStyle: "italic" }}>
              * Debe eliminar o cambiar de sección uno de los cursos en conflicto para poder confirmar su matrícula.
            </div>
          </div>
        </div>
      )}

      {/* Tabla Matriz de Horarios */}
      <div style={{ overflowX: "auto" }}>
        <table style={{ width: "100%", borderCollapse: "collapse", minWidth: "650px", fontSize: "11px" }}>
          <thead>
            <tr>
              <th style={{ width: "65px", padding: "8px", background: "#f8fafc", border: "1px solid #e2e8f0", color: "#64748b", textAlign: "center" }}>
                Hora
              </th>
              {DIAS.map((dia) => (
                <th key={dia} style={{ padding: "8px", background: "#f1f5f9", border: "1px solid #e2e8f0", color: "#334155", textAlign: "center", fontWeight: "600" }}>
                  {dia === "MIERCOLES" ? "MIÉRCOLES" : dia === "SABADO" ? "SÁBADO" : dia}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {HORAS.map((hora) => (
              <tr key={hora} style={{ height: "46px" }}>
                <td style={{ textAlign: "center", border: "1px solid #e2e8f0", background: "#f8fafc", color: "#64748b", fontWeight: "600", fontSize: "10px" }}>
                  {hora}
                </td>
                {DIAS.map((dia) => {
                  // Buscar si hay bloque que cubra este día y hora
                  const bloquesEnHora = bloques.filter((b) => {
                    if (b.dia_semana !== dia) return false;
                    const hInicio = parseInt(b.hora_inicio.split(":")[0], 10);
                    const hFin = parseInt(b.hora_fin.split(":")[0], 10);
                    const hActual = parseInt(hora.split(":")[0], 10);
                    return hActual >= hInicio && hActual < hFin;
                  });

                  if (bloquesEnHora.length === 0) {
                    return <td key={dia} style={{ border: "1px solid #f1f5f9", background: "#ffffff" }} />;
                  }

                  const esConflicto = bloquesEnHora.length > 1 || bloquesEnHora.some((b) => seccionesEnConflicto.includes(b.id_seccion));

                  return (
                    <td
                      key={dia}
                      style={{
                        border: "1px solid #e2e8f0",
                        padding: "2px",
                        verticalAlign: "top",
                        background: esConflicto ? "rgba(239, 68, 68, 0.15)" : "#ffffff",
                      }}
                    >
                      {bloquesEnHora.map((b, idx) => {
                        const colors = cursoColorMap[b.curso_codigo] || PALETA_CURSOS[0];
                        const blockConflict = seccionesEnConflicto.includes(b.id_seccion) || bloquesEnHora.length > 1;

                        return (
                          <div
                            key={idx}
                            style={{
                              background: blockConflict ? "#fee2e2" : colors.bg,
                              borderLeft: `4px solid ${blockConflict ? "#ef4444" : colors.border}`,
                              color: blockConflict ? "#991b1b" : colors.text,
                              padding: "4px 6px",
                              borderRadius: "4px",
                              marginBottom: "2px",
                              fontSize: "10px",
                              fontWeight: "600",
                              lineHeight: "1.2",
                              boxShadow: "0 1px 2px rgba(0,0,0,0.05)",
                            }}
                          >
                            <div style={{ whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                              {b.curso_codigo} - {b.curso_nombre}
                            </div>
                            <div style={{ fontSize: "9px", opacity: 0.85, display: "flex", justifyContent: "space-between" }}>
                              <span>Grup: {b.grupo}</span>
                              <span>{b.aula}</span>
                            </div>
                          </div>
                        );
                      })}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
