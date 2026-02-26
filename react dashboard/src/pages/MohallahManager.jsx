import React, { useEffect, useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useAlert } from '../context/AlertContext';
import { db } from '../lib/firebase';
import { collection, onSnapshot, addDoc, doc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { MapContainer, TileLayer, FeatureGroup, GeoJSON, useMap } from 'react-leaflet';
import { EditControl } from 'react-leaflet-draw';
import L from 'leaflet';
import { renderToStaticMarkup } from 'react-dom/server';
import { LogOut, ArrowRight, Edit3, Save, Trash2, ChevronRight, Plus, Minus, Square, Circle, MapPin, Hexagon, MousePointer2, Type, Home, ShoppingBag, GraduationCap, Trees, Building2, PenTool } from 'lucide-react';
import '../styles/mohallah-manager.css';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw/dist/leaflet.draw.css';
import { GeoSearchControl, OpenStreetMapProvider } from 'leaflet-geosearch';
import 'leaflet-geosearch/dist/geosearch.css';

// Fix Leaflet icons
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
    iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

// Helper to create custom DivIcon
const getIconForType = (type) => {
    let iconComponent;
    let colorClass;

    switch (type) {
        case 'House':
            iconComponent = <Home size={16} />;
            colorClass = 'text-emerald-600';
            break;
        case 'Shop':
            iconComponent = <ShoppingBag size={16} />;
            colorClass = 'text-amber-600';
            break;
        case 'School':
            iconComponent = <GraduationCap size={16} />;
            colorClass = 'text-red-600';
            break;
        case 'Park':
            iconComponent = <Trees size={16} />;
            colorClass = 'text-green-700';
            break;
        case 'Mohallah':
            // Mohallahs are usually polygons, but if a point is used:
            iconComponent = <MapPin size={16} />;
            colorClass = 'text-purple-600';
            break;
        default:
            iconComponent = <MapPin size={16} />;
            colorClass = 'text-blue-600';
    }

    const html = renderToStaticMarkup(
        <div className={`custom-marker-icon ${colorClass}`}>
            {iconComponent}
        </div>
    );

    return L.divIcon({
        html: html,
        className: '', // Remove default class to avoid default styles
        iconSize: [32, 32],
        iconAnchor: [16, 32], // Bottom center
        popupAnchor: [0, -32]
    });
};

function MapController({ setMap }) {
    const map = useMap();
    useEffect(() => {
        setMap(map);
    }, [map, setMap]);
    return null;
}

function SearchField() {
    const map = useMap();
    const provider = new OpenStreetMapProvider();

    useEffect(() => {
        const searchControl = new GeoSearchControl({
            provider: provider,
            style: 'bar',
            showMarker: true,
            showPopup: false,
            autoClose: true,
            retainZoomLevel: false,
            animateZoom: true,
            keepResult: true,
            searchLabel: 'Search for location...',
        });

        map.addControl(searchControl);
        return () => map.removeControl(searchControl);
    }, [map]);

    return null;
}

function MapToolbar({ activeTool, onToolSelect }) {
    const map = useMap();

    return (
        <div className="map-toolbar">
            <div className="toolbar-group">
                <button
                    className="tool-btn"
                    onClick={() => map.zoomIn()}
                    title="Zoom In"
                >
                    <Plus size={20} />
                </button>
                <button
                    className="tool-btn"
                    onClick={() => map.zoomOut()}
                    title="Zoom Out"
                >
                    <Minus size={20} />
                </button>
            </div>

            <div className="toolbar-group">
                <button
                    className={`tool-btn ${activeTool === 'polyline' ? 'active' : ''}`}
                    onClick={() => onToolSelect('polyline')}
                    title="Draw Polyline"
                >
                    <ArrowRight size={20} className="rotate-[-45deg]" />
                </button>
                <button
                    className={`tool-btn ${activeTool === 'polygon' ? 'active' : ''}`}
                    onClick={() => onToolSelect('polygon')}
                    title="Draw Polygon"
                >
                    <Hexagon size={20} />
                </button>
                <button
                    className={`tool-btn ${activeTool === 'circle' ? 'active' : ''}`}
                    onClick={() => onToolSelect('circle')}
                    title="Draw Circle"
                >
                    <Circle size={20} />
                </button>
                <button
                    className={`tool-btn ${activeTool === 'marker' ? 'active' : ''}`}
                    onClick={() => onToolSelect('marker')}
                    title="Add Marker"
                >
                    <MapPin size={20} />
                </button>
                <button
                    className={`tool-btn ${activeTool === 'pencil' ? 'active' : ''}`}
                    onClick={() => onToolSelect('pencil')}
                    title="Freehand / Pencil"
                >
                    <PenTool size={20} />
                </button>
            </div>

            <div className="toolbar-group">
                <button
                    className={`tool-btn ${activeTool === 'edit' ? 'active' : ''}`}
                    onClick={() => onToolSelect('edit')}
                    title="Edit Layers"
                >
                    <Edit3 size={20} />
                </button>
                <button
                    className={`tool-btn delete ${activeTool === 'delete' ? 'active' : ''}`}
                    onClick={() => onToolSelect('delete')}
                    title="Delete Layers"
                >
                    <Trash2 size={20} />
                </button>
            </div>
        </div>
    );
}

export default function MohallahManager() {
    const { currentUser, userRole, logout } = useAuth();
    const { showAlert } = useAlert();
    const navigate = useNavigate();
    const [mohallahs, setMohallahs] = useState([]);
    const [selectedMohallahId, setSelectedMohallahId] = useState(null);
    const [loading, setLoading] = useState(true);
    const [showNameModal, setShowNameModal] = useState(false);
    const [showDeleteModal, setShowDeleteModal] = useState(false);
    const [newItemName, setNewItemName] = useState('');
    const [newItemType, setNewItemType] = useState('Mohallah');
    const [currentLayer, setCurrentLayer] = useState(null);

    // Map & Drawing State
    const [map, setMap] = useState(null);
    const [activeTool, setActiveTool] = useState(null);
    const featureGroupRef = useRef();
    const drawHandlerRef = useRef(null);
    const activeToolRef = useRef(null); // Ref to access activeTool in callbacks
    const tempPolylineRef = useRef(null); // For freehand drawing

    useEffect(() => {
        activeToolRef.current = activeTool;
    }, [activeTool]);

    useEffect(() => {
        // Auto-redirect logic
        if (['super-admin', 'sub-admin', 'moderator'].includes(userRole) && currentUser.assignedMohallahId) {
            localStorage.setItem('selectedMohallahId', currentUser.assignedMohallahId);
            localStorage.setItem('selectedMohallahName', currentUser.assignedMohallahName);
            navigate('/dashboard');
            return;
        }

        const unsubscribe = onSnapshot(collection(db, 'mohallahs'), (snapshot) => {
            const list = [];
            snapshot.forEach(doc => {
                const data = doc.data();
                if (userRole === 'super-admin' && currentUser.assignedMohallahId) {
                    if (doc.id !== currentUser.assignedMohallahId) return;
                }
                list.push({ id: doc.id, ...data });
            });
            setMohallahs(list);
            setLoading(false);
        }, (error) => {
            console.error("Error fetching mohallahs:", error);
            showAlert("Failed to load Mohallahs. Check permissions.", "error");
            setLoading(false);
        });

        return () => unsubscribe();
    }, [userRole, currentUser, navigate]);

    // Drawing Logic
    const stopDrawing = () => {
        if (drawHandlerRef.current) {
            if (drawHandlerRef.current.save) {
                drawHandlerRef.current.save();
            }
            drawHandlerRef.current.disable();
            drawHandlerRef.current = null;
        }
        setActiveTool(null);
    };

    const startDrawing = (toolType) => {
        if (activeTool === toolType) {
            stopDrawing();
            return;
        }

        stopDrawing();

        if (!map) return;

        let handler;
        switch (toolType) {
            case 'polygon':
                handler = new L.Draw.Polygon(map);
                break;
            case 'circle':
                handler = new L.Draw.Circle(map);
                break;
            case 'marker':
                handler = new L.Draw.Marker(map);
                break;
            case 'polyline':
                handler = new L.Draw.Polyline(map);
                break;
            case 'edit':
                handler = new L.EditToolbar.Edit(map, {
                    featureGroup: featureGroupRef.current
                });
                break;
            case 'delete':
                // Custom delete mode: we don't use L.Draw.Delete because we want a modal
                setActiveTool('delete');
                return;
            case 'pencil':
                setActiveTool('pencil');
                return;
            default:
                return;
        }

        if (handler) {
            handler.enable();
            drawHandlerRef.current = handler;
            setActiveTool(toolType);
        }
    };

    // Listen for draw stop event
    useEffect(() => {
        if (!map) return;

        const onDrawStop = (e) => {
            const type = e.layerType;
            if (type) {
                setActiveTool(null);
                drawHandlerRef.current = null;
            }
        };

        map.on(L.Draw.Event.CREATED, onDrawStop);
        return () => {
            map.off(L.Draw.Event.CREATED, onDrawStop);
        };
    }, [map]);

    // Freehand Drawing Logic
    useEffect(() => {
        if (!map) return;

        const onMouseDown = (e) => {
            if (activeToolRef.current !== 'pencil') return;

            map.dragging.disable();
            const latlng = e.latlng;
            tempPolylineRef.current = L.polyline([latlng], { color: '#4F46E5', weight: 4 }).addTo(map);
        };

        const onMouseMove = (e) => {
            if (activeToolRef.current !== 'pencil' || !tempPolylineRef.current) return;
            tempPolylineRef.current.addLatLng(e.latlng);
        };

        const onMouseUp = () => {
            if (activeToolRef.current !== 'pencil' || !tempPolylineRef.current) return;

            const latlngs = tempPolylineRef.current.getLatLngs();
            map.removeLayer(tempPolylineRef.current);
            tempPolylineRef.current = null;
            map.dragging.enable();

            if (latlngs.length > 2) {
                // Close the shape
                latlngs.push(latlngs[0]);
                const polygon = L.polygon(latlngs, getStyleForType('Mohallah'));

                // Add to feature group manually
                if (featureGroupRef.current) {
                    featureGroupRef.current.addLayer(polygon);

                    // Trigger creation logic
                    const event = { layer: polygon };
                    handleCreated(event);
                }
            }

            setActiveTool(null);
        };

        map.on('mousedown', onMouseDown);
        map.on('mousemove', onMouseMove);
        map.on('mouseup', onMouseUp);

        return () => {
            map.off('mousedown', onMouseDown);
            map.off('mousemove', onMouseMove);
            map.off('mouseup', onMouseUp);
        };
    }, [map]);

    // Imperative Layer Management
    useEffect(() => {
        if (!featureGroupRef.current || loading) return;

        const fg = featureGroupRef.current;

        // Remove only layers that came from Firestore
        fg.eachLayer(layer => {
            if (layer.options && layer.options.fromFirestore) {
                fg.removeLayer(layer);
            }
        });

        mohallahs.forEach(m => {
            if (m.geoJson) {
                try {
                    const geoJsonData = JSON.parse(m.geoJson);
                    const layerGroup = L.geoJSON(geoJsonData, {
                        style: getStyleForType(m.type),
                        pointToLayer: (feature, latlng) => {
                            return L.marker(latlng, { icon: getIconForType(m.type) });
                        },
                        onEachFeature: (feature, layer) => {
                            layer.options.firestoreId = m.id;
                            layer.options.fromFirestore = true;

                            layer.bindTooltip(`${m.name} (${m.type || 'Mohallah'})`, { permanent: false, direction: "top" });

                            layer.on('click', () => {
                                setSelectedMohallahId(m.id);
                                if (activeToolRef.current === 'delete') {
                                    setShowDeleteModal(true);
                                }
                            });
                        }
                    });

                    layerGroup.eachLayer(layer => {
                        fg.addLayer(layer);
                    });

                } catch (e) {
                    console.error("Error parsing GeoJSON for", m.name, e);
                }
            }
        });

    }, [mohallahs, loading]);

    const handleCreated = (e) => {
        const layer = e.layer;
        setCurrentLayer(layer);
        setShowNameModal(true);
    };

    const handleEdited = async (e) => {
        const layers = e.layers;
        layers.eachLayer(async (layer) => {
            const firestoreId = layer.options.firestoreId;
            if (firestoreId) {
                const geoJson = JSON.stringify(layer.toGeoJSON());
                try {
                    await updateDoc(doc(db, 'mohallahs', firestoreId), {
                        geoJson: geoJson
                    });
                } catch (err) {
                    console.error("Error updating Mohallah:", err);
                }
            }
        });
    };

    const handleDeleted = (e) => {
        // We are handling delete manually now
    };

    const saveNewMohallah = async () => {
        if (!newItemName || !currentLayer) return;

        let geoJson;
        if (currentLayer instanceof L.Circle) {
            const center = currentLayer.getLatLng();
            const radius = currentLayer.getRadius();
            const points = [];
            for (let i = 0; i < 64; i++) {
                const angle = (i * 360) / 64;
                const rad = (angle * Math.PI) / 180;
                const latR = radius / 111319.9;
                const lngR = radius / (111319.9 * Math.cos(center.lat * (Math.PI / 180)));
                const pLat = center.lat + (latR * Math.cos(rad));
                const pLng = center.lng + (lngR * Math.sin(rad));
                points.push([pLng, pLat]);
            }
            points.push(points[0]);
            geoJson = JSON.stringify({
                type: "Feature",
                properties: {},
                geometry: { type: "Polygon", coordinates: [points] }
            });
        } else {
            geoJson = JSON.stringify(currentLayer.toGeoJSON());
        }

        try {
            await addDoc(collection(db, 'mohallahs'), {
                name: newItemName,
                type: newItemType,
                geoJson: geoJson,
                createdAt: serverTimestamp(),
                createdBy: currentUser.uid
            });
            setShowNameModal(false);
            setNewItemName('');
            setNewItemType('Mohallah');
            featureGroupRef.current.removeLayer(currentLayer);
            setCurrentLayer(null);
        } catch (err) {
            console.error("Error saving:", err);
            showAlert("Failed to save.", "error");
        }
    };

    const deleteMohallah = async () => {
        if (selectedMohallahId) {
            try {
                await deleteDoc(doc(db, 'mohallahs', selectedMohallahId));
                setSelectedMohallahId(null);
                setShowDeleteModal(false);
                // Exit delete mode if needed, or keep it
            } catch (err) {
                console.error("Error deleting:", err);
            }
        }
    };

    const handleLogout = async () => {
        await logout();
        navigate('/login');
    };

    const enterDashboard = () => {
        if (selectedMohallahId) {
            const selected = mohallahs.find(m => m.id === selectedMohallahId);
            localStorage.setItem('selectedMohallahId', selected.id);
            localStorage.setItem('selectedMohallahName', selected.name);
            navigate('/dashboard');
        }
    };

    const getStyleForType = (type) => {
        switch (type) {
            case 'Mohallah': return { color: '#4F46E5', fillOpacity: 0.1 };
            case 'House': return { color: '#10B981', fillOpacity: 0.5 };
            case 'Shop': return { color: '#F59E0B', fillOpacity: 0.5 };
            case 'School': return { color: '#EF4444', fillOpacity: 0.5 };
            case 'Road': return { color: '#374151', weight: 5 };
            case 'Park': return { color: '#059669', fillOpacity: 0.4 };
            default: return { color: '#3B82F6' };
        }
    };

    return (
        <div className="flex h-screen w-screen overflow-hidden bg-gray-50 dark:bg-gray-900">
            <aside className="w-80 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 flex flex-col shadow-xl z-20">
                <div className="p-6 border-b border-gray-100 dark:border-gray-700 bg-white dark:bg-gray-800">
                    <div className="flex items-center gap-4 mb-4">
                        <img src="/logo.png" alt="DM Logo" className="w-12 h-12 object-contain" />
                        <div>
                            <h2 className="text-xl font-bold text-gray-800 dark:text-white m-0">Digital Muhalla</h2>
                            <span className="inline-block bg-purple-100 dark:bg-purple-900 text-purple-700 dark:text-purple-300 text-xs px-2 py-1 rounded mt-1 font-medium">{userRole || 'Loading...'}</span>
                        </div>
                    </div>
                    <div className="flex justify-between items-center text-sm text-gray-500 dark:text-gray-400">
                        <p>{currentUser?.fullName || 'User'}</p>
                        <button onClick={handleLogout} className="text-red-500 hover:text-red-700 font-medium">Logout</button>
                    </div>
                </div>

                <div className="flex-1 overflow-y-auto p-6 bg-gray-50 dark:bg-gray-900">
                    <h3 className="text-lg font-semibold text-gray-800 dark:text-white mb-1">Select Mohallah</h3>
                    <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">Choose a community to manage</p>

                    <div className="space-y-2">
                        {loading ? (
                            <div className="text-center py-4 text-gray-500 dark:text-gray-400">Loading Mohallahs...</div>
                        ) : (
                            mohallahs.filter(m => !m.type || m.type === 'Mohallah').map(m => (
                                <div
                                    key={m.id}
                                    className={`flex items-center justify-between p-3 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg cursor-pointer transition-all hover:border-purple-500 hover:shadow-md text-gray-700 dark:text-gray-300 ${selectedMohallahId === m.id ? 'border-purple-600 bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-300' : ''}`}
                                    onClick={() => setSelectedMohallahId(m.id)}
                                >
                                    <span>{m.name}</span>
                                    <ChevronRight size={16} />
                                </div>
                            ))
                        )}
                    </div>
                </div>

                <div className="p-6 bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 space-y-3">
                    <button
                        className="w-full bg-gradient-to-r from-purple-600 to-indigo-600 text-white py-3 rounded-lg font-semibold shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                        disabled={!selectedMohallahId}
                        onClick={enterDashboard}
                    >
                        Enter Dashboard <ArrowRight size={16} />
                    </button>
                    <button
                        className="w-full bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 py-3 rounded-lg font-semibold hover:bg-gray-200 dark:hover:bg-gray-600 transition-all flex items-center justify-center gap-2"
                        onClick={() => navigate('/dashboard')}
                    >
                        Back to Dashboard
                    </button>
                </div>
            </aside>

            <main className="flex-1 relative z-10">
                <MapContainer center={[33.6844, 73.0479]} zoom={13} style={{ height: '100%', width: '100%' }} zoomControl={false}>
                    <MapController setMap={setMap} />
                    <SearchField />
                    <TileLayer
                        attribution='&copy; OpenStreetMap contributors'
                        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                    />
                    <FeatureGroup ref={featureGroupRef}>
                        {userRole === 'platform-admin' && (
                            <>
                                <EditControl
                                    position="topright"
                                    onCreated={handleCreated}
                                    onEdited={handleEdited}
                                    onDeleted={handleDeleted}
                                    draw={{
                                        rectangle: false,
                                        polygon: false,
                                        circle: false,
                                        circlemarker: false,
                                        marker: false,
                                        polyline: false
                                    }}
                                />
                                <MapToolbar activeTool={activeTool} onToolSelect={startDrawing} />
                            </>
                        )}
                    </FeatureGroup>
                </MapContainer>

                {userRole === 'platform-admin' && (
                    <div className="absolute top-4 right-4 bg-white dark:bg-gray-800 p-4 rounded-xl shadow-2xl border border-gray-100 dark:border-gray-700 w-64 z-[1000]">
                        <div className="border-b border-gray-100 dark:border-gray-700 pb-2 mb-2">
                            <h4 className="font-bold text-gray-800 dark:text-white flex items-center gap-2"><Edit3 size={16} /> Editor Tools</h4>
                        </div>
                        <div className="panel-body">
                            <p className="text-xs text-gray-500 dark:text-gray-400 mb-3">Use the toolbar on the left to draw shapes.</p>
                            <div className="flex flex-col gap-2">
                                <button
                                    className={`flex items-center justify-center gap-2 py-2 rounded-lg text-sm font-medium transition-colors ${activeTool === 'edit' ? 'bg-green-600 text-white hover:bg-green-700' : 'bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400'}`}
                                    onClick={() => stopDrawing()}
                                    disabled={activeTool !== 'edit'}
                                >
                                    <Save size={16} /> Save Changes
                                </button>
                                <button
                                    className="flex items-center justify-center gap-2 py-2 rounded-lg text-sm font-medium transition-colors bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/40"
                                    disabled={!selectedMohallahId}
                                    onClick={() => setShowDeleteModal(true)}
                                >
                                    <Trash2 size={16} /> Delete Selected
                                </button>
                            </div>
                        </div>
                    </div>
                )}
            </main>

            {showNameModal && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[2000] flex items-center justify-center">
                    <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl shadow-2xl w-96 border border-gray-100 dark:border-gray-700">
                        <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">Save New Item</h3>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1 mt-3">Select Type</label>
                        <select value={newItemType} onChange={(e) => setNewItemType(e.target.value)} className="w-full p-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 dark:text-white">
                            <option value="Mohallah">🏰 Mohallah Boundary</option>
                            <option value="House">🏠 House</option>
                            <option value="Shop">🏪 Shop</option>
                            <option value="School">🏫 School</option>
                            <option value="Road">🛣️ Road/Street</option>
                            <option value="Park">🌳 Park</option>
                            <option value="Other">📍 Other</option>
                        </select>

                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1 mt-3">Name / Label</label>
                        <input
                            type="text"
                            placeholder="e.g. Bahria Mohalla Phase 1"
                            value={newItemName}
                            onChange={(e) => setNewItemName(e.target.value)}
                            className="w-full p-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 dark:text-white"
                        />

                        <div className="flex justify-end gap-3 mt-6">
                            <button className="px-4 py-2 text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg" onClick={() => {
                                setShowNameModal(false);
                                if (currentLayer) featureGroupRef.current.removeLayer(currentLayer);
                            }}>Cancel</button>
                            <button className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700" onClick={saveNewMohallah}>Save</button>
                        </div>
                    </div>
                </div>
            )}

            {showDeleteModal && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[2000] flex items-center justify-center">
                    <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl shadow-2xl w-96 border border-gray-100 dark:border-gray-700 text-center">
                        <div className="w-16 h-16 bg-red-100 dark:bg-red-900/30 rounded-full flex items-center justify-center mx-auto mb-4">
                            <Trash2 size={32} className="text-red-600 dark:text-red-400" />
                        </div>
                        <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-2">Delete Item?</h3>
                        <p className="text-gray-500 dark:text-gray-400 mb-6">
                            Are you sure you want to delete this item? This action cannot be undone.
                        </p>
                        <div className="flex justify-center gap-3">
                            <button
                                className="px-5 py-2.5 text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg font-medium transition-colors"
                                onClick={() => setShowDeleteModal(false)}
                            >
                                Cancel
                            </button>
                            <button
                                className="px-5 py-2.5 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium shadow-lg shadow-red-600/20 transition-all hover:shadow-red-600/40"
                                onClick={deleteMohallah}
                            >
                                Yes, Delete
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
