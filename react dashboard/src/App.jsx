import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Signup from './pages/Signup';
import MohallahManager from './pages/MohallahManager';
import Dashboard from './pages/Dashboard';
import ForgotPassword from './pages/ForgotPassword';
import ResetPassword from './pages/ResetPassword';
import Overview from './pages/dashboard/Overview';
import Users from './pages/dashboard/Users';
import Admins from './pages/dashboard/Admins';
import Announcements from './pages/dashboard/Announcements';
import Complaints from './pages/dashboard/Complaints';
import Marketplace from './pages/dashboard/Marketplace';
import Services from './pages/dashboard/Services';
import LocalVibesModeration from './pages/dashboard/LocalVibesModeration';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import { ThemeProvider } from './context/ThemeContext';
import { AlertProvider } from './context/AlertContext';

function App() {
  return (
    <AuthProvider>
      <ThemeProvider>
        <AlertProvider>
          <Router>
            <Routes>
              <Route path="/login" element={<Login />} />
              <Route path="/signup" element={<Signup />} />
              <Route path="/forgot-password" element={<ForgotPassword />} />
              <Route path="/reset-password" element={<ResetPassword />} />
              <Route path="/mohallah-manager" element={
                <ProtectedRoute>
                  <MohallahManager />
                </ProtectedRoute>
              } />
              <Route path="/dashboard" element={
                <ProtectedRoute>
                  <Dashboard />
                </ProtectedRoute>
              }>
                <Route index element={<Overview />} />
                <Route path="users" element={<Users />} />
                <Route path="admins" element={<Admins />} />
                <Route path="announcements" element={<Announcements />} />
                <Route path="complaints" element={<Complaints />} />
                <Route path="marketplace" element={<Marketplace />} />
                <Route path="services" element={<Services />} />
                <Route path="local-vibes" element={<LocalVibesModeration />} />
              </Route>
              <Route path="/" element={<Navigate to="/login" replace />} />
            </Routes>
          </Router>
        </AlertProvider>
      </ThemeProvider>
    </AuthProvider>
  );
}

export default App;
