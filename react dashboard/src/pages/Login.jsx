import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { db } from '../lib/firebase';
import { doc, getDoc } from 'firebase/firestore';
import '../styles/login.css';

export default function Login() {
    const [cnic, setCnic] = useState('');
    const [password, setPassword] = useState('');
    const [role, setRole] = useState('platform-admin');
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { login, currentUser, logout } = useAuth(); // Added logout
    const navigate = useNavigate();

    const validateCNIC = (cnic) => /^\d{5}-\d{7}-\d{1}$/.test(cnic);

    const handleCnicChange = (e) => {
        let v = e.target.value.replace(/\D/g, '');
        if (v.length > 13) v = v.substring(0, 13);
        if (v.length > 5) v = v.substring(0, 5) + '-' + v.substring(5);
        if (v.length > 13) v = v.substring(0, 13) + '-' + v.substring(13);
        setCnic(v);
    };

    // const cnicToEmail = (cnic) => cnic.replace(/-/g, '') + "@digitalmuhalla.com"; // Removed synthetic email generation

    useEffect(() => {
        if (currentUser) {
            if (currentUser.isApproved) {
                navigate('/dashboard');
            } else {
                // If logged in but not approved, show error and logout
                setError('Your account is pending approval.');
                logout();
            }
        }
    }, [currentUser, navigate, logout]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (!validateCNIC(cnic)) {
            setError('Invalid CNIC format');
            return;
        }
        if (password.length < 6) {
            setError('Password too short');
            return;
        }

        setLoading(true);
        setLoading(true);
        try {
            // Lookup email from CNIC
            const docRef = doc(db, 'cnic_email_map', cnic);
            const docSnap = await getDoc(docRef);

            if (docSnap.exists()) {
                const email = docSnap.data().email;
                await login(email, password);
                // Navigation is handled by useEffect when currentUser updates
            } else {
                setError('CNIC not found. Please sign up.');
                setLoading(false);
            }
        } catch (err) {
            console.error(err);
            setError('Invalid Credentials or Server Error');
            setLoading(false);
        }
    };

    return (
        <div className="main-wrapper">
            <div className="visual-side">
                <div className="visual-content">
                    <img src="/mohalla_illustration.png" alt="Digital Mohalla Community" className="visual-image" />
                    <div className="glass-decoration"></div>
                </div>
            </div>

            <div className="form-side">
                <div className="form-container">
                    <div className="mobile-header">
                        <h2>Digital Muhalla</h2>
                    </div>

                    <div className="nav-header">
                        <p className="nav-label">Welcome to Admin Portal</p>
                        <div className="form-toggle">
                            <button className="toggle-btn active">Log In</button>
                            <button className="toggle-btn" onClick={() => navigate('/signup')}>Sign Up</button>
                        </div>
                    </div>

                    <form className="auth-form active-form" onSubmit={handleSubmit}>
                        <div className="header-text">
                            <h2>Sign in</h2>
                            <p>Enter your credentials to access your dashboard.</p>
                        </div>

                        <div className="input-group">
                            <label htmlFor="cnic">CNIC Number</label>
                            <div className="input-wrapper">
                                <input
                                    type="text"
                                    id="cnic"
                                    placeholder="XXXXX-XXXXXXX-X"
                                    value={cnic}
                                    onChange={handleCnicChange}
                                    maxLength="15"
                                />
                                <span className="icon">🆔</span>
                            </div>
                        </div>

                        <div className="input-group">
                            <label htmlFor="password">Password</label>
                            <div className="input-wrapper">
                                <input
                                    type={showPassword ? "text" : "password"}
                                    id="password"
                                    placeholder="••••••••"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                />
                                <span className="icon">🔒</span>
                                <button
                                    type="button"
                                    className="password-toggle"
                                    onClick={() => setShowPassword(!showPassword)}
                                >
                                    {showPassword ? '👁️' : '🙈'}
                                </button>
                            </div>
                        </div>

                        <div className="actions">
                            <label className="checkbox-container">
                                <input type="checkbox" />
                                <span className="checkmark"></span>
                                Keep me logged in
                            </label>
                            <Link to="/forgot-password" className="forgot-link" style={{ textDecoration: 'none' }}>Forgot Password?</Link>
                        </div>

                        <div className="input-group">
                            <label htmlFor="role">Select Role</label>
                            <div className="input-wrapper">
                                <select id="role" value={role} onChange={(e) => setRole(e.target.value)}>
                                    <option value="platform-admin">👑 Platform Admin</option>
                                    <option value="super-admin">⚡ Super Admin</option>
                                    <option value="sub-admin">👔 Sub-Admin</option>
                                    <option value="moderator">🔍 Moderator</option>
                                </select>
                            </div>
                        </div>

                        <button type="submit" className="cta-button" disabled={loading}>
                            {loading ? 'Verifying...' : 'Sign In'} <span className="arrow">→</span>
                        </button>

                        {error && <div className="submit-error" style={{ display: 'block' }}>{error}</div>}
                    </form>

                    <div className="footer-copy">
                        &copy; 2025 Digital Muhalla. Secure Admin Portal.
                    </div>
                </div>
            </div>
        </div>
    );
}
