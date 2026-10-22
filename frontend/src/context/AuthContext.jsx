import React, { createContext, useContext, useState, useEffect } from "react";
import { api } from "../services/api";

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem("token") || "");
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem("user");
    return saved ? JSON.parse(saved) : null;
  });
  const [view, setView] = useState(() => {
    const savedView = localStorage.getItem("current_view");
    return savedView || "login";
  });
  const [activeMatriculaId, setActiveMatriculaId] = useState(null);

  useEffect(() => {
    if (token) {
      localStorage.setItem("token", token);
    } else {
      localStorage.removeItem("token");
    }
  }, [token]);

  useEffect(() => {
    if (user) {
      localStorage.setItem("user", JSON.stringify(user));
    } else {
      localStorage.removeItem("user");
    }
  }, [user]);

  useEffect(() => {
    localStorage.setItem("current_view", view);
  }, [view]);

  const login = async (codigo, password) => {
    const res = await api.login(codigo, password);
    localStorage.setItem("token", res.token);
    localStorage.setItem("user", JSON.stringify(res.estudiante));
    setToken(res.token);
    setUser(res.estudiante);

    if (res.es_ingresante) {
      setView("portafolio");
    } else {
      setView("cola");
    }
    return res;
  };

  const logout = async () => {
    try {
      await api.logout();
    } catch (e) {
      // Ignore network errors on logout
    }
    setToken("");
    setUser(null);
    setView("login");
    setActiveMatriculaId(null);
    localStorage.clear();
  };

  return (
    <AuthContext.Provider
      value={{
        token,
        user,
        setUser,
        view,
        setView,
        login,
        logout,
        activeMatriculaId,
        setActiveMatriculaId,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
