import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { User } from '@/types';

interface AppState {
    user: User | null;
    isAuthenticated: boolean;
    setUser: (user: User | null) => void;
    logout: () => void;
    sidebarOpen: boolean;
    toggleSidebar: () => void;
}

export const useStore = create<AppState>()(
    persist(
        (set) => ({
            user: null,
            isAuthenticated: false,
            sidebarOpen: true,
            setUser: (user) => set({ user, isAuthenticated: !!user }),
            logout: () => {
                if (typeof window !== 'undefined') {
                    localStorage.removeItem('token');
                }
                set({ user: null, isAuthenticated: false });
            },
            toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
        }),
        {
            name: 'admin-storage',
            partialize: (state) => ({
                user: state.user,
                isAuthenticated: state.isAuthenticated,
                sidebarOpen: state.sidebarOpen
            }),
        }
    )
);
