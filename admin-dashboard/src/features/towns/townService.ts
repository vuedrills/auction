import api from '@/lib/api';
import { Town, TownListResponse } from './types';

export const getTowns = async (): Promise<TownListResponse> => {
    const response = await api.get<TownListResponse>('/towns');
    return response.data;
};

export const getTownWithSuburbs = async (id: string) => {
    const response = await api.get(`/towns/${id}`);
    return response.data;
};

// Admin endpoints
export const createTown = async (data: { name: string; state?: string; country?: string; timezone?: string }) => {
    const response = await api.post('/admin/towns', data);
    return response.data;
};

export const deleteTown = async (id: string) => {
    const response = await api.delete(`/admin/towns/${id}`);
    return response.data;
};

export const createSuburb = async (townId: string, data: { name: string; zip_code?: string }) => {
    const response = await api.post(`/admin/towns/${townId}/suburbs`, data);
    return response.data;
};

export const deleteSuburb = async (townId: string, suburbId: string) => {
    const response = await api.delete(`/admin/towns/${townId}/suburbs/${suburbId}`);
    return response.data;
};
