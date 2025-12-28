import api from '@/lib/api';

export const getAdminSettings = async () => {
    const response = await api.get('/admin/settings');
    return response.data;
};

export const updateAdminSetting = async (key: string, value: string) => {
    const response = await api.put(`/admin/settings/${key}`, { value });
    return response.data;
};

export const getPublicSetting = async (key: string) => {
    const response = await api.get(`/settings/${key}`);
    return response.data;
};
