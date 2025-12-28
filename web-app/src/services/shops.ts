import api from './api';
import { User } from '@/stores/authStore';
import { Category } from './categories';

export interface StoreCategory {
    id: string;
    name: string;
    display_name: string;
    icon: string;
    sort_order: number;
    is_active: boolean;
}

export interface Store {
    id: string;
    user_id: string;
    store_name: string;
    slug: string;
    tagline?: string;
    about?: string;
    logo_url?: string;
    cover_url?: string;
    category_id?: string;
    whatsapp?: string;
    phone?: string;
    delivery_options: string[];
    delivery_radius_km?: number;
    operating_hours?: string;
    town_id?: string;
    suburb_id?: string;
    address?: string;
    is_active: boolean;
    is_verified: boolean;
    is_featured: boolean;
    is_stale: boolean;
    total_products: number;
    total_sales: number;
    follower_count: number;
    views: number;
    created_at: string;
    updated_at: string;

    // Joined fields
    owner?: User;
    category?: StoreCategory;
    town?: { name: string };
    suburb?: { name: string };
    is_following?: boolean;
}

export interface Product {
    id: string;
    store_id: string;
    title: string;
    description?: string;
    price: number;
    compare_at_price?: number;
    pricing_type: string;
    category_id?: string;
    condition: string;
    images: string[];
    stock_quantity: number;
    is_available: boolean;
    is_featured: boolean;
    views: number;
    enquiries: number;
    created_at: string;
    updated_at: string;
    last_confirmed_at?: string;

    // Joined fields
    store?: Store;
    category?: Category;
}

export interface ShopsResponse {
    stores: Store[];
    total_count: number;
    page: number;
    limit: number;
}

export interface ProductsResponse {
    products: Product[];
    total_count: number;
    page: number;
    limit: number;
}

export interface ShopFilters {
    page?: number;
    limit?: number;
    category?: string;
    town?: string;
    featured?: boolean;
    q?: string;
}

export interface ProductFilters {
    page?: number;
    limit?: number;
    type?: string;
    category?: string;
    sort?: string;
    q?: string;
}

export const shopsService = {
    // Store discovery
    getShops: async (filters: ShopFilters = {}): Promise<ShopsResponse> => {
        const response = await api.get('/stores', { params: filters });
        return response.data;
    },

    getFeaturedShops: async (): Promise<ShopsResponse> => {
        const response = await api.get('/stores/featured');
        return response.data;
    },

    getNearbyShops: async (): Promise<ShopsResponse> => {
        const response = await api.get('/stores/nearby');
        return response.data;
    },

    getShopBySlug: async (slug: string): Promise<Store> => {
        const response = await api.get(`/stores/${slug}`);
        return response.data.store;
    },

    getShopCategories: async (): Promise<StoreCategory[]> => {
        const response = await api.get('/stores/categories');
        return response.data.categories;
    },

    // Store management (Seller)
    getMyShop: async (): Promise<Store> => {
        const response = await api.get('/stores/me');
        return response.data.store;
    },

    createShop: async (data: any): Promise<Store> => {
        const response = await api.post('/stores', data);
        return response.data.store;
    },

    updateShop: async (data: any): Promise<Store> => {
        const response = await api.put('/stores/me', data);
        return response.data.store;
    },

    // Products
    getProducts: async (slug: string, filters: ProductFilters = {}): Promise<ProductsResponse> => {
        const response = await api.get(`/stores/${slug}/products`, { params: filters });
        return response.data;
    },

    getProductById: async (id: string): Promise<Product> => {
        const response = await api.get(`/products/${id}`);
        return response.data.product;
    },

    createProduct: async (data: any): Promise<Product> => {
        const response = await api.post('/stores/me/products', data);
        return response.data.product;
    },

    updateProduct: async (id: string, data: any): Promise<Product> => {
        const response = await api.put(`/products/${id}`, data);
        return response.data.product;
    },

    deleteProduct: async (id: string): Promise<void> => {
        await api.delete(`/products/${id}`);
    },

    confirmProduct: async (id: string): Promise<void> => {
        await api.post(`/products/${id}/confirm`);
    },

    // Follow system
    followShop: async (id: string): Promise<void> => {
        await api.post(`/stores/${id}/follow`);
    },

    unfollowShop: async (id: string): Promise<void> => {
        await api.delete(`/stores/${id}/follow`);
    },

    getFollowingShops: async (): Promise<ShopsResponse> => {
        const response = await api.get('/users/me/following-stores');
        return response.data;
    },

    // Analytics
    trackEvent: async (id: string, eventType: string): Promise<void> => {
        await api.post(`/stores/${id}/track`, { event_type: eventType });
    },

    searchProducts: async (filters: any): Promise<ProductsResponse> => {
        const response = await api.get('/products/search', { params: filters });
        return response.data;
    }
};
