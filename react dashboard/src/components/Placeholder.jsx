import React from 'react';

export default function Placeholder({ title }) {
    return (
        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">{title}</h2>
            <p className="text-gray-600 dark:text-gray-400">This module is under construction.</p>
        </div>
    );
}
