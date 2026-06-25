import React, { useState, useEffect } from 'react';
import { Flame, Trash2, AlertTriangle, Eye } from 'lucide-react';

// NOTE: Ensure your Firebase config is available, assuming similar setup to other pages
// import { collection, getDocs, query, where, doc, updateDoc } from 'firebase/firestore';
// import { db } from '../../firebase'; // adjust import as per project

export default function LocalVibesModeration() {
    const [stats, setStats] = useState({ active: 0, today: 0, deleted: 0 });
    const [reportedPosts, setReportedPosts] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Mock data fetching since Firebase setup is unknown
        setTimeout(() => {
            setStats({ active: 142, today: 35, deleted: 12 });
            setReportedPosts([
                { id: '1', type: 'photo', url: 'https://via.placeholder.com/150', reporterCount: 3, reason: 'Inappropriate content', date: '2026-05-23' },
                { id: '2', type: 'joke', text: 'This is a bad joke that got reported.', reporterCount: 1, reason: 'Spam', date: '2026-05-23' },
            ]);
            setLoading(false);
        }, 1000);
    }, []);

    const handleDelete = (id) => {
        // Mock delete logic
        // updateDoc(doc(db, 'local_vibes_posts', id), { is_deleted: true })
        setReportedPosts(reportedPosts.filter(p => p.id !== id));
        alert('Post deleted and user warned.');
    };

    if (loading) return <div className="p-6 text-center text-gray-500">Loading moderation data...</div>;

    return (
        <div className="p-6">
            <div className="flex justify-between items-center mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-gray-800 dark:text-white flex items-center gap-2">
                        <Flame className="text-orange-500" /> Local Vibes Moderation
                    </h1>
                    <p className="text-gray-600 dark:text-gray-400 mt-2">Monitor and moderate 24-hour expiring content</p>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-md border-l-4 border-orange-500">
                    <h3 className="text-gray-500 dark:text-gray-400 text-sm font-medium">Active Posts Now</h3>
                    <p className="text-3xl font-bold text-gray-800 dark:text-white mt-2">{stats.active}</p>
                </div>
                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-md border-l-4 border-blue-500">
                    <h3 className="text-gray-500 dark:text-gray-400 text-sm font-medium">Posts Today</h3>
                    <p className="text-3xl font-bold text-gray-800 dark:text-white mt-2">{stats.today}</p>
                </div>
                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-md border-l-4 border-red-500">
                    <h3 className="text-gray-500 dark:text-gray-400 text-sm font-medium">Deleted Today</h3>
                    <p className="text-3xl font-bold text-gray-800 dark:text-white mt-2">{stats.deleted}</p>
                </div>
            </div>

            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md overflow-hidden">
                <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/50 flex justify-between items-center">
                    <h2 className="text-lg font-semibold text-gray-800 dark:text-white flex items-center gap-2">
                        <AlertTriangle className="text-amber-500" size={20} /> Reported Posts
                    </h2>
                </div>
                
                <div className="p-6">
                    {reportedPosts.length === 0 ? (
                        <p className="text-gray-500 dark:text-gray-400 text-center py-4">No reported posts at the moment.</p>
                    ) : (
                        <div className="space-y-4">
                            {reportedPosts.map(post => (
                                <div key={post.id} className="flex flex-col md:flex-row items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg bg-gray-50 dark:bg-gray-900/30">
                                    <div className="flex items-center gap-4 w-full md:w-2/3">
                                        <div className="w-16 h-16 rounded bg-gray-200 dark:bg-gray-700 flex items-center justify-center flex-shrink-0">
                                            {post.type === 'photo' ? (
                                                <img src={post.url} alt="Reported" className="w-full h-full object-cover rounded" />
                                            ) : (
                                                <Eye className="text-gray-400" />
                                            )}
                                        </div>
                                        <div>
                                            <p className="text-sm font-semibold text-gray-800 dark:text-white">
                                                {post.type.toUpperCase()} - {post.reporterCount} Reports
                                            </p>
                                            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1 line-clamp-2">
                                                {post.text || 'Media Content'}
                                            </p>
                                            <p className="text-xs text-red-500 mt-1">Reason: {post.reason}</p>
                                        </div>
                                    </div>
                                    
                                    <div className="mt-4 md:mt-0 flex gap-2">
                                        <button 
                                            onClick={() => handleDelete(post.id)}
                                            className="px-4 py-2 bg-red-100 text-red-600 hover:bg-red-200 rounded-lg flex items-center gap-2 text-sm font-medium transition-colors"
                                        >
                                            <Trash2 size={16} /> Delete & Warn User
                                        </button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
