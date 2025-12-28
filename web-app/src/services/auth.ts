import { api } from './api';
import { z } from 'zod';
import { type User } from '@/stores/authStore';

// Types
export interface LoginResponse {
    user: User;
    token: string;
    refresh_token: string;
}

export interface RegisterResponse {
    user: User;
    token: string;
}

export interface Town {
    id: string;
    name: string;
}

export interface Suburb {
    id: string;
    name: string;
    town_id: string;
}

// Schemas
export const loginSchema = z.object({
    email: z.string().min(1, 'Username or Email is required'),
    password: z.string().min(1, 'Password is required'),
});

export const registerSchema = z.object({
    username: z.string().min(3, 'Username must be at least 3 characters'),
    email: z.string().email('Invalid email address'),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    full_name: z.string().min(2, 'Full name is required'),
    home_town_id: z.string().uuid('Invalid Town ID'),
    home_suburb_id: z.string().uuid('Invalid Suburb ID').optional().or(z.literal('')),
    phone: z.string().optional(),
});

export const forgotPasswordSchema = z.object({
    email: z.string().email('Invalid email address'),
});

export const resetPasswordSchema = z.object({
    token: z.string().min(1, 'Token is required'),
    new_password: z.string().min(8, 'Password must be at least 8 characters'),
    confirmPassword: z.string().min(8, 'Password must be at least 8 characters'),
}).refine((data) => data.new_password === data.confirmPassword, {
    message: "Passwords don't match",
    path: ["confirmPassword"],
});

export type LoginInput = z.infer<typeof loginSchema>;
export type RegisterInput = z.infer<typeof registerSchema>;
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;

// Service Functions
export const authService = {
    login: async (data: LoginInput): Promise<LoginResponse> => {
        const response = await api.post('/auth/login', data);
        return response.data;
    },

    register: async (data: RegisterInput): Promise<RegisterResponse> => {
        const response = await api.post('/auth/register', data);
        return response.data;
    },

    forgotPassword: async (data: ForgotPasswordInput): Promise<void> => {
        await api.post('/auth/forgot-password', data);
    },

    resetPassword: async (data: Omit<ResetPasswordInput, 'confirmPassword'>): Promise<void> => {
        await api.post('/auth/reset-password', data);
    },

    getTowns: async (): Promise<Town[]> => {
        const response = await api.get('/towns');
        // valid response: { towns: [...] }
        return response.data.towns || [];
    },

    getSuburbs: async (townId: string): Promise<Suburb[]> => {
        const response = await api.get(`/towns/${townId}/suburbs`);
        // valid response: { suburbs: [...] }
        return response.data.suburbs || [];
    },

    getMe: async (): Promise<User> => {
        const response = await api.get('/users/me');
        return response.data.user;
    },

    updateProfile: async (data: any): Promise<User> => {
        const response = await api.put('/users/me', data);
        return response.data.user;
    },

    getMyBadges: async (): Promise<any[]> => {
        const response = await api.get('/users/me/badges');
        return response.data.badges || [];
    },
};
