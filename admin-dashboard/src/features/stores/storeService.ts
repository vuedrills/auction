import api from '@/lib/api';
import { Store, StoresResponse, StoreFilters } from '@/types';

export const getStores = async (params: StoreFilters): Promise<StoresResponse> => {
    const response = await api.get<StoresResponse>('/stores', { params });
    return response.data;
};

export const getStore = async (id: string): Promise<Store> => {
    const response = await api.get<Store>(`/stores/${id}`);
    return response.data;
};

export const updateStore = async (id: string, data: Partial<Store>): Promise<Store> => {
    const response = await api.patch<Store>(`/stores/${id}`, data);
    return response.data;
};

export const deleteStore = async (id: string): Promise<void> => {
    await api.delete(`/stores/${id}`);
};

export const verifyStore = async (id: string): Promise<void> => {
    await api.post(`/stores/${id}/verify`);
};

export const deactivateStore = async (id: string): Promise<void> => {
    await api.patch(`/stores/${id}`, { is_active: false });
};

// Admin endpoints (use store ID, not slug)
export const adminGetStore = async (id: string): Promise<Store> => {
    const response = await api.get<Store>(`/admin/stores/${id}`);
    return response.data;
};

export const adminUpdateStore = async (id: string, data: Partial<Store>): Promise<void> => {
    await api.put(`/admin/stores/${id}`, data);
};

export const adminGetStoreProducts = async (id: string) => {
    const response = await api.get(`/admin/stores/${id}/products`);
    return response.data;
};
