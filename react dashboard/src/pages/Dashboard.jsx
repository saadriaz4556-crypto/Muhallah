import React, { useState } from 'react';
import { Outlet, Navigate } from 'react-router-dom';
import Sidebar from '../components/Sidebar';
import Header from '../components/Header';
import { MohallahProvider, useMohallah } from '../context/MohallahContext';

import { useAuth } from '../context/AuthContext';

function DashboardContent() {
    const [sidebarOpen, setSidebarOpen] = useState(false);
    const { selectedMohallah } = useMohallah();
    const { userRole } = useAuth();

    if (!selectedMohallah.id && userRole !== 'platform-admin') {
        return <Navigate to="/mohallah-manager" />;
    }

    return (
        <div className="flex flex-col h-screen bg-gray-50 dark:bg-gray-900">
            <Header toggleSidebar={() => setSidebarOpen(!sidebarOpen)} />
            <div className="flex flex-1 overflow-hidden">
                <Sidebar isOpen={sidebarOpen} />
                <main className="flex-1 overflow-x-hidden overflow-y-auto bg-gray-50 dark:bg-gray-900 p-6">
                    <Outlet />
                </main>
            </div>
        </div>
    );
}

export default function Dashboard() {
    return (
        <MohallahProvider>
            <DashboardContent />
        </MohallahProvider>
    );
}
