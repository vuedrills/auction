import api from './api';

export interface ChatMessage {
    id: string;
    conversation_id?: string; // used in shops
    chat_id?: string; // used in auctions
    sender_id: string;
    content: string;
    image_url?: string;
    attachment_url?: string;
    is_read: boolean;
    created_at: string;
    sender_name?: string;
    sender_avatar?: string;
    message_type?: string;
    product_id?: string;
}

export interface AuctionChat {
    id: string;
    auction_id: string;
    auction_title: string;
    auction_image?: string;
    participant_id: string;
    participant_name: string;
    participant_avatar?: string;
    last_message?: {
        content: string;
        created_at: string;
    };
    unread_count: number;
    updated_at: string;
}

export interface ShopChat {
    id: string;
    store_id: string;
    store_name: string;
    store_logo?: string;
    customer_id: string;
    customer_name: string;
    customer_avatar?: string;
    product_id?: string;
    product_title?: string;
    product_image?: string;
    is_store_owner: boolean;
    other_name: string;
    other_avatar?: string;
    last_message?: {
        content: string;
        created_at: string;
    };
    unread_count: number;
    updated_at: string;
}

export type ChatType = 'auction' | 'shop';

export const chatService = {
    // Auction Chats
    getAuctionChats: async (): Promise<AuctionChat[]> => {
        const response = await api.get('/chats');
        return response.data.chats;
    },

    getAuctionMessages: async (chatId: string): Promise<ChatMessage[]> => {
        const response = await api.get(`/chats/${chatId}/messages`);
        return response.data.messages;
    },

    sendAuctionMessage: async (chatId: string, content: string, imageUrl?: string): Promise<ChatMessage> => {
        const response = await api.post(`/chats/${chatId}/messages`, { content, image_url: imageUrl });
        return response.data;
    },

    startAuctionChat: async (auctionId: string, message?: string): Promise<{ id: string; auction_id: string }> => {
        const response = await api.post(`/auctions/${auctionId}/chat`, { message });
        return response.data;
    },

    markAuctionChatRead: async (chatId: string): Promise<void> => {
        await api.put(`/chats/${chatId}/read`);
    },

    // Shop Chats
    getShopChats: async (): Promise<ShopChat[]> => {
        const response = await api.get('/shop-chats');
        return response.data.conversations;
    },

    getShopMessages: async (chatId: string): Promise<ChatMessage[]> => {
        const response = await api.get(`/shop-chats/${chatId}/messages`);
        return response.data.messages;
    },

    sendShopMessage: async (chatId: string, content: string, productId?: string, attachmentUrl?: string): Promise<ChatMessage> => {
        const response = await api.post(`/shop-chats/${chatId}/messages`, {
            content,
            product_id: productId,
            attachment_url: attachmentUrl,
            message_type: 'text'
        });
        return response.data;
    },

    startShopChat: async (storeId: string, productId?: string, message?: string): Promise<{ conversation_id: string }> => {
        const response = await api.post('/shop-chats/start', { store_id: storeId, product_id: productId, message });
        return response.data;
    },

    markShopChatRead: async (chatId: string): Promise<void> => {
        await api.put(`/shop-chats/${chatId}/read`);
    },

    getUnreadCounts: async (): Promise<{ total: number; auction: number; shop: number }> => {
        const [auctionRes, shopRes] = await Promise.all([
            api.get('/chats/unread-count').catch(() => ({ data: { unread_count: 0 } })), // Placeholder if not implemented
            api.get('/shop-chats/unread-count')
        ]);

        const auctionCount = auctionRes.data.unread_count || 0;
        const shopCount = shopRes.data.unread_count || 0;

        return {
            total: auctionCount + shopCount,
            auction: auctionCount,
            shop: shopCount
        };
    }
};
