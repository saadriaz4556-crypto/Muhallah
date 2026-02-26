import React from 'react';
import { Users as UsersIcon, UserCheck, MapPin, Megaphone } from 'lucide-react';
import {
    Chart as ChartJS,
    CategoryScale,
    LinearScale,
    PointElement,
    LineElement,
    BarElement,
    Title,
    Tooltip,
    Legend,
    ArcElement,
    Filler
} from 'chart.js';
import { Line, Bar, Doughnut } from 'react-chartjs-2';

ChartJS.register(
    CategoryScale,
    LinearScale,
    PointElement,
    LineElement,
    BarElement,
    Title,
    Tooltip,
    Legend,
    ArcElement,
    Filler
);

export default function Overview() {
    // Mock Data (Ported from dashboard.html fallback)
    const growthData = {
        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        datasets: [
            {
                label: 'New Users',
                data: [65, 78, 66, 44, 56, 67, 75, 89, 105, 120, 145, 160],
                borderColor: '#8b5cf6',
                backgroundColor: 'rgba(139, 92, 246, 0.5)',
                tension: 0.4,
                fill: true,
            },
            {
                label: 'Active Users',
                data: [45, 55, 46, 30, 40, 47, 52, 62, 73, 84, 101, 112],
                borderColor: '#3b82f6',
                borderDash: [5, 5],
                tension: 0.4,
                fill: false,
            }
        ]
    };

    const engagementData = {
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        datasets: [
            {
                label: 'Interactions',
                data: [12, 19, 15, 25, 22, 30, 28],
                borderColor: '#3b82f6',
                backgroundColor: 'rgba(59, 130, 246, 0.5)',
                tension: 0.4,
                fill: true,
            }
        ]
    };

    const donutData = {
        labels: ['Users', 'Pending', 'Services', 'Announcements'],
        datasets: [{
            data: [120, 15, 45, 8],
            backgroundColor: ['#8b5cf6', '#3b82f6', '#10b981', '#f97316'],
            borderWidth: 0,
            hoverOffset: 4
        }]
    };

    const activityData = {
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        datasets: [
            {
                label: 'Visits',
                data: [150, 230, 180, 320, 290, 140, 190],
                backgroundColor: '#8b5cf6',
                borderRadius: 4,
            },
            {
                label: 'Actions',
                data: [80, 120, 90, 160, 140, 60, 95],
                backgroundColor: '#60a5fa',
                borderRadius: 4,
            }
        ]
    };

    return (
        <div className="space-y-6">
            {/* Stats Grid */}
            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div className="bg-gradient-to-r from-purple-500 to-purple-600 rounded-xl p-6 text-white shadow-lg">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-purple-100 text-sm font-medium">Total Users</p>
                            <p className="text-3xl font-bold mt-1">120</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg backdrop-blur-sm">
                            <UsersIcon className="w-6 h-6 text-white" />
                        </div>
                    </div>
                </div>

                <div className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl p-6 text-white shadow-lg">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-blue-100 text-sm font-medium">Pending Approvals</p>
                            <p className="text-3xl font-bold mt-1">15</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg backdrop-blur-sm">
                            <UserCheck className="w-6 h-6 text-white" />
                        </div>
                    </div>
                </div>

                <div className="bg-gradient-to-r from-green-500 to-green-600 rounded-xl p-6 text-white shadow-lg">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-green-100 text-sm font-medium">Services Listed</p>
                            <p className="text-3xl font-bold mt-1">45</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg backdrop-blur-sm">
                            <MapPin className="w-6 h-6 text-white" />
                        </div>
                    </div>
                </div>

                <div className="bg-gradient-to-r from-orange-500 to-orange-600 rounded-xl p-6 text-white shadow-lg">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-orange-100 text-sm font-medium">Announcements</p>
                            <p className="text-3xl font-bold mt-1">8</p>
                        </div>
                        <div className="p-3 bg-white bg-opacity-20 rounded-lg backdrop-blur-sm">
                            <Megaphone className="w-6 h-6 text-white" />
                        </div>
                    </div>
                </div>
            </div>

            {/* Charts Section */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Main Growth Chart */}
                <div className="lg:col-span-2 bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
                    <div className="flex items-center justify-between mb-4">
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white">Community Growth</h2>
                        <select className="text-sm border-gray-200 dark:border-gray-600 rounded-lg text-gray-500 dark:text-gray-400 bg-white dark:bg-gray-700">
                            <option value="year">This Year</option>
                        </select>
                    </div>
                    <div className="h-80">
                        <Line data={growthData} options={{ responsive: true, maintainAspectRatio: false }} />
                    </div>
                </div>

                {/* Engagement Stats */}
                <div className="space-y-6">
                    <div className="grid grid-cols-2 gap-4">
                        <div className="bg-purple-50 dark:bg-purple-900/20 rounded-xl p-4">
                            <p className="text-xs text-purple-600 dark:text-purple-400 font-medium mb-1">Avg Reply Time</p>
                            <h3 className="text-xl font-bold text-purple-700 dark:text-purple-300">30m 15s</h3>
                        </div>
                        <div className="bg-blue-50 dark:bg-blue-900/20 rounded-xl p-4">
                            <p className="text-xs text-blue-600 dark:text-blue-400 font-medium mb-1">Resolution Rate</p>
                            <h3 className="text-xl font-bold text-blue-700 dark:text-blue-300">94.2%</h3>
                        </div>
                    </div>

                    <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700 h-52">
                        <h2 className="text-sm font-bold text-gray-900 dark:text-white mb-2">Engagement Trends</h2>
                        <div className="h-full pb-6">
                            <Line data={engagementData} options={{ responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { display: false }, y: { display: false } } }} />
                        </div>
                    </div>
                </div>
            </div>

            {/* Bottom Row Charts */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
                    <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-4">Statistics Overview</h2>
                    <div className="h-64 relative">
                        <Doughnut data={donutData} options={{ responsive: true, maintainAspectRatio: false, cutout: '75%', plugins: { legend: { display: false } } }} />
                        <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                            <span className="text-3xl font-bold text-gray-800 dark:text-white">120</span>
                            <span className="text-xs text-gray-500 dark:text-gray-400">Total Users</span>
                        </div>
                    </div>
                </div>

                <div className="lg:col-span-2 bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
                    <div className="flex items-center justify-between mb-4">
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white">Weekly Activity</h2>
                    </div>
                    <div className="h-64">
                        <Bar data={activityData} options={{ responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }} />
                    </div>
                </div>
            </div>
        </div>
    );
}
