import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { verifyPasswordResetCode, confirmPasswordReset } from 'firebase/auth';
import { auth } from '../lib/firebase';
import '../styles/login.css';

export default function ResetPassword() {
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [validCode, setValidCode] = useState(false);
    const [searchParams] = useSearchParams();
    const navigate = useNavigate();

    // Get the action code from the URL
    const oobCode = searchParams.get('oobCode');

    useEffect(() => {
        if (!oobCode) {
            setError('Invalid or missing reset code.');
            return;
        }

        // Verify the password reset code
        verifyPasswordResetCode(auth, oobCode)
            .then((email) => {
                setValidCode(true);
            })
            .catch((error) => {
                console.error(error);
                setError('Invalid or expired reset code. Please request a new one.');
            });
    }, [oobCode]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage('');
        setError('');

        if (password !== confirmPassword) {
            setError('Passwords do not match');
            return;
        }

        if (password.length < 6) {
            setError('Password must be at least 6 characters');
            return;
        }

        setLoading(true);

        try {
            await confirmPasswordReset(auth, oobCode, password);
            setMessage('Password has been reset successfully! Redirecting to login...');
            setTimeout(() => {
                navigate('/login');
            }, 3000);
        } catch (err) {
            console.error(err);
            setError('Failed to reset password. Please try again.');
            setLoading(false);
        }
    };

    if (!oobCode) {
        return (
            <div className="main-wrapper">
                <div className="form-side" style={{ width: '100%', maxWidth: '100%' }}>
                    <div className="form-container" style={{ textAlign: 'center' }}>
                        <h2>Invalid Link</h2>
                        <p>The password reset link is invalid or missing.</p>
                        <button onClick={() => navigate('/login')} className="cta-button">Go to Login</button>
                    </div>
                </div>
            </div>
        );
    }

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
                    </div>

                    <form className="auth-form active-form" onSubmit={handleSubmit}>
                        <div className="header-text">
                            <h2>Reset Password</h2>
                            <p>Enter your new password below.</p>
                        </div>

                        {message && <div className="submit-success" style={{ display: 'block', color: 'green', marginBottom: '1rem' }}>{message}</div>}
                        {error && <div className="submit-error" style={{ display: 'block' }}>{error}</div>}

                        {!validCode && !error && <p>Verifying link...</p>}

                        {validCode && (
                            <>
                                <div className="input-group">
                                    <label htmlFor="password">New Password</label>
                                    <div className="input-wrapper">
                                        <input
                                            type="password"
                                            id="password"
                                            placeholder="••••••••"
                                            value={password}
                                            onChange={(e) => setPassword(e.target.value)}
                                            required
                                        />
                                        <span className="icon">🔒</span>
                                    </div>
                                </div>

                                <div className="input-group">
                                    <label htmlFor="confirmPassword">Confirm Password</label>
                                    <div className="input-wrapper">
                                        <input
                                            type="password"
                                            id="confirmPassword"
                                            placeholder="••••••••"
                                            value={confirmPassword}
                                            onChange={(e) => setConfirmPassword(e.target.value)}
                                            required
                                        />
                                        <span className="icon">🔒</span>
                                    </div>
                                </div>

                                <button type="submit" className="cta-button" disabled={loading}>
                                    {loading ? 'Resetting...' : 'Reset Password'} <span className="arrow">→</span>
                                </button>
                            </>
                        )}
                    </form>

                    <div className="footer-copy">
                        &copy; 2025 Digital Muhalla. Secure Admin Portal.
                    </div>
                </div>
            </div>
        </div>
    );
}
