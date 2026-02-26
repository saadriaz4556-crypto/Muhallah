import React from 'react';
import { Menu, Moon, Sun, LogOut } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useMohallah } from '../context/MohallahContext';
import { useTheme } from '../context/ThemeContext';
import { useNavigate } from 'react-router-dom';

export default function Header({ toggleSidebar }) {
    const { currentUser, userRole, logout } = useAuth();
    const { selectedMohallah } = useMohallah();
    const { theme, toggleTheme } = useTheme();
    const navigate = useNavigate();

    const handleLogout = async () => {
        await logout();
        navigate('/login');
    };

    const roleTitles = {
        'platform-admin': '🌐 Platform Admin',
        'super-admin': '👑 Super Admin',
        'sub-admin': '👨‍💼 Sub-Admin',
        'moderator': '🔍 Moderator'
    };

    return (
        <header className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
            <div className="flex items-center justify-between px-6 py-4">
                <div className="flex items-center space-x-4">
                    <button onClick={toggleSidebar} className="lg:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-gray-200">
                        <Menu size={24} />
                    </button>
                    <div className="flex items-center space-x-3">
                        <div className="flex items-center justify-center">
                            <img src="/logo.png" alt="Digital Mohalla" className="h-12 w-auto" />
                        </div>
                        <div>
                            <h1 className="text-xl font-bold text-gray-900 dark:text-white">Digital Mohalla</h1>
                            <p className="text-sm text-gray-600 dark:text-gray-300">{roleTitles[userRole] || userRole}</p>
                            <p className="text-xs text-gray-500 dark:text-gray-400">Mohalla: <span className="font-medium">{selectedMohallah.name || 'Unknown'}</span></p>
                        </div>
                    </div>
                </div>

                <div className="flex items-center space-x-3">
                    <button
                        onClick={toggleTheme}
                        className="p-2 rounded-lg text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700 transition-colors"
                        title={theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
                    >
                        {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
                    </button>
                    <button onClick={handleLogout} className="bg-red-600 text-white px-3 py-2 rounded-lg text-sm hover:bg-red-700 transition flex items-center gap-2">
                        <LogOut size={16} /> Logout
                    </button>
                </div>
            </div>
        </header>
    );
}
