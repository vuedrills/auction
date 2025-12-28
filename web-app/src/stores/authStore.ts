import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface User {
    id: string;
    username: string;
    email: string;
    full_name?: string;
    avatar_url?: string;
    profile_image_url?: string;
    home_town_id?: string;
    home_suburb_id?: string;
    town_id?: string;
    suburb_id?: string;
    town_name?: string;
    suburb_name?: string;
    is_verified?: boolean;
    is_active?: boolean;
    role?: string;
    phone?: string;
    created_at?: string;
}

interface AuthState {
    user: User | null;
    token: string | null;
    refreshToken: string | null;
    isAuthenticated: boolean;
    isLoading: boolean;

    // Actions
    setUser: (user: User | null) => void;
    setTokens: (token: string, refreshToken: string) => void;
    login: (user: User, token: string, refreshToken: string) => void;
    logout: () => void;
    setLoading: (loading: boolean) => void;
}

export const useAuthStore = create<AuthState>()(
    persist(
        (set) => ({
            user: null,
            token: null,
            refreshToken: null,
            isAuthenticated: false,
            isLoading: true,

            setUser: (user) => set({ user, isAuthenticated: !!user }),

            setTokens: (token, refreshToken) => {
                if (typeof window !== 'undefined') {
                    localStorage.setItem('auth_token', token);
                    localStorage.setItem('refresh_token', refreshToken);
                }
                set({ token, refreshToken });
            },

            login: (user, token, refreshToken) => {
                if (typeof window !== 'undefined') {
                    localStorage.setItem('auth_token', token);
                    localStorage.setItem('refresh_token', refreshToken);
                }
                set({ user, token, refreshToken, isAuthenticated: true, isLoading: false });
            },

            logout: () => {
                if (typeof window !== 'undefined') {
                    localStorage.removeItem('auth_token');
                    localStorage.removeItem('refresh_token');
                }
                set({ user: null, token: null, refreshToken: null, isAuthenticated: false });
            },

            setLoading: (loading) => set({ isLoading: loading }),
        }),
        {
            name: 'auth-storage',
            partialize: (state) => ({
                user: state.user,
                token: state.token,
                refreshToken: state.refreshToken,
                isAuthenticated: state.isAuthenticated,
            }),
        }
    )
);
