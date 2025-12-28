import api from '@/lib/api';
import { StoreAnalyticsResponse } from '@/types';

export const getStoreAnalytics = async (storeId: string): Promise<StoreAnalyticsResponse> => {
    const response = await api.get<StoreAnalyticsResponse>(`/analytics/store/${storeId}`);
    return response.data;
};
