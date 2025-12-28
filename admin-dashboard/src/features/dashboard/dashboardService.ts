import api from '@/lib/api';

export const getDashboardStats = async (): Promise<{
    total_users: number;
    active_auctions: number;
    total_auctions: number;
    total_sales: number;
    active_stores: number;
    total_bids: number;
}> => {
    const response = await api.get('/admin/stats');
    return response.data;
};
