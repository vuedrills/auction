import api from './api';

export interface UserProfile {
    id: string;
    name: string;
    email: string;
    phone?: string;
    avatar_url?: string;
    created_at: string;
    updated_at?: string;
}

export interface UpdateProfileData {
    full_name?: string;
    email?: string;
}

export interface ChangePasswordData {
    current_password: string;
    new_password: string;
}

export const usersService = {
    getProfile: async (): Promise<UserProfile> => {
        const response = await api.get('/users/me');
        return response.data;
    },

    updateProfile: async (data: UpdateProfileData): Promise<UserProfile> => {
        const response = await api.put('/users/me', data);
        return response.data;
    },

    changePassword: async (data: ChangePasswordData): Promise<void> => {
        await api.put('/users/me/password', data);
    },

    uploadAvatar: async (file: File): Promise<{ avatar_url: string }> => {
        const formData = new FormData();
        formData.append('avatar', file);
        const response = await api.post('/users/me/avatar', formData, {
            headers: {
                'Content-Type': 'multipart/form-data',
            },
        });
        return response.data;
    },

    deleteAccount: async (): Promise<void> => {
        await api.delete('/users/me');
    },
};
