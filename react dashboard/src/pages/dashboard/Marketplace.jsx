import React, { useState, useEffect, useMemo } from 'react';
import { db } from '../../lib/firebase';
import { updateDoc, doc, deleteDoc } from 'firebase/firestore';
import { ShoppingBag, Check, X, Trash2, Calendar, TrendingUp } from 'lucide-react';
import { marketplace as dummyMarketplace } from '../../data/dummyData';
import { useAlert } from '../../context/AlertContext';

export default function Marketplace() {
    const { showAlert, showConfirm } = useAlert();
    const [items, setItems] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Using dummy data for display purposes as requested
        setItems(dummyMarketplace);
        setLoading(false);
    }, []);

    const handleApprove = async (id) => {
        try {
            await updateDoc(doc(db, 'marketplace', id), { status: 'approved' });
            showAlert("Item approved successfully.", "success");
        } catch (err) {
            console.error("Error approving item:", err);
            showAlert("Failed to approve item.", "error");
        }
    };

    const handleDelete = async (id) => {
        const confirmed = await showConfirm("Delete this marketplace item?", "warning", "Confirm Deletion");
        if (confirmed) {
            try {
                await deleteDoc(doc(db, 'marketplace', id));
                showAlert("Item deleted successfully.", "success");
            } catch (err) {
                console.error("Error deleting item:", err);
                showAlert("Failed to delete item.", "error");
            }
        }
    };

    const stats = useMemo(() => {
        const total = items.length;
        const active = items.filter(i => i.status !== 'sold').length;
        // Simulating "this month" - in real app would filter by date
        const thisMonth = items.length;
        return { total, active, thisMonth };
    }, [items]);

    return (
        <div className="space-y-6">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Community Marketplace</h1>
                    <p className="text-gray-600 dark:text-gray-400 mt-1">Browse items for sale within your community</p>
                </div>
            </div>

            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-gradient-to-r from-purple-500 to-purple-600 rounded-xl p-6 text-white">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-purple-100 text-sm">Total Listings</p>
                            <p className="text-2xl font-bold mt-1">{stats.total}</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                            <ShoppingBag className="w-6 h-6" />
                        </div>
                    </div>
                </div>

                <div className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl p-6 text-white">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-blue-100 text-sm">This Month</p>
                            <p className="text-2xl font-bold mt-1">{stats.thisMonth}</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                            <Calendar className="w-6 h-6" />
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
                            <TrendingUp className="w-6 h-6" />
                        </div>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {loading ? (
                    <div className="col-span-full text-center py-8 text-gray-500 dark:text-gray-400">Loading items...</div>
                ) : items.length === 0 ? (
                    <div className="col-span-full text-center py-12">
                        <ShoppingBag className="w-12 h-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                        <p className="text-gray-500 dark:text-gray-400">No marketplace listings found.</p>
                    </div>
                ) : (
                    items.map(item => (
                        <div key={item.id} className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden hover:shadow-md transition-all">
                            <div className="h-48 bg-gray-200 dark:bg-gray-700 relative">
                                {item.image ? (
                                    <img src={item.image} alt={item.title} className="w-full h-full object-cover" />
                                ) : (
                                    <div className="w-full h-full flex items-center justify-center text-gray-400 dark:text-gray-500">
                                        <ShoppingBag className="w-12 h-12" />
                                    </div>
                                )}
                                <span className={`absolute top-3 right-3 px-2 py-1 rounded-full text-xs font-bold uppercase ${item.status === 'approved' ? 'bg-green-500 text-white' : 'bg-yellow-500 text-white'
                                    }`}>
                                    {item.status || 'Pending'}
                                </span>
                            </div>
                            <div className="p-4">
                                <div className="flex justify-between items-start mb-2">
                                    <h3 className="font-bold text-gray-900 dark:text-white text-lg">{item.title}</h3>
                                    <span className="font-bold text-green-600 dark:text-green-400">Rs. {item.price}</span>
                                </div>
                                <p className="text-gray-600 dark:text-gray-300 text-sm mb-4 line-clamp-2">{item.description}</p>

                                <div className="flex justify-between items-center pt-4 border-t border-gray-100 dark:border-gray-700">
                                    <span className="text-xs text-gray-500 dark:text-gray-400">By: {item.sellerName || 'Unknown'}</span>
                                    <div className="flex space-x-2">
                                        {item.status !== 'approved' && (
                                            <button onClick={() => handleApprove(item.id)} className="p-2 bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400 rounded-lg hover:bg-green-200 dark:hover:bg-green-900/50">
                                                <Check className="w-4 h-4" />
                                            </button>
                                        )}
                                        <button onClick={() => handleDelete(item.id)} className="p-2 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 rounded-lg hover:bg-red-200 dark:hover:bg-red-900/50">
                                            <Trash2 className="w-4 h-4" />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
}
