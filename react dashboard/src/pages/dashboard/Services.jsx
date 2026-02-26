import React, { useState, useEffect, useMemo } from 'react';
import { db } from '../../lib/firebase';
import { deleteDoc, doc } from 'firebase/firestore';
import { Wrench, Trash2, Phone, Plus, Search, Settings, Layers, ShieldCheck } from 'lucide-react';
import { services as dummyServices } from '../../data/dummyData';
import { useAlert } from '../../context/AlertContext';

export default function Services() {
    const { showAlert, showConfirm } = useAlert();
    const [services, setServices] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [categoryFilter, setCategoryFilter] = useState('all');

    useEffect(() => {
        // Using dummy data for display purposes as requested
        setServices(dummyServices);
        setLoading(false);
    }, []);

    const handleDelete = async (id) => {
        const confirmed = await showConfirm("Delete this service listing?", "warning", "Confirm Deletion");
        if (confirmed) {
            try {
                await deleteDoc(doc(db, 'services', id));
                showAlert("Service deleted successfully.", "success");
            } catch (err) {
                console.error("Error deleting service:", err);
                showAlert("Failed to delete service.", "error");
            }
        }
    };

    // Calculate stats
    const stats = useMemo(() => {
        const total = services.length;
        const categories = new Set(services.map(s => s.category)).size;
        const verified = services.filter(s => s.verified).length;
        return { total, categories, verified };
    }, [services]);

    // Filter services
    const filteredServices = useMemo(() => {
        return services.filter(service => {
            const matchesSearch = service.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                service.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
                service.person.toLowerCase().includes(searchTerm.toLowerCase());
            const matchesCategory = categoryFilter === 'all' || service.category === categoryFilter;
            return matchesSearch && matchesCategory;
        });
    }, [services, searchTerm, categoryFilter]);

    // Get unique categories
    const categories = useMemo(() => {
        return Array.from(new Set(services.map(s => s.category)));
    }, [services]);

    return (
        <div className="space-y-6">
            {/* Header Section */}
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Local Services</h1>
                    <p className="text-gray-600 dark:text-gray-400 mt-1">Find trusted service providers in your community</p>
                </div>
                <div className="flex items-center space-x-3 mt-4 lg:mt-0">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                        <input
                            type="text"
                            placeholder="Search services..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent w-64 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        />
                    </div>
                    <button className="bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700 flex items-center space-x-2">
                        <Plus className="w-4 h-4" />
                        <span>Add Service</span>
                    </button>
                </div>
            </div>

            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-gradient-to-r from-purple-500 to-purple-600 rounded-xl p-6 text-white">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-purple-100 text-sm">Total Services</p>
                            <p className="text-2xl font-bold mt-1">{stats.total}</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                            <Settings className="w-6 h-6" />
                        </div>
                    </div>
                </div>

                <div className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl p-6 text-white">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-blue-100 text-sm">Categories</p>
                            <p className="text-2xl font-bold mt-1">{stats.categories}</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                            <Layers className="w-6 h-6" />
                        </div>
                    </div>
                </div>

                <div className="bg-gradient-to-r from-green-500 to-green-600 rounded-xl p-6 text-white">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-green-100 text-sm">Verified</p>
                            <p className="text-2xl font-bold mt-1">{stats.verified}</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg">
                            <ShieldCheck className="w-6 h-6" />
                        </div>
                    </div>
                </div>
            </div>

            {/* Services List */}
            <div className="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
                <div className="flex items-center justify-between mb-6">
                    <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Available Services</h2>
                    <div className="flex items-center space-x-3 text-sm">
                        <span className="text-gray-500 dark:text-gray-400">Filter by:</span>
                        <select
                            value={categoryFilter}
                            onChange={(e) => setCategoryFilter(e.target.value)}
                            className="border-0 text-gray-700 dark:text-gray-300 dark:bg-gray-800 font-medium focus:ring-0"
                        >
                            <option value="all">All Categories</option>
                            {categories.map(cat => (
                                <option key={cat} value={cat}>{cat.charAt(0).toUpperCase() + cat.slice(1)}</option>
                            ))}
                        </select>
                    </div>
                </div>

                {loading ? (
                    <div className="col-span-full text-center py-8 text-gray-500 dark:text-gray-400">Loading services...</div>
                ) : filteredServices.length === 0 ? (
                    <div className="col-span-full text-center py-12">
                        <Wrench className="w-12 h-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                        <p className="text-gray-500 dark:text-gray-400">No services found.</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {filteredServices.map(service => (
                            <div key={service.id} className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden hover:shadow-md transition-all">
                                {/* Service Image */}
                                <div className="h-48 bg-gray-200 dark:bg-gray-700 relative">
                                    {service.image ? (
                                        <img src={service.image} alt={service.name} className="w-full h-full object-cover" />
                                    ) : (
                                        <div className="w-full h-full flex items-center justify-center text-gray-400 dark:text-gray-500">
                                            <Wrench className="w-12 h-12" />
                                        </div>
                                    )}
                                </div>

                                {/* Service Info */}
                                <div className="p-6">
                                    <div className="flex items-start justify-between mb-3">
                                        <div className="flex-1">
                                            <div className="flex items-center space-x-2 mb-1">
                                                <h3 className="font-bold text-gray-900 dark:text-white text-lg">{service.name}</h3>
                                            </div>
                                            <span className="inline-block px-2.5 py-0.5 bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-300 text-xs font-medium rounded-full uppercase">
                                                {service.category}
                                            </span>
                                        </div>
                                        <button onClick={() => handleDelete(service.id)} className="text-gray-400 hover:text-red-500 p-2">
                                            <Trash2 className="w-5 h-5" />
                                        </button>
                                    </div>

                                    <p className="text-gray-600 dark:text-gray-300 text-sm mb-4 line-clamp-2">{service.descriptionText || service.description}</p>

                                    <div className="space-y-2 border-t border-gray-100 dark:border-gray-700 pt-4">
                                        <div className="flex items-center text-gray-700 dark:text-gray-300 text-sm">
                                            <Phone className="w-4 h-4 mr-2 text-gray-500 dark:text-gray-400" />
                                            <span className="font-medium">{service.phone}</span>
                                        </div>
                                        <div className="flex items-center text-gray-600 dark:text-gray-400 text-xs">
                                            <span className="font-medium">Provider:</span>
                                            <span className="ml-1">{service.person}</span>
                                        </div>
                                        {service.availability && service.availability.length > 0 && (
                                            <div className="flex flex-wrap gap-1 mt-2">
                                                {service.availability.map((avail, idx) => (
                                                    <span key={idx} className="px-2 py-1 bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300 text-xs rounded">
                                                        {avail}
                                                    </span>
                                                ))}
                                            </div>
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
