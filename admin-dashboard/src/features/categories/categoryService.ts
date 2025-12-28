import api from '@/lib/api';

export const getCategories = async () => {
    const response = await api.get('/categories');
    return response.data;
};

export const getCategory = async (id: string) => {
    const response = await api.get(`/categories/${id}`);
    return response.data;
};
