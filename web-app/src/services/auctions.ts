import api from './api';
import { User } from '@/stores/authStore';

export interface Town {
    id: string;
    name: string;
    state?: string;
    country?: string;
}

export interface Suburb {
    id: string;
    name: string;
    town_id: string;
    zip_code?: string;
}

export interface Category {
    id: string;
    name: string;
    slug: string;
    icon_url?: string;
    description?: string;
    parent_id?: string;
}

export type AuctionStatus = 'draft' | 'pending' | 'active' | 'ending_soon' | 'ended' | 'sold' | 'cancelled';

export interface Auction {
    id: string;
    title: string;
    description?: string;
    starting_price: number;
    current_price?: number;
    reserve_price?: number;
    bid_increment: number;
    seller_id: string;
    winner_id?: string;
    category_id: string;
    town_id: string;
    suburb_id?: string;
    status: AuctionStatus;
    condition: string;
    start_time?: string;
    end_time: string;
    original_end_time?: string;
    anti_snipe_minutes: number;
    total_bids: number;
    views: number;
    images: string[];
    is_featured: boolean;
    allow_offers: boolean;
    pickup_location?: string;
    shipping_available: boolean;
    created_at: string;
    updated_at: string;

    // Joined fields
    seller?: User;
    winner?: User;
    category?: Category;
    town?: Town;
    suburb?: Suburb;

    // Computed fields
    time_remaining?: string;
    is_ending_soon?: boolean;
    min_next_bid?: number;
    user_is_high_bidder?: boolean;
    user_has_bid?: boolean;
    tags?: string[];
    is_watched?: boolean;
}

export interface AuctionFilters {
    town_id?: string;
    suburb_id?: string;
    category_id?: string;
    seller_id?: string;
    status?: AuctionStatus;
    search?: string;
    min_price?: number;
    max_price?: number;
    sort_by?: string;
    sort_order?: string;
    page?: number;
    limit?: number;
}

export interface AuctionListResponse {
    auctions: Auction[];
    total: number;
    page: number;
    limit: number;
    total_pages: number;
}

export const auctionsService = {
    getAuctions: async (filters?: AuctionFilters): Promise<AuctionListResponse> => {
        const response = await api.get('/auctions', { params: filters });
        return response.data;
    },

    getAuctionById: async (id: string): Promise<Auction> => {
        const response = await api.get(`/auctions/${id}`);
        return response.data;
    },

    getMyTownAuctions: async (filters?: AuctionFilters): Promise<AuctionListResponse> => {
        const response = await api.get('/auctions/my-town', { params: filters });
        return response.data;
    },

    getNationalAuctions: async (filters?: AuctionFilters): Promise<AuctionListResponse> => {
        const response = await api.get('/auctions/national', { params: filters });
        return response.data;
    },

    createAuction: async (data: any): Promise<Auction> => {
        const response = await api.post('/auctions', data);
        return response.data;
    },

    updateAuction: async (id: string, data: any): Promise<Auction> => {
        const response = await api.put(`/auctions/${id}`, data);
        return response.data;
    },

    deleteAuction: async (id: string): Promise<void> => {
        await api.delete(`/auctions/${id}`);
    },

    getBidHistory: async (id: string): Promise<any[]> => {
        const response = await api.get(`/auctions/${id}/bids`);
        return response.data;
    },

    placeBid: async (id: string, amount: number): Promise<any> => {
        const response = await api.post(`/auctions/${id}/bids`, { amount });
        return response.data;
    },

    // User specific endpoints
    getMyAuctions: async (): Promise<AuctionListResponse> => {
        const response = await api.get('/users/me/auctions');
        return response.data;
    },

    getMyBids: async (): Promise<any[]> => {
        const response = await api.get('/users/me/bids');
        return response.data.bids || [];
    },

    getWonAuctions: async (): Promise<AuctionListResponse> => {
        const response = await api.get('/users/me/won');
        return response.data;
    },

    getWatchlist: async (): Promise<AuctionListResponse> => {
        const response = await api.get('/users/me/watchlist');
        return response.data;
    },

    addToWatchlist: async (id: string): Promise<void> => {
        await api.post(`/users/me/watchlist/${id}`);
    },

    removeFromWatchlist: async (id: string): Promise<void> => {
        await api.delete(`/users/me/watchlist/${id}`);
    },
};
