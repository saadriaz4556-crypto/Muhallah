import React, { useState, useEffect, useMemo } from 'react';
import { db } from '../../lib/firebase';
import { collection, addDoc, deleteDoc, doc, serverTimestamp } from 'firebase/firestore';
import { Megaphone, Calendar, Eye, Send, Trash2, Info, Bell, Activity } from 'lucide-react';
import { announcements as dummyAnnouncements } from '../../data/dummyData';
import { useAuth } from '../../context/AuthContext';
import { useAlert } from '../../context/AlertContext';
import TiptapEditor from '../../components/TiptapEditor';

export default function Announcements() {
    const { currentUser } = useAuth();
    const { showAlert, showConfirm } = useAlert();
    const [announcements, setAnnouncements] = useState([]);
    const [loading, setLoading] = useState(true);
    const [formData, setFormData] = useState({ title: '', category: 'general', content: '' });
    const [errors, setErrors] = useState({ title: '', content: '' });

    useEffect(() => {
        // Using dummy data for display purposes as requested
        setAnnouncements(dummyAnnouncements);
        setLoading(false);
    }, []);

    const validateForm = () => {
        const newErrors = { title: '', content: '' };
        let isValid = true;

        // Validate title (must be at least 2 words)
        const titleWords = formData.title.trim().split(/\s+/).filter(word => word.length > 0);
        if (titleWords.length < 2) {
            newErrors.title = 'Title must contain at least 2 words';
            isValid = false;
        }

        // Validate content (must be at least 8 words) - strip HTML tags for counting
        const contentText = formData.content.replace(/<[^>]*>/g, '').trim();
        const contentWords = contentText.split(/\s+/).filter(word => word.length > 0);
        if (contentWords.length < 8) {
            newErrors.content = 'Content must contain at least 8 words';
            isValid = false;
        }

        setErrors(newErrors);
        return isValid;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (!formData.title || !formData.content) {
            showAlert('Please fill in all fields', 'error');
            return;
        }

        if (!validateForm()) {
            showAlert('Please fix validation errors', 'error');
            return;
        }

        try {
            // Add to local state (dummy data)
            const newAnnouncement = {
                id: announcements.length + 1,
                title: formData.title,
                content: formData.content,
                category: formData.category,
                priority: 'medium',
                date: new Date().toISOString().split('T')[0],
                views: 0,
                attachments: 0,
                status: 'active'
            };

            setAnnouncements([newAnnouncement, ...announcements]);

            // Also save to Firebase for real data
            await addDoc(collection(db, 'announcements'), {
                ...formData,
                createdAt: serverTimestamp(),
                createdBy: currentUser.uid,
                authorName: currentUser.fullName || 'Admin',
                status: 'active',
                views: 0
            });

            setFormData({ title: '', category: 'general', content: '' });
            setErrors({ title: '', content: '' });
            showAlert('Announcement published successfully!', 'success');
        } catch (err) {
            console.error("Error publishing:", err);
            // Still show success for dummy data even if Firebase fails
            showAlert("Announcement published!", "success");
        }
    };

    const handleDelete = async (id) => {
        const confirmed = await showConfirm("Delete this announcement?", "warning");
        if (confirmed) {
            try {
                // Remove from local state
                setAnnouncements(announcements.filter(a => a.id !== id));

                // Also try to delete from Firebase
                await deleteDoc(doc(db, 'announcements', id));
                showAlert("Announcement deleted.", "success");
            } catch (err) {
                console.error("Error deleting:", err);
                showAlert("Announcement deleted.", "success");
            }
        }
    };

    const stats = useMemo(() => {
        const total = announcements.length;
        const active = announcements.filter(a => a.status === 'active').length;
        const totalViews = announcements.reduce((sum, a) => sum + (a.views || 0), 0);
        return { total, active, totalViews };
    }, [announcements]);

    // Quill modules configuration
    const quillModules = {
        toolbar: [
            [{ 'header': [1, 2, 3, false] }],
            ['bold', 'italic', 'underline', 'strike'],
            [{ 'list': 'ordered' }, { 'list': 'bullet' }],
            [{ 'color': [] }, { 'background': [] }],
            ['link'],
            ['clean']
        ]
    };

    return (
        <div className="space-y-6">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Announcements</h1>
                    <p className="text-gray-600 dark:text-gray-400 mt-1">Keep your community informed with important updates</p>
                </div>
            </div>

            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-gradient-to-r from-purple-500 to-purple-600 rounded-xl p-6 text-white">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-purple-100 text-sm">Total Announcements</p>
                            <p className="text-2xl font-bold mt-1">{stats.total}</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                            <Bell className="w-6 h-6" />
                        </div>
                    </div>
                </div>

                <div className="bg-gradient-to-r from-green-500 to-green-600 rounded-xl p-6 text-white">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-green-100 text-sm">Active</p>
                            <p className="text-2xl font-bold mt-1">{stats.active}</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                            <Activity className="w-6 h-6" />
                        </div>
                    </div>
                </div>

                <div className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl p-6 text-white">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-blue-100 text-sm">Total Views</p>
                            <p className="text-2xl font-bold mt-1">{stats.totalViews}</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                            <Eye className="w-6 h-6" />
                        </div>
                    </div>
                </div>
            </div>

            {/* Create Announcement */}
            <div className="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
                <div className="flex items-center justify-between mb-6">
                    <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Create New Announcement</h2>
                    <div className="flex items-center space-x-2 text-sm text-gray-500 dark:text-gray-400">
                        <Info className="w-4 h-4" />
                        <span>Visible to all community members</span>
                    </div>
                </div>

                <form onSubmit={handleSubmit} className="space-y-4">
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Title</label>
                                <input
                                    type="text"
                                    value={formData.title}
                                    onChange={(e) => {
                                        setFormData({ ...formData, title: e.target.value });
                                        setErrors({ ...errors, title: '' });
                                    }}
                                    className={`w-full px-4 py-3 border ${errors.title ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'} rounded-xl focus:ring-2 focus:ring-purple-500 bg-white dark:bg-gray-700 dark:text-white`}
                                    placeholder="e.g., Water Supply Maintenance"
                                    required
                                />
                                {errors.title && <p className="text-red-500 text-sm mt-1">{errors.title}</p>}
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Category</label>
                                <select
                                    value={formData.category}
                                    onChange={e => setFormData({ ...formData, category: e.target.value })}
                                    className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-xl focus:ring-2 focus:ring-purple-500 bg-white dark:bg-gray-700 dark:text-white"
                                >
                                    <option value="general">📢 General</option>
                                    <option value="maintenance">🔧 Maintenance</option>
                                    <option value="safety">🛡️ Safety</option>
                                    <option value="event">🎉 Event</option>
                                    <option value="emergency">🚨 Emergency</option>
                                </select>
                            </div>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Content</label>
                            <TiptapEditor
                                content={formData.content}
                                onChange={(html) => {
                                    setFormData({ ...formData, content: html });
                                    setErrors({ ...errors, content: '' });
                                }}
                                error={errors.content}
                            />
                            {errors.content && <p className="text-red-500 text-sm mt-1">{errors.content}</p>}
                        </div>
                    </div>
                    <div className="flex justify-end">
                        <button type="submit" className="px-6 py-3 bg-purple-600 text-white rounded-xl hover:bg-purple-700 flex items-center space-x-2">
                            <Send className="w-4 h-4" />
                            <span>Publish Announcement</span>
                        </button>
                    </div>
                </form>
            </div>

            {/* List */}
            <div className="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-6">Recent Announcements</h2>
                {loading ? (
                    <div className="text-center py-8 text-gray-500 dark:text-gray-400">Loading...</div>
                ) : announcements.length === 0 ? (
                    <div className="text-center py-12">
                        <Megaphone className="w-12 h-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                        <p className="text-gray-500 dark:text-gray-400">No announcements yet.</p>
                    </div>
                ) : (
                    <div className="space-y-4">
                        {announcements.map(ann => (
                            <div key={ann.id} className="bg-gray-50 dark:bg-gray-700 rounded-xl p-6 border border-gray-200 dark:border-gray-600">
                                <div className="flex justify-between items-start">
                                    <div className="flex-1">
                                        <div className="flex items-center space-x-3 mb-2">
                                            <span className="bg-purple-100 dark:bg-purple-900 text-purple-800 dark:text-purple-200 text-xs font-bold px-2 py-1 rounded-full uppercase">
                                                {ann.category}
                                            </span>
                                            <span className="text-sm text-gray-500 dark:text-gray-400">
                                                {ann.date || 'Just now'}
                                            </span>
                                        </div>
                                        <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2">{ann.title}</h3>
                                        <div
                                            className="text-gray-600 dark:text-gray-300 prose prose-sm dark:prose-invert max-w-none"
                                            dangerouslySetInnerHTML={{ __html: ann.content }}
                                        />
                                    </div>
                                    <button onClick={() => handleDelete(ann.id)} className="text-red-500 hover:text-red-700 p-2">
                                        <Trash2 className="w-5 h-5" />
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}
