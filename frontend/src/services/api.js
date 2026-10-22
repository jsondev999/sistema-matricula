// =============================================================================
// CLIENTE API REST: COMUNICACIÓN CON BACKEND PHP 8 (PDO)
// =============================================================================

const API_BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:8000/api";

function getAuthHeaders(isMultipart = false) {
  const token = localStorage.getItem("token");
  const headers = {};
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }
  if (!isMultipart) {
    headers["Content-Type"] = "application/json";
  }
  return headers;
}

async function handleResponse(response) {
  const text = await response.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch (e) {
    throw new Error(`Respuesta inválida del servidor PHP: ${text.substring(0, 100)}`);
  }

  if (!response.ok) {
    const errorMsg = data.mensaje || data.error || `Error HTTP ${response.status}`;
    const err = new Error(errorMsg);
    err.status = response.status;
    err.data = data;
    throw err;
  }

  return data.data !== undefined ? data.data : data;
}

export const api = {
  // Auth
  login: async (codigo, password) => {
    const res = await fetch(`${API_BASE_URL}/auth/login.php`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ codigo, password }),
    });
    return handleResponse(res);
  },

  logout: async () => {
    const res = await fetch(`${API_BASE_URL}/auth/logout.php`, {
      method: "POST",
      headers: getAuthHeaders(),
    });
    return handleResponse(res);
  },

  recuperar: async (codigo, correo) => {
    const res = await fetch(`${API_BASE_URL}/auth/recuperar.php`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ codigo, correo }),
    });
    return handleResponse(res);
  },

  // Portafolio
  getPortafolioEstado: async () => {
    const res = await fetch(`${API_BASE_URL}/portafolio/estado.php`, {
      method: "GET",
      headers: getAuthHeaders(),
    });
    return handleResponse(res);
  },

  subirDocumentoPortafolio: async (idTipoDocumento, file) => {
    const formData = new FormData();
    formData.append("id_tipo_documento", idTipoDocumento);
    formData.append("archivo", file);

    const res = await fetch(`${API_BASE_URL}/portafolio/subir.php`, {
      method: "POST",
      headers: getAuthHeaders(true),
      body: formData,
    });
    return handleResponse(res);
  },

  // Cola Virtual
  ingresarCola: async () => {
    const res = await fetch(`${API_BASE_URL}/cola/ingresar.php`, {
      method: "POST",
      headers: getAuthHeaders(),
    });
    return handleResponse(res);
  },

  getPosicionCola: async () => {
    const res = await fetch(`${API_BASE_URL}/cola/posicion.php`, {
      method: "GET",
      headers: getAuthHeaders(),
    });
    return handleResponse(res);
  },

  // Matrícula
  getPerfil: async () => {
    const res = await fetch(`${API_BASE_URL}/matricula/perfil.php`, {
      method: "GET",
      headers: getAuthHeaders(),
    });
    return handleResponse(res);
  },

  getCreditos: async () => {
    const res = await fetch(`${API_BASE_URL}/matricula/creditos.php`, {
      method: "GET",
      headers: getAuthHeaders(),
    });
    return handleResponse(res);
  },

  getCatalogo: async () => {
    const res = await fetch(`${API_BASE_URL}/matricula/catalogo.php`, {
      method: "GET",
      headers: getAuthHeaders(),
    });
    return handleResponse(res);
  },

  getProforma: async () => {
    const res = await fetch(`${API_BASE_URL}/matricula/proforma.php`, {
      method: "GET",
      headers: getAuthHeaders(),
    });
    return handleResponse(res);
  },

  agregarCurso: async (idProforma, idSeccion) => {
    const res = await fetch(`${API_BASE_URL}/matricula/agregar_curso.php`, {
      method: "POST",
      headers: getAuthHeaders(),
      body: JSON.stringify({ id_proforma: idProforma, id_seccion: idSeccion }),
    });
    return handleResponse(res);
  },

  retirarCurso: async (idProforma, idSeccion) => {
    const res = await fetch(`${API_BASE_URL}/matricula/retirar_curso.php`, {
      method: "POST",
      headers: getAuthHeaders(),
      body: JSON.stringify({ id_proforma: idProforma, id_seccion: idSeccion }),
    });
    return handleResponse(res);
  },

  confirmarMatricula: async (idProforma) => {
    const res = await fetch(`${API_BASE_URL}/matricula/confirmar.php`, {
      method: "POST",
      headers: getAuthHeaders(),
      body: JSON.stringify({ id_proforma: idProforma }),
    });
    return handleResponse(res);
  },

  timeoutMatricula: async () => {
    const res = await fetch(`${API_BASE_URL}/matricula/timeout.php`, {
      method: "POST",
      headers: getAuthHeaders(),
    });
    return handleResponse(res);
  },

  getPdfUrl: (idMatricula) => `${API_BASE_URL}/reportes/generar_ficha.php?id=${idMatricula}&format=html`,
};
