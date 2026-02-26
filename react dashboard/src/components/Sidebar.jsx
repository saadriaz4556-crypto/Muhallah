import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Users, UserCog, Megaphone, FileText, ShoppingBag, Wrench, Settings, Map } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export default function Sidebar({ isOpen }) {
    const location = useLocation();
    const { userRole } = useAuth();

    const menuItems = [
        { path: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
        { path: '/mohallah-manager', icon: Map, label: 'Mohallah Manager', roles: ['platform-admin'] },
        { path: '/dashboard/users', icon: Users, label: 'User Management' },
        { path: '/dashboard/admins', icon: UserCog, label: 'Admin Management', roles: ['platform-admin', 'super-admin'] },
        { path: '/dashboard/announcements', icon: Megaphone, label: 'Announcements' },
        { path: '/dashboard/complaints', icon: FileText, label: 'Complaints', roles: ['super-admin', 'sub-admin', 'moderator'] },
        { path: '/dashboard/marketplace', icon: ShoppingBag, label: 'Marketplace' },
        { path: '/dashboard/services', icon: Wrench, label: 'Services' },
    ];

    return (
        <aside className={`fixed lg:static inset-y-0 left-0 z-50 w-64 bg-white dark:bg-gray-800 shadow-lg transform ${isOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0 transition-transform duration-300`}>
            <div className="p-6">

                <nav className="space-y-2">
                    {menuItems.map((item) => {
                        if (item.roles && !item.roles.includes(userRole)) return null;
                        const isActive = location.pathname === item.path || (item.path !== '/dashboard' && location.pathname.startsWith(item.path));
                        return (
                            <Link
                                key={item.path}
                                to={item.path}
                                className={`flex items-center space-x-3 px-4 py-3 rounded-lg transition-all ${isActive
                                    ? 'text-white font-medium bg-gradient-to-r from-[#667eea] to-[#764ba2]'
                                    : 'text-gray-700 dark:text-gray-300 hover:bg-gradient-to-r hover:from-[#7a88ee] hover:to-[#8a6ac7] hover:text-white'
                                    }`}
                            >
                                <item.icon size={20} />
                                <span>{item.label}</span>
                            </Link>
                        );
                    })}
                </nav>
            </div>
        </aside>
    );
}
