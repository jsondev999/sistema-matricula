import React, { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { api } from "../services/api";
import Navbar from "../components/Navbar";
import { CheckCircle2, FileDown, ShieldCheck, Printer, LogOut, Award, BookCheck } from "lucide-react";

export default function ConfirmacionPage() {
  const { user, activeMatriculaId, logout } = useAuth();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const cargarFicha = async () => {
      try {
        if (!activeMatriculaId) {
          // Si no tiene id en contexto, consultar el perfil
          const p = await api.getPerfil();
          if (p.matricula?.id_matricula) {
            const res = await api.getProforma();
            setData({ matricula: p.matricula, proforma: res });
          }
        } else {
          const res = await api.getProforma();
          setData({ matricula: { id_matricula: activeMatriculaId }, proforma: res });
        }
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    cargarFicha();
  }, [activeMatriculaId]);

  const matId = activeMatriculaId || data?.matricula?.id_matricula || 1;
  const pdfUrl = api.getPdfUrl(matId);

  return (
    <div style={{ minHeight: "100vh", background: "#f8fafc" }}>
      <Navbar />

      <main style={{ maxWidth: "780px", margin: "40px auto", padding: "0 20px" }} className="fade-in">
        <div style={{
          background: "#ffffff",
          borderRadius: "20px",
          border: "1px solid #e2e8f0",
          boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.05)",
          overflow: "hidden",
          textAlign: "center"
        }}>
          {/* Header Celebración */}
          <div style={{
            background: "linear-gradient(135deg, #059669 0%, #10b981 100%)",
            color: "#ffffff",
            padding: "40px 20px"
          }}>
            <div style={{
              display: "inline-flex",
              background: "rgba(255, 255, 255, 0.2)",
              padding: "18px",
              borderRadius: "50%",
              marginBottom: "16px"
            }}>
              <CheckCircle2 size={54} color="#ffffff" />
            </div>
            <h2 style={{ fontSize: "26px", color: "#ffffff", margin: 0 }}>
              ¡MATRÍCULA CONFIRMADA EXITOSAMENTE!
            </h2>
            <p style={{ margin: "8px 0 0", color: "#d1fae5", fontSize: "15px" }}>
              Su registro ha sido procesado de manera oficial y permanente para el Semestre 2026-II.
            </p>
          </div>

          {/* Cuerpo Resumen */}
          <div style={{ padding: "36px 30px" }}>
            <div style={{
              background: "#f0fdf4",
              border: "1px solid #bbf7d0",
              borderRadius: "14px",
              padding: "20px",
              marginBottom: "28px",
              display: "grid",
              gridTemplateColumns: "repeat(3, 1fr)",
              gap: "14px",
              textAlign: "center"
            }}>
              <div>
                <div style={{ fontSize: "11px", color: "#166534", fontWeight: "700", textTransform: "uppercase" }}>
                  Estado Actual
                </div>
                <div style={{ fontSize: "16px", fontWeight: "800", color: "#15803d", marginTop: "2px" }}>
                  CONFIRMADA
                </div>
              </div>

              <div>
                <div style={{ fontSize: "11px", color: "#166534", fontWeight: "700", textTransform: "uppercase" }}>
                  Total Créditos
                </div>
                <div style={{ fontSize: "16px", fontWeight: "800", color: "#15803d", marginTop: "2px" }}>
                  {data?.proforma?.total_creditos || 12} créditos
                </div>
              </div>

              <div>
                <div style={{ fontSize: "11px", color: "#166534", fontWeight: "700", textTransform: "uppercase" }}>
                  Edición de Cursos
                </div>
                <div style={{ fontSize: "16px", fontWeight: "800", color: "#dc2626", marginTop: "2px" }}>
                  BLOQUEADA (RF-20)
                </div>
              </div>
            </div>

            {/* Aviso de Inmutabilidad */}
            <div style={{
              background: "#f8fafc",
              border: "1px solid #e2e8f0",
              borderRadius: "10px",
              padding: "16px",
              marginBottom: "30px",
              textAlign: "left",
              fontSize: "13px",
              color: "#475569",
              display: "flex",
              alignItems: "flex-start",
              gap: "12px"
            }}>
              <ShieldCheck size={22} color="#10b981" style={{ flexShrink: 0, marginTop: "2px" }} />
              <div>
                <strong>Garantía de Inmutabilidad y Reserva Definitiva:</strong>
                <p style={{ margin: "4px 0 0", lineHeight: "1.5" }}>
                  Sus vacantes han sido consolidadas de forma definitiva en la base de datos de la UNJBG.
                  Puede descargar e imprimir su Ficha Oficial de Matrícula para cualquier trámite universitario.
                </p>
              </div>
            </div>

            {/* Botones de Acción */}
            <div style={{ display: "flex", justifyContent: "center", gap: "16px", flexWrap: "wrap" }}>
              <a
                href={pdfUrl}
                target="_blank"
                rel="noopener noreferrer"
                style={{
                  background: "linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%)",
                  color: "#ffffff",
                  textDecoration: "none",
                  padding: "14px 28px",
                  borderRadius: "10px",
                  fontSize: "15px",
                  fontWeight: "700",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "10px",
                  boxShadow: "0 10px 15px -3px rgba(37,99,235,0.35)",
                  cursor: "pointer"
                }}
              >
                <FileDown size={20} />
                <span>Descargar Ficha Oficial en PDF</span>
              </a>

              <button
                onClick={logout}
                style={{
                  background: "#f1f5f9",
                  border: "1px solid #cbd5e1",
                  color: "#334155",
                  padding: "14px 24px",
                  borderRadius: "10px",
                  fontSize: "15px",
                  fontWeight: "600",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px",
                  cursor: "pointer"
                }}
              >
                <LogOut size={18} />
                <span>Cerrar Sesión</span>
              </button>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
