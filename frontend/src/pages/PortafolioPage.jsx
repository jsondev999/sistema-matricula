import React, { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { api } from "../services/api";
import Navbar from "../components/Navbar";
import { FileCheck, UploadCloud, AlertCircle, CheckCircle2, ArrowRight, ShieldAlert, FileText } from "lucide-react";

export default function PortafolioPage() {
  const { setView } = useAuth();
  const [documentos, setDocumentos] = useState([]);
  const [completos, setCompletos] = useState(false);
  const [loading, setLoading] = useState(true);
  const [uploadingId, setUploadingId] = useState(null);
  const [mensaje, setMensaje] = useState("");
  const [error, setError] = useState("");

  const cargarEstado = async () => {
    try {
      setLoading(true);
      const res = await api.getPortafolioEstado();
      setDocumentos(res.documentos || []);
      setCompletos(res.completos);
    } catch (err) {
      setError(err.message || "Error al cargar estado del portafolio.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    cargarEstado();
  }, []);

  const handleSubirArchivo = async (idTipo, file) => {
    if (!file) return;
    setError("");
    setMensaje("");
    setUploadingId(idTipo);

    try {
      const res = await api.subirDocumentoPortafolio(idTipo, file);
      setMensaje(res.mensaje || "Documento subido correctamente.");
      await cargarEstado();
    } catch (err) {
      setError(err.message || "Error al subir documento.");
    } finally {
      setUploadingId(null);
    }
  };

  const totalEntregados = documentos.filter((d) => d.estado_documento === "ENTREGADO").length;

  return (
    <div style={{ minHeight: "100vh", background: "#f8fafc" }}>
      <Navbar />

      <main style={{ maxWidth: "860px", margin: "32px auto", padding: "0 20px" }} className="fade-in">
        {/* Banner de Bienvenida e Instrucciones */}
        <div style={{
          background: "linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%)",
          color: "#ffffff",
          padding: "26px",
          borderRadius: "14px",
          marginBottom: "24px",
          boxShadow: "0 10px 15px -3px rgba(37,99,235,0.2)"
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: "12px", marginBottom: "8px" }}>
            <FileCheck size={28} color="#93c5fd" />
            <h2 style={{ margin: 0, fontSize: "20px", color: "#ffffff" }}>
              Módulo de Portafolio de Admisión (Ingresantes)
            </h2>
          </div>
          <p style={{ margin: 0, fontSize: "14px", color: "#dbeafe", lineHeight: "1.6" }}>
            Como alumno ingresante, debe adjuntar digitalizados sus <strong>4 documentos obligatorios</strong> en formato <strong>JPG o PNG</strong> (máx. 2 MB cada uno).
            Por disposición reglamentaria, el sistema no permitirá el paso a la cola virtual hasta completar su expediente.
          </p>
        </div>

        {/* Mensajes de Alerta */}
        {error && (
          <div style={{ background: "#fee2e2", borderLeft: "4px solid #ef4444", color: "#991b1b", padding: "12px 16px", borderRadius: "8px", marginBottom: "20px", display: "flex", gap: "10px" }}>
            <AlertCircle size={20} color="#dc2626" style={{ flexShrink: 0 }} />
            <span>{error}</span>
          </div>
        )}

        {mensaje && (
          <div style={{ background: "#ecfdf5", borderLeft: "4px solid #10b981", color: "#065f46", padding: "12px 16px", borderRadius: "8px", marginBottom: "20px", display: "flex", gap: "10px" }}>
            <CheckCircle2 size={20} color="#10b981" style={{ flexShrink: 0 }} />
            <span>{mensaje}</span>
          </div>
        )}

        {/* Lista de 4 Requisitos */}
        <div style={{ background: "#ffffff", borderRadius: "14px", border: "1px solid #e2e8f0", padding: "24px", boxShadow: "0 2px 4px rgba(0,0,0,0.04)", marginBottom: "24px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "18px", borderBottom: "1px solid #f1f5f9", paddingBottom: "12px" }}>
            <h3 style={{ margin: 0, fontSize: "16px", color: "#1e293b" }}>Documentos Exigidos por Admisión</h3>
            <span style={{ fontSize: "13px", fontWeight: "700", color: completos ? "#16a34a" : "#ca8a04", background: completos ? "#dcfce7" : "#fef9c3", padding: "4px 12px", borderRadius: "12px" }}>
              {totalEntregados} de 4 entregados
            </span>
          </div>

          {loading ? (
            <div style={{ textAlign: "center", padding: "30px", color: "#64748b" }}>Cargando requisitos...</div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: "14px" }}>
              {documentos.map((doc) => {
                const entregado = doc.estado_documento === "ENTREGADO";
                const isUploading = uploadingId === doc.id_tipo_documento;

                return (
                  <div
                    key={doc.id_tipo_documento}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      padding: "16px",
                      borderRadius: "10px",
                      border: `1px solid ${entregado ? "#bbf7d0" : "#e2e8f0"}`,
                      background: entregado ? "#f0fdf4" : "#ffffff",
                      transition: "all 0.2s ease"
                    }}
                  >
                    <div style={{ display: "flex", alignItems: "center", gap: "14px" }}>
                      <div style={{
                        background: entregado ? "#dcfce7" : "#f1f5f9",
                        color: entregado ? "#16a34a" : "#64748b",
                        padding: "10px",
                        borderRadius: "8px",
                        display: "flex"
                      }}>
                        <FileText size={22} />
                      </div>
                      <div>
                        <div style={{ fontWeight: "600", fontSize: "14px", color: "#1e293b" }}>
                          {doc.nombre}
                        </div>
                        <div style={{ fontSize: "12px", color: "#64748b" }}>
                          {entregado ? (
                            <span style={{ color: "#16a34a", fontWeight: "600" }}>✓ Archivo adjuntado ({doc.formato}, {doc.peso_kb} KB)</span>
                          ) : (
                            <span>Formato requerido: JPG o PNG (máx. 2 MB)</span>
                          )}
                        </div>
                      </div>
                    </div>

                    <div>
                      {entregado ? (
                        <span style={{ background: "#dcfce7", color: "#15803d", padding: "6px 14px", borderRadius: "20px", fontSize: "12px", fontWeight: "700", display: "inline-flex", alignItems: "center", gap: "4px" }}>
                          <CheckCircle2 size={14} /> ENTREGADO
                        </span>
                      ) : (
                        <label style={{
                          background: isUploading ? "#94a3b8" : "#2563eb",
                          color: "#ffffff",
                          padding: "8px 16px",
                          borderRadius: "8px",
                          fontSize: "13px",
                          fontWeight: "600",
                          cursor: isUploading ? "not-allowed" : "pointer",
                          display: "inline-flex",
                          alignItems: "center",
                          gap: "6px"
                        }}>
                          <UploadCloud size={16} />
                          {isUploading ? "Subiendo..." : "Adjuntar Archivo"}
                          <input
                            type="file"
                            accept=".jpg,.jpeg,.png"
                            disabled={isUploading}
                            onChange={(e) => {
                              if (e.target.files?.[0]) {
                                handleSubirArchivo(doc.id_tipo_documento, e.target.files[0]);
                              }
                            }}
                            style={{ display: "none" }}
                          />
                        </label>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Botón de Paso a la Cola Virtual */}
        <div style={{
          background: "#ffffff",
          borderRadius: "14px",
          border: "1px solid #e2e8f0",
          padding: "20px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between"
        }}>
          <div>
            <div style={{ fontWeight: "700", fontSize: "15px", color: "#1e293b" }}>
              {completos ? "Expediente Completo (4/4)" : "Expediente Incompleto"}
            </div>
            <div style={{ fontSize: "12px", color: "#64748b" }}>
              {completos
                ? "Ha completado satisfactoriamente los 4 requisitos. Ya puede acceder a la sala de espera."
                : "Falta subir documentos obligatorios para habilitar el paso a la cola virtual."}
            </div>
          </div>

          <button
            disabled={!completos}
            onClick={() => setView("cola")}
            style={{
              background: completos ? "linear-gradient(135deg, #10b981 0%, #059669 100%)" : "#cbd5e1",
              color: "#ffffff",
              border: "none",
              padding: "12px 24px",
              borderRadius: "8px",
              fontSize: "14px",
              fontWeight: "700",
              cursor: completos ? "pointer" : "not-allowed",
              display: "flex",
              alignItems: "center",
              gap: "8px",
              boxShadow: completos ? "0 4px 12px rgba(16,185,129,0.3)" : "none"
            }}
          >
            {completos ? (
              <>
                <span>Continuar a Cola Virtual</span>
                <ArrowRight size={18} />
              </>
            ) : (
              <>
                <ShieldAlert size={18} />
                <span>Acceso Bloqueado</span>
              </>
            )}
          </button>
        </div>
      </main>
    </div>
  );
}
