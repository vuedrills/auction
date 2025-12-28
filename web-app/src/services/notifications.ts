import api from './api';

export interface Notification {
    id: string;
    user_id: string;
    type: string;
    title: string;
    body: string;
    message: string; // alias for body
    related_auction_id?: string;
    data?: any;
    is_read: boolean;
    read: boolean; // alias for is_read
    created_at: string;
    has_rated?: boolean;
}

// Transform backend response to include aliases
const transformNotification = (n: any): Notification => ({
    ...n,
    message: n.body || n.message,
    read: n.is_read ?? n.read ?? false,
});

export const notificationsService = {
    getNotifications: async (): Promise<Notification[]> => {
        const response = await api.get('/notifications');
        const notifications = response.data.notifications || response.data || [];
        return notifications.map(transformNotification);
    },

    getUnreadCount: async (): Promise<number> => {
        const response = await api.get('/notifications/unread-count');
        return response.data.count;
    },

    markAsRead: async (id: string): Promise<void> => {
        await api.put(`/notifications/${id}/read`);
    },

    markAllAsRead: async (): Promise<void> => {
        await api.put('/notifications/read-all');
    },

    deleteNotification: async (id: string): Promise<void> => {
        await api.delete(`/notifications/${id}`);
    },

    getPreferences: async () => {
        const response = await api.get('/users/me/notification-preferences');
        return response.data;
    },

    updatePreferences: async (preferences: { push_enabled: boolean; email_enabled: boolean }) => {
        await api.put('/users/me/notification-preferences', preferences);
    }
};

// Keep backward compatible export
export const notificationService = notificationsService;
