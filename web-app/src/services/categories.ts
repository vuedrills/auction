import api from './api';

export interface Category {
    id: string;
    name: string;
    slug: string;
    icon_url?: string;
    description?: string;
    parent_id?: string;
    count?: number;
    sub_categories?: Category[];
}

export const categoriesService = {
    getCategories: async (): Promise<Category[]> => {
        const response = await api.get('/categories');
        // Backend might return wrapped object
        return response.data.categories || response.data;
    },

    getCategoryById: async (id: string): Promise<Category> => {
        const response = await api.get(`/categories/${id}`);
        return response.data;
    },

    getCategorySlots: async (categoryId: string, townId: string): Promise<any> => {
        const response = await api.get(`/categories/${categoryId}/slots/${townId}`);
        return response.data;
    },
};
