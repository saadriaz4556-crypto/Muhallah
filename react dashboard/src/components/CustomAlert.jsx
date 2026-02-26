import React from 'react';
import { X, Check, AlertTriangle, Info } from 'lucide-react';

export default function CustomAlert({ isOpen, type, title, message, onConfirm, onCancel, isConfirm }) {
    if (!isOpen) return null;

    const getIcon = () => {
        switch (type) {
            case 'success': return <Check className="w-8 h-8 text-green-500" />;
            case 'error': return <X className="w-8 h-8 text-red-500" />;
            case 'warning': return <AlertTriangle className="w-8 h-8 text-yellow-500" />;
            default: return <Info className="w-8 h-8 text-blue-500" />;
        }
    };

    const getBgColor = () => {
        switch (type) {
            case 'success': return 'bg-green-100 dark:bg-green-900/30';
            case 'error': return 'bg-red-100 dark:bg-red-900/30';
            case 'warning': return 'bg-yellow-100 dark:bg-yellow-900/30';
            default: return 'bg-blue-100 dark:bg-blue-900/30';
        }
    };

    return (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/50 backdrop-blur-sm animate-fadeIn">
            <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-sm p-6 transform transition-all scale-100 animate-scaleUp border border-gray-100 dark:border-gray-700">
                <div className="flex flex-col items-center text-center">
                    <div className={`w-16 h-16 rounded-full flex items-center justify-center mb-4 ${getBgColor()}`}>
                        {getIcon()}
                    </div>

                    <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-2">
                        {title || (type === 'error' ? 'Error' : type === 'success' ? 'Success' : 'Notice')}
                    </h3>

                    <p className="text-gray-600 dark:text-gray-300 mb-6">
                        {message}
                    </p>

                    <div className="flex gap-3 w-full">
                        {isConfirm && (
                            <button
                                onClick={onCancel}
                                className="flex-1 px-4 py-2.5 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-xl font-medium hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
                            >
                                Cancel
                            </button>
                        )}
                        <button
                            onClick={onConfirm}
                            className={`flex-1 px-4 py-2.5 text-white rounded-xl font-medium shadow-lg transition-all transform hover:scale-[1.02] ${type === 'error' ? 'bg-red-600 hover:bg-red-700 shadow-red-500/30' :
                                    type === 'warning' ? 'bg-yellow-600 hover:bg-yellow-700 shadow-yellow-500/30' :
                                        'bg-purple-600 hover:bg-purple-700 shadow-purple-500/30'
                                }`}
                        >
                            {isConfirm ? 'Confirm' : 'OK'}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
