import React, { createContext, useContext, useState, useCallback } from 'react';
import CustomAlert from '../components/CustomAlert';

const AlertContext = createContext();

export function useAlert() {
    return useContext(AlertContext);
}

export function AlertProvider({ children }) {
    const [alertState, setAlertState] = useState({
        isOpen: false,
        type: 'info', // success, error, warning, info
        title: '',
        message: '',
        isConfirm: false,
        onConfirm: () => { },
        onCancel: () => { }
    });

    const closeAlert = useCallback(() => {
        setAlertState(prev => ({ ...prev, isOpen: false }));
    }, []);

    const showAlert = useCallback((message, type = 'info', title = '') => {
        return new Promise((resolve) => {
            setAlertState({
                isOpen: true,
                type,
                title,
                message,
                isConfirm: false,
                onConfirm: () => {
                    closeAlert();
                    resolve(true);
                },
                onCancel: () => {
                    closeAlert();
                    resolve(false);
                }
            });
        });
    }, [closeAlert]);

    const showConfirm = useCallback((message, type = 'warning', title = '') => {
        return new Promise((resolve) => {
            setAlertState({
                isOpen: true,
                type,
                title,
                message,
                isConfirm: true,
                onConfirm: () => {
                    closeAlert();
                    resolve(true);
                },
                onCancel: () => {
                    closeAlert();
                    resolve(false);
                }
            });
        });
    }, [closeAlert]);

    return (
        <AlertContext.Provider value={{ showAlert, showConfirm }}>
            {children}
            <CustomAlert
                isOpen={alertState.isOpen}
                type={alertState.type}
                title={alertState.title}
                message={alertState.message}
                isConfirm={alertState.isConfirm}
                onConfirm={alertState.onConfirm}
                onCancel={alertState.onCancel}
            />
        </AlertContext.Provider>
    );
}
