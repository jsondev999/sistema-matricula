import React from 'react';
import { useAuth } from './context/AuthContext';
import LoginPage from './pages/LoginPage';
import PortafolioPage from './pages/PortafolioPage';
import ColaVirtualPage from './pages/ColaVirtualPage';
import MatriculaPage from './pages/MatriculaPage';
import ConfirmacionPage from './pages/ConfirmacionPage';

function App() {
  const { user, view } = useAuth();

  // Si no hay usuario autenticado o la vista es login, mostrar LoginPage
  if (!user || view === 'login') {
    return <LoginPage />;
  }

  // Enrutamiento de vistas según estado del estudiante
  switch (view) {
    case 'portafolio':
      return <PortafolioPage />;
    case 'cola':
      return <ColaVirtualPage />;
    case 'matricula':
      return <MatriculaPage />;
    case 'confirmacion':
      return <ConfirmacionPage />;
    default:
      return <LoginPage />;
  }
}

export default App;
