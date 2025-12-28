import api from '@/lib/api';

export const getAdminBids = async (params: { page?: number; limit?: number; town_id?: string; suburb_id?: string } = {}) => {
    const response = await api.get('/admin/bids', { params });
    return response.data;
};

export const getAdminConversations = async (params: { town_id?: string; suburb_id?: string; type?: string } = {}) => {
    const response = await api.get('/admin/conversations', { params });
    return response.data;
};

export const getAdminNotifications = async () => {
    const response = await api.get('/admin/notifications');
    return response.data;
};

export const sendAdminNotification = async (data: {
    user_ids?: string[];
    category?: string;
    town_id?: string;
    suburb_id?: string;
    title: string;
    body: string;
    type?: string;
}) => {
    const response = await api.post('/admin/notifications', data);
    return response.data;
};

export const deleteAdminAuction = async (id: string) => {
    const response = await api.delete(`/admin/auctions/${id}`);
    return response.data;
};

export const approveAdminAuction = async (id: string) => {
    const response = await api.post(`/admin/auctions/${id}/approve`);
    return response.data;
};

export const updateAuctionStatus = async (id: string, status: string) => {
    const response = await api.put(`/admin/auctions/${id}/status`, { status });
    return response.data;
};

export const getAdminAuctionDetails = async (id: string) => {
    const response = await api.get(`/admin/auctions/${id}`);
    return response.data;
};

export const searchUsers = async (query: string) => {
    const response = await api.get('/admin/users/search', { params: { q: query } });
    return response.data;
};

export const getAdminUserDetails = async (id: string) => {
    const response = await api.get(`/admin/users/${id}`);
    return response.data;
};

export const updateUserStatus = async (id: string, isActive: boolean) => {
    const response = await api.put(`/admin/users/${id}/status`, { is_active: isActive });
    return response.data;
};

export const verifyUser = async (id: string, isVerified: boolean) => {
    const response = await api.put(`/admin/users/${id}/verify`, { is_verified: isVerified });
    return response.data;
};

export const getAdminChatMessages = async (id: string) => {
    const response = await api.get(`/admin/conversations/${id}/messages`);
    return response.data;
};

// Categories
export const createCategory = async (data: any) => {
    const response = await api.post('/admin/categories', data);
    return response.data;
};

export const updateCategory = async (id: string, data: any) => {
    const response = await api.put(`/admin/categories/${id}`, data);
    return response.data;
};

export const deleteCategory = async (id: string) => {
    const response = await api.delete(`/admin/categories/${id}`);
    return response.data;
};

// Admins
export const getAdmins = async () => {
    const response = await api.get('/admin/admins');
    return response.data;
};

export const addAdmin = async (userId: string) => {
    const response = await api.post('/admin/admins', { user_id: userId });
    return response.data;
};

export const removeAdmin = async (id: string) => {
    const response = await api.delete(`/admin/admins/${id}`);
    return response.data;
};
