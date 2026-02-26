import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { sendPasswordResetEmail } from 'firebase/auth';
import { auth, db } from '../lib/firebase';
import { doc, getDoc } from 'firebase/firestore';
import '../styles/login.css';

export default function ForgotPassword() {
    const [cnic, setCnic] = useState('');
    const [showModal, setShowModal] = useState(false);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const handleCnicChange = (e) => {
        let v = e.target.value.replace(/\D/g, '');
        if (v.length > 13) v = v.substring(0, 13);
        if (v.length > 5) v = v.substring(0, 5) + '-' + v.substring(5);
        if (v.length > 13) v = v.substring(0, 13) + '-' + v.substring(13);
        setCnic(v);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            // Lookup email from CNIC
            const docRef = doc(db, 'cnic_email_map', cnic);
            const docSnap = await getDoc(docRef);

            if (docSnap.exists()) {
                const email = docSnap.data().email;
                const actionCodeSettings = {
                    url: window.location.origin + '/reset-password',
                    handleCodeInApp: true,
                };
                await sendPasswordResetEmail(auth, email, actionCodeSettings);
                setShowModal(true);
            } else {
                setError('CNIC not found. Please check the number or sign up.');
            }
        } catch (err) {
            console.error(err);
            setError('Failed to process request. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    const handleCloseModal = () => {
        setShowModal(false);
        navigate('/login');
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
                        <p className="nav-label">Account Recovery</p>
                        <div className="form-toggle">
                            <Link to="/login" className="toggle-btn">Log In</Link>
                        </div>
                    </div>

                    <form className="auth-form active-form" onSubmit={handleSubmit}>
                        <div className="header-text">
                            <h2>Forgot Password</h2>
                            <p>Enter your CNIC to reset your password.</p>
                        </div>

                        {error && <div className="submit-error" style={{ display: 'block' }}>{error}</div>}

                        <div className="input-group">
                            <label htmlFor="cnic">CNIC Number</label>
                            <div className="input-wrapper">
                                <input
                                    type="text"
                                    id="cnic"
                                    placeholder="XXXXX-XXXXXXX-X"
                                    value={cnic}
                                    onChange={handleCnicChange}
                                    required
                                />
                                <span className="icon">🆔</span>
                            </div>
                        </div>

                        <button type="submit" className="cta-button" disabled={loading}>
                            {loading ? 'Processing...' : 'Send Reset Link'} <span className="arrow">→</span>
                        </button>

                        <div className="actions" style={{ justifyContent: 'center', marginTop: '1rem' }}>
                            <Link to="/login" className="forgot-link" style={{ textDecoration: 'none' }}>Back to Login</Link>
                        </div>
                    </form>

                    <div className="footer-copy">
                        &copy; 2025 Digital Muhalla. Secure Admin Portal.
                    </div>
                </div>
            </div>

            {/* Success Modal */}
            {showModal && (
                <div
                    style={{
                        position: 'fixed',
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        backgroundColor: 'rgba(0, 0, 0, 0.7)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        zIndex: 9999,
                        padding: '20px'
                    }}
                >
                    <div
                        style={{
                            backgroundColor: 'white',
                            borderRadius: '16px',
                            maxWidth: '400px',
                            width: '100%',
                            padding: '32px',
                            textAlign: 'center',
                            boxShadow: '0 20px 60px rgba(0,0,0,0.3)'
                        }}
                    >
                        <div style={{ fontSize: '48px', marginBottom: '16px' }}>📧</div>
                        <h3 style={{ fontSize: '24px', fontWeight: 'bold', color: '#1f2937', marginBottom: '12px' }}>
                            Link Sent!
                        </h3>
                        <p style={{ color: '#6b7280', fontSize: '16px', marginBottom: '24px' }}>
                            A password reset link has been sent to your registered email address. Please check your inbox.
                        </p>
                        <button
                            onClick={handleCloseModal}
                            style={{
                                width: '100%',
                                padding: '12px',
                                borderRadius: '8px',
                                border: 'none',
                                backgroundColor: '#8b5cf6',
                                color: 'white',
                                fontSize: '16px',
                                fontWeight: '600',
                                cursor: 'pointer',
                                transition: 'background-color 0.2s'
                            }}
                            onMouseEnter={(e) => e.target.style.backgroundColor = '#7c3aed'}
                            onMouseLeave={(e) => e.target.style.backgroundColor = '#8b5cf6'}
                        >
                            Close
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}
