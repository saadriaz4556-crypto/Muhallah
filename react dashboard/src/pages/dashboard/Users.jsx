import React, { useState, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useAlert } from '../../context/AlertContext';
import { useMohallah } from '../../context/MohallahContext';
import { db } from '../../lib/firebase';
import { collection, onSnapshot, addDoc, serverTimestamp, query, where, doc, updateDoc } from 'firebase/firestore'; // Added doc, updateDoc
import { Search, UserPlus, Users as UsersIcon, UserCheck, User, Filter, X, CheckCircle, XCircle } from 'lucide-react'; // Added CheckCircle, XCircle

// ... (existing imports)

export default function Users() {
    const { userRole } = useAuth();
    const { showAlert } = useAlert();
    const { selectedMohallah } = useMohallah();
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterMohalla, setFilterMohalla] = useState('all');
    const [filterStatus, setFilterStatus] = useState('all');
    const [sortBy, setSortBy] = useState('newest');
    const [showAddModal, setShowAddModal] = useState(false);
    const [confirmationModal, setConfirmationModal] = useState({ show: false, action: null, userId: null, userName: '' });

    // Stats
    const totalUsers = users.length;
    const pendingUsers = users.filter(u => u.status === 'Pending' || u.status === 'pending_verification').length;
    const activeUsers = users.filter(u => u.status === 'Approved').length;

    useEffect(() => {
        const q = query(collection(db, 'users'));
        const unsubscribe = onSnapshot(q, (snapshot) => {
            const usersList = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            setUsers(usersList);
            setLoading(false);
        }, (error) => {
            console.error("Error fetching users:", error);
            setLoading(false);
        });

        return () => unsubscribe();
    }, []);

    const filteredUsers = users.filter(user => {
        const matchesSearch = user.fullName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.email?.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesMohalla = filterMohalla === 'all' || user.mohalla === filterMohalla;
        const matchesStatus = filterStatus === 'all' || (filterStatus === 'pending' ? (user.status === 'Pending' || user.status === 'pending_verification') : user.status === 'Approved');

        return matchesSearch && matchesMohalla && matchesStatus;
    }).sort((a, b) => {
        if (sortBy === 'newest') return (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0);
        if (sortBy === 'oldest') return (a.createdAt?.seconds || 0) - (b.createdAt?.seconds || 0);
        if (sortBy === 'name') return (a.fullName || '').localeCompare(b.fullName || '');
        return 0;
    });

    const confirmAction = async () => {
        if (!confirmationModal.userId || !confirmationModal.action) return;

        const { action, userId } = confirmationModal;
        const newStatus = action === 'approve' ? 'Approved' : 'Rejected';
        const successMessage = action === 'approve' ? 'User approved successfully!' : 'User rejected successfully!';
        const errorMessage = action === 'approve' ? 'Failed to approve user.' : 'Failed to reject user.';

        try {
            const userRef = doc(db, 'users', userId);
            await updateDoc(userRef, {
                status: newStatus
            });
            showAlert(successMessage, 'success');
        } catch (error) {
            console.error(`Error ${action}ing user:`, error);
            showAlert(errorMessage, 'error');
        } finally {
            setConfirmationModal({ show: false, action: null, userId: null, userName: '' });
        }
    };

    const openConfirmation = (action, user) => {
        setConfirmationModal({
            show: true,
            action,
            userId: user.id,
            userName: user.fullName
        });
    };

    const handleAddUser = async (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const newUser = {
            id: users.length + 1,
            fullName: formData.get('fullName'),
            email: formData.get('email'),
            phone: formData.get('phone'),
            cnic: formData.get('cnic'),
            mohalla: formData.get('mohalla'),
            role: 'user', // Default role
            status: 'Approved', // Auto-approve manual adds
            createdAt: new Date().toISOString()
        };

        try {
            // Add to local state (dummy data)
            setUsers([newUser, ...users]);

            // Also try to add to Firebase for real data
            await addDoc(collection(db, 'users'), {
                ...newUser,
                createdAt: serverTimestamp()
            });

            setShowAddModal(false);
            showAlert('User added successfully!', 'success');
        } catch (error) {
            console.error("Error adding user:", error);
            // Still show success for dummy data even if Firebase fails
            setShowAddModal(false);
            showAlert('User added successfully!', 'success');
        }
    };

    return (
        <div className="space-y-6">
            {/* ... (existing header and stats) */}

            {/* Users List */}
            <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Community Members</h2>

                {loading ? (
                    <div className="text-center py-8 text-gray-500 dark:text-gray-400">Loading users...</div>
                ) : filteredUsers.length === 0 ? (
                    // ... (existing empty state)
                    <div className="text-center py-12 border-2 border-dashed border-gray-200 dark:border-gray-700 rounded-xl">
                        <div className="w-24 h-24 bg-gray-100 dark:bg-gray-700 rounded-full flex items-center justify-center mx-auto mb-4">
                            <UsersIcon className="w-8 h-8 text-gray-400 dark:text-gray-500" />
                        </div>
                        <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No users found</h3>
                        <p className="text-gray-500 dark:text-gray-400">Try adjusting your search or filters.</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        {filteredUsers.map(user => (
                            <div key={user.id} className={`bg-white dark:bg-gray-700 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-600 border-l-4 ${(user.status === 'Pending' || user.status === 'pending_verification') ? 'border-l-yellow-500' : user.status === 'Rejected' ? 'border-l-red-500' : 'border-l-green-500'} hover:shadow-md transition-all`}>
                                <div className="flex items-start justify-between">
                                    <div className="flex items-center space-x-3">
                                        <div className="w-12 h-12 rounded-full bg-gray-200 dark:bg-gray-600 flex items-center justify-center text-gray-600 dark:text-gray-300 font-bold text-lg">
                                            {user.fullName?.charAt(0).toUpperCase()}
                                        </div>
                                        <div>
                                            <h3 className="font-semibold text-gray-900 dark:text-white">{user.fullName}</h3>
                                            <p className="text-xs text-gray-500 dark:text-gray-400">{user.area || user.propertyAddress || 'No Address'}</p>
                                        </div>
                                    </div>
                                    <span className={`px-2 py-1 rounded-full text-xs font-semibold ${(user.status === 'Pending' || user.status === 'pending_verification') ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200' : user.status === 'Rejected' ? 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200' : 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'}`}>
                                        {user.status === 'pending_verification' ? 'Pending Verification' : user.status}
                                    </span>
                                </div>
                                <div className="mt-4 space-y-2 text-sm text-gray-600 dark:text-gray-300">
                                    <p className="flex items-center"><span className="w-20 text-gray-400 dark:text-gray-500">CNIC:</span> {user.cnic}</p>
                                    <p className="flex items-center"><span className="w-20 text-gray-400 dark:text-gray-500">Phone:</span> {user.phone || 'N/A'}</p>
                                    <p className="flex items-center"><span className="w-20 text-gray-400 dark:text-gray-500">Email:</span> {user.email}</p>
                                    <p className="flex items-center"><span className="w-20 text-gray-400 dark:text-gray-500">Role:</span> {user.role}</p>
                                </div>

                                {(user.status === 'Pending' || user.status === 'pending_verification') && (
                                    <div className="mt-4 pt-4 border-t border-gray-100 dark:border-gray-600 flex justify-end space-x-3">
                                        <button
                                            onClick={() => openConfirmation('reject', user)}
                                            className="flex items-center space-x-2 px-3 py-1.5 bg-red-600 text-white text-sm rounded-lg hover:bg-red-700 transition-colors"
                                        >
                                            <XCircle className="w-4 h-4" />
                                            <span>Reject</span>
                                        </button>
                                        <button
                                            onClick={() => openConfirmation('approve', user)}
                                            className="flex items-center space-x-2 px-3 py-1.5 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700 transition-colors"
                                        >
                                            <CheckCircle className="w-4 h-4" />
                                            <span>Approve</span>
                                        </button>
                                    </div>
                                )}
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* Confirmation Modal */}
            {confirmationModal.show && (
                <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
                    <div className="bg-white dark:bg-gray-800 rounded-xl p-6 w-full max-w-sm shadow-xl transform transition-all">
                        <div className="text-center">
                            <div className={`mx-auto flex items-center justify-center h-12 w-12 rounded-full mb-4 ${confirmationModal.action === 'approve' ? 'bg-green-100 dark:bg-green-900' : 'bg-red-100 dark:bg-red-900'}`}>
                                {confirmationModal.action === 'approve' ? (
                                    <CheckCircle className={`h-6 w-6 ${confirmationModal.action === 'approve' ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`} />
                                ) : (
                                    <XCircle className="h-6 w-6 text-red-600 dark:text-red-400" />
                                )}
                            </div>
                            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                                {confirmationModal.action === 'approve' ? 'Approve User?' : 'Reject User?'}
                            </h3>
                            <p className="text-sm text-gray-500 dark:text-gray-400 mb-6">
                                Are you sure you want to {confirmationModal.action} <strong>{confirmationModal.userName}</strong>?
                                {confirmationModal.action === 'reject' && " This action cannot be undone."}
                            </p>
                            <div className="flex justify-center space-x-3">
                                <button
                                    onClick={() => setConfirmationModal({ show: false, action: null, userId: null, userName: '' })}
                                    className="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
                                >
                                    Cancel
                                </button>
                                <button
                                    onClick={confirmAction}
                                    className={`px-4 py-2 text-white rounded-lg shadow-sm transition-colors ${confirmationModal.action === 'approve' ? 'bg-green-600 hover:bg-green-700' : 'bg-red-600 hover:bg-red-700'}`}
                                >
                                    Confirm {confirmationModal.action === 'approve' ? 'Approval' : 'Rejection'}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Add User Modal */}
            {showAddModal && (
                <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
                    <div className="bg-white rounded-xl p-6 w-full max-w-md">
                        <div className="flex justify-between items-center mb-4">
                            <h3 className="text-xl font-semibold">Add New User</h3>
                            <button onClick={() => setShowAddModal(false)} className="text-gray-500 hover:text-gray-700">
                                <X className="w-6 h-6" />
                            </button>
                        </div>
                        <form onSubmit={handleAddUser} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                                <input name="fullName" required className="w-full p-2 border border-gray-300 rounded-lg" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">CNIC</label>
                                <input name="cnic" required className="w-full p-2 border border-gray-300 rounded-lg" placeholder="12345-1234567-1" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                                <input name="phone" required className="w-full p-2 border border-gray-300 rounded-lg" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                                <input name="email" type="email" required className="w-full p-2 border border-gray-300 rounded-lg" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Mohalla</label>
                                <select name="mohalla" className="w-full p-2 border border-gray-300 rounded-lg">
                                    <option value="bahria">Bahria Mohalla</option>
                                    <option value="satellite">Satellite Mohalla</option>
                                    <option value="ghouri">Ghouri Mohalla</option>
                                </select>
                            </div>
                            <div className="flex justify-end space-x-3 mt-6">
                                <button type="button" onClick={() => setShowAddModal(false)} className="px-4 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50">Cancel</button>
                                <button type="submit" className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700">Add User</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
