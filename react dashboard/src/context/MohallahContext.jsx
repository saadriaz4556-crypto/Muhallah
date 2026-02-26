import React, { createContext, useContext, useState, useEffect } from 'react';

const MohallahContext = createContext();

export function useMohallah() {
    return useContext(MohallahContext);
}

export function MohallahProvider({ children }) {
    const [selectedMohallah, setSelectedMohallah] = useState({
        id: localStorage.getItem('selectedMohallahId'),
        name: localStorage.getItem('selectedMohallahName')
    });

    const setMohallah = (id, name) => {
        localStorage.setItem('selectedMohallahId', id);
        localStorage.setItem('selectedMohallahName', name);
        setSelectedMohallah({ id, name });
    };

    return (
        <MohallahContext.Provider value={{ selectedMohallah, setMohallah }}>
            {children}
        </MohallahContext.Provider>
    );
}
