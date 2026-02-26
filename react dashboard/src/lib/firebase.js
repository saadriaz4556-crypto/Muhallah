import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
    apiKey: "AIzaSyBftGlQSTEurzcX-OeKgQuVyne91D_tN14",
    authDomain: "digitalmohallah-f91c6.firebaseapp.com",
    projectId: "digitalmohallah-f91c6",
    storageBucket: "digitalmohallah-f91c6.firebasestorage.app",
    messagingSenderId: "496013462528",
    appId: "1:496013462528:web:84f32c8b30e820cd48dce5"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export default app;
