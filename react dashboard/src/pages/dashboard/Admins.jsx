import React, { useState, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useAlert } from '../../context/AlertContext';
import { db } from '../../lib/firebase';
import { collection, onSnapshot, query, where, updateDoc, doc, deleteDoc } from 'firebase/firestore';
import { Shield, ShieldAlert, ShieldCheck, Check, X, MapPin } from 'lucide-react';

export default function Admins() {
    const { userRole, currentUser } = useAuth();
    const { showAlert, showConfirm } = useAlert();
    const [admins, setAdmins] = useState([]);
    const [adminRequests, setAdminRequests] = useState([]);
    const [mohallahs, setMohallahs] = useState([]);
    const [loading, setLoading] = useState(true);

    // Assignment Modal State
    const [assignModalOpen, setAssignModalOpen] = useState(false);
    const [selectedAdmin, setSelectedAdmin] = useState(null);
    const [selectedMohallahId, setSelectedMohallahId] = useState('');

    useEffect(() => {
        // Fetch all admins
        const unsubAdmins = onSnapshot(
            collection(db, 'admins'),
            (snapshot) => {
                const list = [];
                snapshot.forEach(doc => {
                    list.push({ id: doc.id, ...doc.data() });
                });
                setAdmins(list);
                setLoading(false);
            },
            (error) => {
                console.error("Error fetching admins:", error);
                setLoading(false);
            }
        );

        // Fetch Mohallahs
        const unsubMohallahs = onSnapshot(
            collection(db, 'mohallahs'),
            (snapshot) => {
                const list = [];
                snapshot.forEach(doc => {
                    const data = doc.data();
                    if (data.type === 'Mohallah' || !data.type) {
                        list.push({ id: doc.id, ...data });
                    }
                });
                setMohallahs(list);
            },
            (error) => {
                console.error("Error fetching mohallahs:", error);
            }
        );

        // Fetch pending requests (Platform Admin & Super Admin)
        let unsubRequests = () => { };

        if (userRole === 'platform-admin') {
            try {
                // Platform Admin sees ALL pending requests
                const q = query(collection(db, 'admins'), where('isApproved', '==', false));
                unsubRequests = onSnapshot(
                    q,
                    (snapshot) => {
                        const list = [];
                        snapshot.forEach(doc => {
                            list.push({ id: doc.id, ...doc.data() });
                        });
                        setAdminRequests(list);
                    },
                    (error) => {
                        console.error("Error fetching admin requests:", error);
                        setAdminRequests([]);
                    }
                );
            } catch (error) {
                console.error("Error setting up admin requests query:", error);
            }
        }

        return () => {
            unsubAdmins();
            unsubRequests();
            unsubMohallahs();
        };
    }, [userRole]);

    const handleApprove = async (id, name, role) => {
        const confirmed = await showConfirm(`Approve ${name} as ${role}?`, "success");
        if (confirmed) {
            try {
                await updateDoc(doc(db, 'admins', id), { isApproved: true });
                showAlert(`${name} approved as ${role}`, "success");
            } catch (err) {
                console.error("Error approving:", err);
                showAlert("Failed to approve.", "error");
            }
        }
    };

    const handleReject = async (id, name) => {
        const confirmed = await showConfirm(`Reject request from ${name}?`, "warning");
        if (confirmed) {
            try {
                await deleteDoc(doc(db, 'admins', id));
                showAlert(`Request from ${name} rejected`, "info");
            } catch (err) {
                console.error("Error rejecting:", err);
                showAlert("Failed to reject.", "error");
            }
        }
    };

    const openAssignModal = (admin) => {
        setSelectedAdmin(admin);
        setSelectedMohallahId(admin.assignedMohallahId || '');
        setAssignModalOpen(true);
    };

    const saveAssignment = async () => {
        if (!selectedAdmin) return;

        const mohallah = mohallahs.find(m => m.id === selectedMohallahId);
        const mohallahName = mohallah ? mohallah.name : null;
        const mohallahId = mohallah ? mohallah.id : null;

        try {
            await updateDoc(doc(db, 'admins', selectedAdmin.id), {
                assignedMohallahId: mohallahId,
                assignedMohallahName: mohallahName
            });
            showAlert(`Assigned ${mohallahName || 'nothing'} to ${selectedAdmin.fullName}`, "success");
            setAssignModalOpen(false);
        } catch (err) {
            console.error("Error assigning:", err);
            showAlert("Failed to assign Mohallah.", "error");
        }
    };

    const handleDeleteAdmin = async (admin) => {
        const confirmed = await showConfirm(`Are you sure you want to delete ${admin.fullName}?`, "warning");
        if (confirmed) {
            try {
                await deleteDoc(doc(db, 'admins', admin.id));
                showAlert(`${admin.fullName} has been deleted.`, "success");
            } catch (err) {
                console.error("Error deleting admin:", err);
                showAlert("Failed to delete admin.", "error");
            }
        }
    };

    // Filter admins
    const superAdmins = admins.filter(a => a.role === 'super-admin' && a.isApproved);
    const subAdmins = admins.filter(a => a.role === 'sub-admin' && a.isApproved);
    const moderators = admins.filter(a => a.role === 'moderator' && a.isApproved);

    // Filter available Mohallahs for assignment based on role
    const getAssignableMohallahs = () => {
        if (userRole === 'platform-admin') {
            return mohallahs;
        } else if (userRole === 'super-admin' && currentUser?.assignedMohallahId) {
            return mohallahs.filter(m => m.id === currentUser.assignedMohallahId);
        }
        return [];
    };

    const assignableMohallahs = getAssignableMohallahs();

    // Check if current user can assign to the target admin
    const canAssign = (targetRole) => {
        if (userRole === 'platform-admin' && targetRole === 'super-admin') return true;
        if (userRole === 'super-admin' && (targetRole === 'sub-admin' || targetRole === 'moderator')) return true;
        return false;
    };

    return (
        <div className="space-y-6">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Admin Management</h1>
                    <p className="text-gray-600 dark:text-gray-400 mt-1">Manage admin roles and assign Mohallahs</p>
                </div>
            </div>

            {/* Stats Cards (Platform Admin Only) */}
            {userRole === 'platform-admin' && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div className="bg-gradient-to-r from-purple-500 to-purple-600 rounded-xl p-6 text-white">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-purple-100 text-sm">Total Applications</p>
                                <p className="text-2xl font-bold mt-1">{adminRequests.length + admins.filter(a => a.isApproved).length}</p>
                            </div>
                            <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                                <Shield className="w-6 h-6" />
                            </div>
                        </div>
                    </div>

                    <div className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl p-6 text-white">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-blue-100 text-sm">Pending Review</p>
                                <p className="text-2xl font-bold mt-1">{adminRequests.length}</p>
                            </div>
                            <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                                <ShieldAlert className="w-6 h-6" />
                            </div>
                        </div>
                    </div>

                    <div className="bg-gradient-to-r from-green-500 to-green-600 rounded-xl p-6 text-white">
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-green-100 text-sm">Reviewed</p>
                                <p className="text-2xl font-bold mt-1">{admins.filter(a => a.isApproved).length}</p>
                            </div>
                            <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                                <ShieldCheck className="w-6 h-6" />
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Admin Requests (Platform Admin Only) */}
            {userRole === 'platform-admin' && (
                <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-xl p-6">
                    <div className="flex items-center justify-between mb-4">
                        <div>
                            <h2 className="text-xl font-bold text-yellow-800 dark:text-yellow-200 flex items-center gap-2">
                                <ShieldAlert className="w-6 h-6" />
                                Pending Admin Requests
                            </h2>
                            <p className="text-yellow-700 dark:text-yellow-300 text-sm mt-1">Review applications for Super Admins, Sub-Admins, and Moderators.</p>
                        </div>
                        <span className="bg-yellow-200 dark:bg-yellow-800 text-yellow-800 dark:text-yellow-200 text-xs font-bold px-3 py-1 rounded-full">
                            {adminRequests.length} Pending
                        </span>
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                        {adminRequests.length === 0 ? (
                            <div className="col-span-2 text-center py-8 text-gray-500 dark:text-gray-400 bg-white dark:bg-gray-800 rounded-lg border border-yellow-100 dark:border-yellow-900">
                                <ShieldCheck className="w-8 h-8 mx-auto mb-2 text-green-500" />
                                <p>No pending applications. All caught up!</p>
                            </div>
                        ) : (
                            adminRequests.map(req => (
                                <div key={req.id} className="bg-white dark:bg-gray-800 rounded-lg p-5 shadow-sm border-l-4 border-yellow-400 dark:border-yellow-500 flex flex-col justify-between">
                                    <div>
                                        <div className="flex justify-between items-start mb-3">
                                            <div className="flex items-center space-x-3">
                                                <div className="w-10 h-10 rounded-full bg-purple-100 dark:bg-purple-900 flex items-center justify-center text-purple-600 dark:text-purple-300 font-bold text-lg">
                                                    {req.fullName?.charAt(0).toUpperCase()}
                                                </div>
                                                <div>
                                                    <h3 className="font-bold text-gray-900 dark:text-white">{req.fullName}</h3>
                                                    <p className="text-xs text-gray-500 dark:text-gray-400">{req.email}</p>
                                                </div>
                                            </div>
                                            <span className="bg-purple-100 dark:bg-purple-900 text-purple-800 dark:text-purple-200 text-xs font-bold px-2 py-1 rounded">
                                                {req.role}
                                            </span>
                                        </div>
                                        <div className="text-sm text-gray-600 dark:text-gray-300 mb-4">
                                            <p><strong>Mohalla:</strong> {req.mohalla}</p>
                                            <p><strong>CNIC:</strong> {req.cnic}</p>
                                        </div>
                                    </div>
                                    <div className="flex justify-end space-x-3 pt-4 border-t border-gray-100 dark:border-gray-700">
                                        <button onClick={() => handleApprove(req.id, req.fullName, req.role)} className="flex items-center space-x-1 px-3 py-1.5 bg-green-500 text-white rounded hover:bg-green-600 text-sm">
                                            <Check className="w-4 h-4" /> <span>Accept</span>
                                        </button>
                                        <button onClick={() => handleReject(req.id, req.fullName)} className="flex items-center space-x-1 px-3 py-1.5 bg-red-500 text-white rounded hover:bg-red-600 text-sm">
                                            <X className="w-4 h-4" /> <span>Reject</span>
                                        </button>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>
            )}

            {/* Active Admins Lists */}
            <div className="space-y-6">
                {userRole === 'platform-admin' && (
                    <AdminGroup
                        title="Super Admins"
                        list={superAdmins}
                        onAssign={openAssignModal}
                        canAssign={canAssign('super-admin')}
                        onDelete={handleDeleteAdmin}
                    />
                )}

                {userRole === 'super-admin' && (
                    <>
                        <AdminGroup
                            title="Sub Admins"
                            list={subAdmins}
                            onAssign={openAssignModal}
                            canAssign={canAssign('sub-admin')}
                            onDelete={handleDeleteAdmin}
                        />
                        <AdminGroup
                            title="Moderators"
                            list={moderators}
                            onAssign={openAssignModal}
                            canAssign={canAssign('moderator')}
                            onDelete={handleDeleteAdmin}
                        />
                    </>
                )}
            </div>

            {/* Assignment Modal */}
            {assignModalOpen && selectedAdmin && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[2000] flex items-center justify-center p-4">
                    <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl shadow-2xl w-full max-w-md border border-gray-100 dark:border-gray-700">
                        <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-4">
                            Assign Mohallah to {selectedAdmin.fullName}
                        </h3>

                        <div className="mb-6">
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Select Mohallah</label>
                            {assignableMohallahs.length === 0 ? (
                                <p className="text-red-500 text-sm">No Mohallahs available to assign.</p>
                            ) : (
                                <select
                                    value={selectedMohallahId}
                                    onChange={(e) => setSelectedMohallahId(e.target.value)}
                                    className="w-full p-3 border border-gray-300 dark:border-gray-600 rounded-xl bg-white dark:bg-gray-700 dark:text-white focus:ring-2 focus:ring-purple-500"
                                >
                                    <option value="">-- No Assignment --</option>
                                    {assignableMohallahs.map(m => (
                                        <option key={m.id} value={m.id}>{m.name}</option>
                                    ))}
                                </select>
                            )}
                            {userRole === 'super-admin' && (
                                <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
                                    You can only assign your own Mohallah ({currentUser?.assignedMohallahName}).
                                </p>
                            )}
                        </div>

                        <div className="flex justify-end gap-3">
                            <button
                                onClick={() => setAssignModalOpen(false)}
                                className="px-4 py-2 text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={saveAssignment}
                                className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700"
                            >
                                Save Assignment
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

function AdminGroup({ title, list, onAssign, canAssign, onDelete }) {
    return (
        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">{title}</h2>
            {list.length === 0 ? (
                <div className="text-center py-4 text-gray-500 dark:text-gray-400">No {title.toLowerCase()} found.</div>
            ) : (
                <div className="space-y-4">
                    {list.map(admin => (
                        <div key={admin.id} className="flex flex-col md:flex-row md:items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 gap-4">
                            <div className="flex items-start space-x-4">
                                <div className="w-12 h-12 rounded-full bg-gray-200 dark:bg-gray-600 flex-shrink-0 flex items-center justify-center text-gray-600 dark:text-gray-300 font-bold text-lg">
                                    {admin.fullName?.charAt(0).toUpperCase()}
                                </div>
                                <div>
                                    <h4 className="font-bold text-gray-900 dark:text-white text-lg">{admin.fullName}</h4>
                                    <div className="text-sm text-gray-500 dark:text-gray-400 space-y-1 mt-1">
                                        <p className="flex items-center gap-2">📞 {admin.phone || 'N/A'}</p>
                                        <p className="flex items-center gap-2">📍 {admin.address || 'No Address'}</p>
                                        <div className="pt-1">
                                            {admin.assignedMohallahName ? (
                                                <span className="inline-flex items-center gap-1 text-purple-600 dark:text-purple-400 font-medium bg-purple-50 dark:bg-purple-900/20 px-2 py-0.5 rounded text-xs">
                                                    <MapPin size={12} /> {admin.assignedMohallahName}
                                                </span>
                                            ) : (
                                                <span className="text-gray-400 italic text-xs">No Mohallah Assigned</span>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="flex flex-col items-end gap-3">
                                <div className="flex items-center gap-2">
                                    {canAssign && (
                                        <button
                                            onClick={() => onAssign(admin)}
                                            className="px-4 py-2 text-sm font-medium bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors shadow-sm"
                                        >
                                            Assign Mohallah
                                        </button>
                                    )}
                                    {onDelete && (
                                        <button
                                            onClick={() => onDelete(admin)}
                                            className="p-2 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                                            title="Delete Admin"
                                        >
                                            <X size={20} />
                                        </button>
                                    )}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
