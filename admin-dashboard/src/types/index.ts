
export interface UserQueryParams {
    page?: number;
    limit?: number;
    search?: string;
    is_verified?: boolean;
    is_active?: boolean;
    sort_by?: string;
    sort_order?: 'asc' | 'desc';
    town_id?: string;
}

export interface UserListResponse {
    users: User[];
    total: number;
    page: number;
    limit: number;
    total_pages: number;
}

export interface AuctionFilters {
    page?: number;
    limit?: number;
    town_id?: string;
    suburb_id?: string;
    category_id?: string;
    seller_id?: string;
    status?: AuctionStatus | 'all';
    search?: string;
    min_price?: number;
    max_price?: number;
    sort_by?: string;
    sort_order?: string;
}

export interface AuctionListResponse {
    auctions: Auction[];
    total: number;
    page: number;
    limit: number;
    total_pages: number;
}

export interface StoreFilters {
    page?: number;
    limit?: number;
    search?: string;
    is_verified?: boolean;
    is_active?: boolean;
    is_featured?: boolean;
    category_id?: string;
    town_id?: string;
    suburb_id?: string;
    include_inactive?: boolean;
}

export interface StoresResponse {
    stores: Store[];
    total_count: number;
    page: number;
    limit: number;
}
export interface User {
    id: string;
    email: string;
    username: string;
    full_name: string;
    avatar_url?: string;
    phone?: string;
    is_verified: boolean;
    is_active: boolean;
    created_at: string;
    updated_at: string;
    role?: 'admin' | 'moderator' | 'user'; // Assuming this field will be added
    home_town_id?: string;
    home_suburb_id?: string;
    rating: number;
    total_sales: number;
}

export type AuctionStatus = 'draft' | 'pending' | 'active' | 'ending_soon' | 'ended' | 'sold' | 'cancelled';  // 'all' is kept out of main enum to avoid type errors on Auction object, but handled in filter

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
    status: AuctionStatus;
    condition: string;
    start_time?: string;
    end_time?: string;
    images: string[];
    is_featured: boolean;
    allow_offers: boolean;
    created_at: string;
    seller?: User;
    winner?: User;
}

export interface Store {
    id: string;
    user_id: string;
    store_name: string;
    slug: string;
    about?: string;
    logo_url?: string;
    cover_url?: string;
    is_active: boolean;
    is_verified: boolean;
    is_featured: boolean;
    is_stale: boolean;
    total_products: number;
    total_sales: number;
    views: number;
    created_at: string;
    owner?: User;
}

export interface Product {
    id: string;
    store_id: string;
    title: string;
    description?: string;
    price: number;
    pricing_type: string;
    condition: string;
    images: string[];
    stock_quantity: number;
    is_available: boolean;
    views: number;
    created_at: string;
    store?: Store;
}

export interface LoginRequest {
    email: string;
    password: string;
}

export interface AuthResponse {
    token: string;
    expires_at: number;
    user: User;
}

export interface StoreAnalytics {
    id: string;
    store_id: string;
    date: string;
    views: number;
    unique_visitors: number;
    product_views: number;
    enquiries: number;
    whatsapp_clicks: number;
    call_clicks: number;
    follows_gained: number;
}

export interface StoreAnalyticsResponse {
    total_views: number;
    total_enquiries: number;
    total_followers: number;
    total_products: number;
    views_this_week: number;
    views_this_month: number;
    top_products: Product[];
    daily_stats: StoreAnalytics[];
}

