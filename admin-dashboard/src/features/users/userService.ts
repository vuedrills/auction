import api from '@/lib/api';
import { User, UserListResponse, UserQueryParams } from '@/types';

export const getUsers = async (params: UserQueryParams): Promise<UserListResponse> => {
    const response = await api.get<UserListResponse>('/users', { params });
    return response.data;
};

export const getUser = async (id: string): Promise<User> => {
    const response = await api.get<User>(`/users/${id}`);
    return response.data;
};

export const updateUser = async (id: string, data: Partial<User>): Promise<User> => {
    const response = await api.patch<User>(`/users/${id}`, data);
    return response.data;
};

export const suspendUser = async (id: string, reason: string): Promise<void> => {
    await api.post(`/users/${id}/suspend`, { reason });
};

export const reactivateUser = async (id: string): Promise<void> => {
    await api.post(`/users/${id}/reactivate`);
};
