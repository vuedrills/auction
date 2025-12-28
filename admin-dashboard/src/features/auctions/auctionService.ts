import api from '@/lib/api';
import { Auction, AuctionListResponse, AuctionFilters } from '@/types';

export const getAuctions = async (params: AuctionFilters): Promise<AuctionListResponse> => {
    const response = await api.get<AuctionListResponse>('/auctions', { params });
    return response.data;
};

export const getAuction = async (id: string): Promise<Auction> => {
    const response = await api.get<Auction>(`/auctions/${id}`);
    return response.data;
};

export const updateAuction = async (id: string, data: Partial<Auction>): Promise<Auction> => {
    const response = await api.patch<Auction>(`/auctions/${id}`, data);
    return response.data;
};

export const deleteAuction = async (id: string): Promise<void> => {
    await api.delete(`/auctions/${id}`);
};

export const approveAuction = async (id: string): Promise<void> => {
    await api.post(`/auctions/${id}/approve`);
};

export const rejectAuction = async (id: string, reason: string): Promise<void> => {
    await api.post(`/auctions/${id}/reject`, { reason });
};
