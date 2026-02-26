import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useAlert } from '../context/AlertContext';
import '../styles/login.css';

import { storage, db } from '../lib/firebase';
// import { ref, uploadBytes, getDownloadURL } from 'firebase/storage'; // Removed Firebase Storage
import { collection, getDocs, setDoc, doc } from 'firebase/firestore';

export default function Signup() {
    const [formData, setFormData] = useState({
        fullName: '',
        phone: '',
        email: '',
        cnic: '',
        role: 'super-admin',
        ownershipType: '',
        address: '',
        mohallahName: '', // Added field
        password: '',
        confirmPassword: '',
        terms: false,
        cnicFile: null,
        utilityBillFile: null,
        policeCertFile: null
    });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [showTermsModal, setShowTermsModal] = useState(false);
    const { signup } = useAuth();
    const { showAlert } = useAlert();
    const navigate = useNavigate();

    // Cloudinary Configuration
    const CLOUDINARY_CLOUD_NAME = "dheaiajgv";
    const CLOUDINARY_UPLOAD_PRESET = "digitalmohallah";

    const handleChange = (e) => {
        const { id, value, type, checked } = e.target;
        setFormData(prev => ({
            ...prev,
            [id]: type === 'checkbox' ? checked : value
        }));
    };

    const handleCnicChange = (e) => {
        let v = e.target.value.replace(/\D/g, '');
        if (v.length > 13) v = v.substring(0, 13);
        if (v.length > 5) v = v.substring(0, 5) + '-' + v.substring(5);
        if (v.length > 13) v = v.substring(0, 13) + '-' + v.substring(13);
        setFormData(prev => ({ ...prev, cnic: v }));
    };

    const handleFileChange = (e, field) => {
        const file = e.target.files[0];
        if (file) {
            setFormData(prev => ({ ...prev, [field]: file }));
        }
    };

    // const cnicToEmail = (cnic) => cnic.replace(/-/g, '') + "@digitalmuhalla.com"; // Removed synthetic email generation

    const uploadToCloudinary = async (file) => {
        if (!file) return null;

        const formData = new FormData();
        formData.append("file", file);
        formData.append("upload_preset", CLOUDINARY_UPLOAD_PRESET);
        formData.append("folder", "admin_docs"); // Optional: Organize in a folder

        try {
            const res = await fetch(
                `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/image/upload`, // Use 'auto' or 'image'/'raw' depending on file type if needed, 'image' usually works for PDFs too in some configs, but 'auto' is safer
                {
                    method: "POST",
                    body: formData,
                }
            );

            if (!res.ok) {
                const errorData = await res.json();
                throw new Error(errorData.error?.message || "Image upload failed");
            }

            const data = await res.json();
            return data.secure_url;
        } catch (err) {
            console.error("Cloudinary Upload Error:", err);
            throw new Error("Failed to upload document. Please try again.");
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (formData.password !== formData.confirmPassword) {
            setError('Passwords do not match');
            return;
        }

        if (CLOUDINARY_CLOUD_NAME === "YOUR_CLOUD_NAME" || CLOUDINARY_UPLOAD_PRESET === "YOUR_UPLOAD_PRESET") {
            setError('System Error: Cloudinary credentials not configured. Please contact admin.');
            return;
        }

        setLoading(true);
        try {
            // Use real email for authentication
            await signup(formData.email, formData.password, {
                fullName: formData.fullName,
                phone: formData.phone,
                email: formData.email, // Contact email
                cnic: formData.cnic,
                role: formData.role,
                ownershipType: formData.ownershipType,
                address: formData.address,
                mohalla: formData.mohallahName, // Save Mohallah Name
                cnicUrl,
                utilityBillUrl,
                policeCertUrl
            });

            // Create CNIC to Email mapping
            await setDoc(doc(db, 'cnic_email_map', formData.cnic), {
                email: formData.email
            });
            await showAlert('Application submitted! Wait for approval.', 'success');
            navigate('/login');
        } catch (err) {
            console.error(err);
            setError(err.message);
        } finally {
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
                            <button className="toggle-btn" onClick={() => navigate('/login')}>Log In</button>
                            <button className="toggle-btn active">Sign Up</button>
                        </div>
                    </div>

                    <form className="auth-form active-form" onSubmit={handleSubmit}>
                        <div className="header-text">
                            <h2>New Application</h2>
                            <p>Apply for an admin role. Verification required.</p>
                        </div>

                        <div className="input-row">
                            <div className="input-group">
                                <label>Full Name</label>
                                <input type="text" id="fullName" className="simple-input" placeholder="e.g. Ali Khan" value={formData.fullName} onChange={handleChange} required />
                            </div>
                            <div className="input-group">
                                <label>Phone</label>
                                <input type="tel" id="phone" className="simple-input" placeholder="0300-1234567" value={formData.phone} onChange={handleChange} required />
                            </div>
                        </div>

                        <div className="input-group">
                            <label>Email Address</label>
                            <div className="input-wrapper">
                                <input type="email" id="email" placeholder="your.email@example.com" value={formData.email} onChange={handleChange} required />
                                <span className="icon">📧</span>
                            </div>
                        </div>

                        <div className="input-group">
                            <label>CNIC</label>
                            <div className="input-wrapper">
                                <input type="text" id="cnic" placeholder="XXXXX-XXXXXXX-X" value={formData.cnic} onChange={handleCnicChange} required />
                                <span className="icon">🆔</span>
                            </div>
                        </div>

                        <div className="input-group">
                            <label htmlFor="role">Applying For</label>
                            <div className="input-wrapper">
                                <select id="role" value={formData.role} onChange={handleChange}>
                                    <option value="super-admin">⚡ Super Admin</option>
                                    <option value="sub-admin">👔 Sub-Admin</option>
                                    <option value="moderator">🔍 Moderator</option>
                                </select>
                            </div>
                        </div>

                        <div className="input-group">
                            <label htmlFor="ownershipType">Residence Status</label>
                            <div className="input-wrapper">
                                <select id="ownershipType" value={formData.ownershipType} onChange={handleChange} required>
                                    <option value="" disabled>Select Ownership</option>
                                    <option value="owner">🏠 Owner</option>
                                    <option value="rental">🔑 Rental / Tenant</option>
                                </select>
                            </div>
                        </div>

                        {/* File Uploads */}
                        <div className="upload-section">
                            <label className="file-box">
                                <input type="file" accept="image/*,application/pdf" onChange={(e) => handleFileChange(e, 'cnicFile')} />
                                <span className="box-icon">🆔</span>
                                <div className="box-info">
                                    <span>CNIC (Front/Back)</span>
                                    <small>{formData.cnicFile ? formData.cnicFile.name : 'Upload Images/PDF'}</small>
                                </div>
                            </label>
                            <label className="file-box">
                                <input type="file" accept="image/*,application/pdf" onChange={(e) => handleFileChange(e, 'utilityBillFile')} />
                                <span className="box-icon">⚡</span>
                                <div className="box-info">
                                    <span>Utility Bill</span>
                                    <small>{formData.utilityBillFile ? formData.utilityBillFile.name : 'Upload Verification'}</small>
                                </div>
                            </label>
                            <label className="file-box">
                                <input type="file" accept="image/*,application/pdf" onChange={(e) => handleFileChange(e, 'policeCertFile')} />
                                <span className="box-icon">👮</span>
                                <div className="box-info">
                                    <span>Police Cert.</span>
                                    <small>{formData.policeCertFile ? formData.policeCertFile.name : 'Upload Document'}</small>
                                </div>
                            </label>
                        </div>

                        <div className="input-group">
                            <label>Mohallah / Area Name</label>
                            <input type="text" id="mohallahName" className="simple-input" placeholder="e.g. Bahria Phase 1" value={formData.mohallahName} onChange={handleChange} required />
                        </div>

                        <div className="input-group">
                            <label>Residential Address</label>
                            <input type="text" id="address" className="simple-input" placeholder="Street, Sector, City" value={formData.address} onChange={handleChange} required />
                        </div>

                        <div className="input-row">
                            <div className="input-group">
                                <label>Password</label>
                                <input type="password" id="password" className="simple-input" placeholder="Min 8 chars" value={formData.password} onChange={handleChange} required />
                            </div>
                            <div className="input-group">
                                <label>Confirm</label>
                                <input type="password" id="confirmPassword" className="simple-input" placeholder="Repeat" value={formData.confirmPassword} onChange={handleChange} required />
                            </div>
                        </div>

                        <div className="actions">
                            <label className="checkbox-container">
                                <input type="checkbox" id="terms" checked={formData.terms} onChange={handleChange} required />
                                <span className="checkmark"></span>
                                I agree to the{' '}
                                <button
                                    type="button"
                                    onClick={() => setShowTermsModal(true)}
                                    style={{
                                        color: '#8b5cf6',
                                        textDecoration: 'underline',
                                        background: 'none',
                                        border: 'none',
                                        cursor: 'pointer',
                                        padding: 0,
                                        font: 'inherit'
                                    }}
                                >
                                    Terms and Conditions
                                </button>
                            </label>
                        </div>

                        <button type="submit" className="cta-button" disabled={loading}>
                            {loading ? 'Processing...' : 'Submit Application'}
                        </button>

                        {error && <div className="submit-error" style={{ display: 'block' }}>{error}</div>}
                    </form>

                    <div className="footer-copy">
                        &copy; 2025 Digital Muhalla. Secure Admin Portal.
                    </div>
                </div>
            </div>

            {/* Terms and Conditions Modal */}
            {showTermsModal && (
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
                    onClick={() => setShowTermsModal(false)}
                >
                    <div
                        style={{
                            backgroundColor: 'white',
                            borderRadius: '16px',
                            maxWidth: '700px',
                            width: '100%',
                            maxHeight: '85vh',
                            overflow: 'auto',
                            padding: '32px',
                            boxShadow: '0 20px 60px rgba(0,0,0,0.3)'
                        }}
                        onClick={(e) => e.stopPropagation()}
                    >
                        <div style={{ marginBottom: '24px' }}>
                            <h2 style={{ fontSize: '28px', fontWeight: 'bold', color: '#1f2937', marginBottom: '8px' }}>
                                Terms and Conditions
                            </h2>
                            <p style={{ color: '#6b7280', fontSize: '14px' }}>
                                Last updated: December 2025
                            </p>
                        </div>

                        <div style={{ color: '#374151', lineHeight: '1.7', fontSize: '15px' }}>
                            <section style={{ marginBottom: '24px' }}>
                                <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '12px', color: '#111827' }}>
                                    1. Acceptance of Terms
                                </h3>
                                <p>
                                    By applying for an administrator role on the Digital Muhalla platform, you agree to comply with and be bound by these Terms and Conditions. If you do not agree to these terms, please do not submit your application.
                                </p>
                            </section>

                            <section style={{ marginBottom: '24px' }}>
                                <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '12px', color: '#111827' }}>
                                    2. Admin Responsibilities
                                </h3>
                                <p>As an administrator, you agree to:</p>
                                <ul style={{ marginLeft: '24px', marginTop: '8px' }}>
                                    <li>Act with integrity and professionalism in all community interactions</li>
                                    <li>Maintain confidentiality of sensitive user and community information</li>
                                    <li>Respond promptly to community complaints and service requests</li>
                                    <li>Follow all platform guidelines and policies</li>
                                    <li>Not misuse your administrative privileges for personal gain</li>
                                </ul>
                            </section>

                            <section style={{ marginBottom: '24px' }}>
                                <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '12px', color: '#111827' }}>
                                    3. Verification Requirements
                                </h3>
                                <p>
                                    All applicants must provide valid identification documents including CNIC, utility bill, and police clearance certificate. Providing false or misleading information will result in immediate rejection and potential legal action.
                                </p>
                            </section>

                            <section style={{ marginBottom: '24px' }}>
                                <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '12px', color: '#111827' }}>
                                    4. Data Privacy & Protection
                                </h3>
                                <p>
                                    We are committed to protecting your personal information. Your data will be:
                                </p>
                                <ul style={{ marginLeft: '24px', marginTop: '8px' }}>
                                    <li>Stored securely using industry-standard encryption</li>
                                    <li>Used solely for verification and administrative purposes</li>
                                    <li>Never shared with third parties without your consent</li>
                                    <li>Retained only for as long as necessary for legal and operational purposes</li>
                                </ul>
                            </section>

                            <section style={{ marginBottom: '24px' }}>
                                <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '12px', color: '#111827' }}>
                                    5. Code of Conduct
                                </h3>
                                <p>
                                    Administrators must maintain professional conduct at all times. This includes respecting community members, avoiding conflicts of interest, and refraining from discriminatory behavior based on race, religion, gender, or any other protected characteristic.
                                </p>
                            </section>

                            <section style={{ marginBottom: '24px' }}>
                                <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '12px', color: '#111827' }}>
                                    6. Approval Process
                                </h3>
                                <p>
                                    Applications are subject to review and approval by platform administrators. The approval process may take 3-7 business days. We reserve the right to reject any application without providing specific reasons.
                                </p>
                            </section>

                            <section style={{ marginBottom: '24px' }}>
                                <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '12px', color: '#111827' }}>
                                    7. Termination
                                </h3>
                                <p>
                                    We reserve the right to suspend or terminate your administrator access at any time if you violate these terms, abuse your privileges, or engage in conduct deemed harmful to the community or platform.
                                </p>
                            </section>

                            <section style={{ marginBottom: '24px' }}>
                                <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '12px', color: '#111827' }}>
                                    8. Limitation of Liability
                                </h3>
                                <p>
                                    Digital Muhalla and its operators shall not be liable for any direct, indirect, incidental, or consequential damages arising from your use of the platform or performance of administrative duties.
                                </p>
                            </section>

                            <section style={{ marginBottom: '24px' }}>
                                <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '12px', color: '#111827' }}>
                                    9. Changes to Terms
                                </h3>
                                <p>
                                    We may update these Terms and Conditions from time to time. Continued use of the platform after such changes constitutes acceptance of the modified terms.
                                </p>
                            </section>

                            <section>
                                <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '12px', color: '#111827' }}>
                                    10. Contact Information
                                </h3>
                                <p>
                                    For questions or concerns regarding these terms, please contact us at{' '}
                                    <a href="mailto:support@digitalmuhalla.com" style={{ color: '#8b5cf6', textDecoration: 'underline' }}>
                                        support@digitalmuhalla.com
                                    </a>
                                </p>
                            </section>
                        </div>

                        <div style={{ marginTop: '32px', display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                            <button
                                onClick={() => setShowTermsModal(false)}
                                style={{
                                    padding: '12px 24px',
                                    borderRadius: '8px',
                                    border: 'none',
                                    backgroundColor: '#8b5cf6',
                                    color: 'white',
                                    fontSize: '15px',
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
                </div>
            )}
        </div>
    );
}
