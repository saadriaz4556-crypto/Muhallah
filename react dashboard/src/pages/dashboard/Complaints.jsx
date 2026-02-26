import React, { useState, useEffect, useMemo } from 'react';
import { db } from '../../lib/firebase';
import { updateDoc, doc } from 'firebase/firestore';
import { FileText, CheckCircle, Clock, AlertCircle, Search, Filter } from 'lucide-react';
import { complaints as dummyComplaints } from '../../data/dummyData';

export default function Complaints() {
    const [complaints, setComplaints] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('all');

    useEffect(() => {
        // Using dummy data for display purposes as requested
        setComplaints(dummyComplaints);
        setLoading(false);
    }, []);

    const updateStatus = async (id, newStatus) => {
        try {
            await updateDoc(doc(db, 'complaints', id), { status: newStatus });
        } catch (err) {
            console.error("Error updating status:", err);
        }
    };

    // Calculate stats
    const stats = useMemo(() => {
        const total = complaints.length;
        const pending = complaints.filter(c => c.status === 'Pending').length;
        const resolved = complaints.filter(c => c.status === 'Resolved').length;
        return { total, pending, resolved };
    }, [complaints]);

    // Filter complaints
    const filteredComplaints = useMemo(() => {
        return complaints.filter(complaint => {
            const matchesSearch = complaint.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                complaint.content.toLowerCase().includes(searchTerm.toLowerCase());
            const matchesStatus = statusFilter === 'all' ||
                (statusFilter === 'pending' && complaint.status === 'Pending') ||
                (statusFilter === 'resolved' && complaint.status === 'Resolved');
            return matchesSearch && matchesStatus;
        });
    }, [complaints, searchTerm, statusFilter]);

    return (
        <div className="space-y-6">
            {/* Header Section */}
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Community Complaints</h1>
                    <p className="text-gray-600 dark:text-gray-400 mt-1">Address and resolve community issues efficiently</p>
                </div>
                <div className="flex items-center space-x-3 mt-4 lg:mt-0">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                        <input
                            type="text"
                            placeholder="Search complaints..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent w-64 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        />
                    </div>
                    <button className="p-2 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700">
                        <Filter className="w-4 h-4 text-gray-600 dark:text-gray-400" />
                    </button>
                </div>
            </div>

            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-gradient-to-r from-purple-500 to-purple-600 rounded-xl p-6 text-white">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-purple-100 text-sm">Total Complaints</p>
                            <p className="text-2xl font-bold mt-1">{stats.total}</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                            <AlertCircle className="w-6 h-6" />
                        </div>
                    </div>
                </div>

                <div className="bg-gradient-to-r from-yellow-500 to-yellow-600 rounded-xl p-6 text-white">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-yellow-100 text-sm">Pending</p>
                            <p className="text-2xl font-bold mt-1">{stats.pending}</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                            <Clock className="w-6 h-6" />
                        </div>
                    </div>
                </div>

                <div className="bg-gradient-to-r from-green-500 to-green-600 rounded-xl p-6 text-white">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-green-100 text-sm">Resolved</p>
                            <p className="text-2xl font-bold mt-1">{stats.resolved}</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                            <CheckCircle className="w-6 h-6" />
                        </div>
                    </div>
                </div>
            </div>

            {/* Complaints List */}
            <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
                <div className="flex items-center justify-between mb-6">
                    <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Recent Complaints</h2>
                    <div className="flex items-center space-x-3 text-sm">
                        <span className="text-gray-500 dark:text-gray-400">Filter by:</span>
                        <select
                            value={statusFilter}
                            onChange={(e) => setStatusFilter(e.target.value)}
                            className="border-0 text-gray-700 dark:text-gray-300 dark:bg-gray-800 font-medium focus:ring-0"
                        >
                            <option value="all">All Status</option>
                            <option value="pending">Pending</option>
                            <option value="resolved">Resolved</option>
                        </select>
                    </div>
                </div>

                {loading ? (
                    <div className="text-center py-8 text-gray-500 dark:text-gray-400">Loading complaints...</div>
                ) : filteredComplaints.length === 0 ? (
                    <div className="text-center py-12">
                        <FileText className="w-12 h-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                        <p className="text-gray-500 dark:text-gray-400">No complaints found.</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {filteredComplaints.map(complaint => (
                            <div key={complaint.id} className="border border-gray-200 dark:border-gray-700 rounded-xl overflow-hidden hover:shadow-md transition-shadow">
                                {/* Complaint Image */}
                                {complaint.image && (
                                    <div className="h-48 bg-gray-200 dark:bg-gray-700">
                                        <img
                                            src={complaint.image}
                                            alt={complaint.title}
                                            className="w-full h-full object-cover"
                                        />
                                    </div>
                                )}

                                {/* Complaint Content */}
                                <div className="p-4">
                                    <div className="flex items-center space-x-2 mb-2">
                                        <span className={`px-2 py-1 rounded-full text-xs font-bold uppercase ${complaint.status === 'Resolved'
                                                ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                                                : complaint.status === 'In Progress'
                                                    ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
                                                    : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
                                            }`}>
                                            {complaint.status || 'Pending'}
                                        </span>
                                        <span className="text-xs text-gray-500 dark:text-gray-400">
                                            {complaint.date}
                                        </span>
                                    </div>
                                    <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2">{complaint.title}</h3>
                                    <p className="text-gray-600 dark:text-gray-300 text-sm mb-3 line-clamp-2">{complaint.content}</p>
                                    <p className="text-xs text-gray-500 dark:text-gray-400 mb-3">Submitted by: {complaint.user}</p>

                                    {/* Action Buttons */}
                                    <div className="flex flex-col space-y-2">
                                        {complaint.status !== 'Resolved' && (
                                            <button
                                                onClick={() => updateStatus(complaint.id, 'Resolved')}
                                                className="flex items-center justify-center space-x-2 px-3 py-2 bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400 rounded-lg hover:bg-green-100 dark:hover:bg-green-900/40 text-sm font-medium"
                                            >
                                                <CheckCircle className="w-4 h-4" />
                                                <span>Mark Resolved</span>
                                            </button>
                                        )}
                                        {complaint.status === 'Pending' && (
                                            <button
                                                onClick={() => updateStatus(complaint.id, 'In Progress')}
                                                className="flex items-center justify-center space-x-2 px-3 py-2 bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/40 text-sm font-medium"
                                            >
                                                <Clock className="w-4 h-4" />
                                                <span>In Progress</span>
                                            </button>
                                        )}
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}
