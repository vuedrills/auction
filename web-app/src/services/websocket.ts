import { useAuthStore } from '@/stores/authStore';

export type WSMessageType =
    | 'subscribe'
    | 'unsubscribe'
    | 'ping'
    | 'bid:new'
    | 'bid:outbid'
    | 'auction:ending'
    | 'auction:ended'
    | 'auction:won'
    | 'auction:sold'
    | 'auction:update'
    | 'notification:new'
    | 'message:new'
    | 'shop_message:new'
    | 'error'
    | 'pong';

export interface WSMessage {
    type: WSMessageType;
    auction_id?: string;
    user_id?: string;
    data?: any;
}

class WebSocketService {
    private socket: WebSocket | null = null;
    private listeners: Set<(message: WSMessage) => void> = new Set();
    private reconnectTimeout: NodeJS.Timeout | null = null;
    private url: string = '';

    constructor() {
        const baseUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';
        this.url = baseUrl.replace('http', 'ws').replace('/api', '/ws');
    }

    connect() {
        if (this.socket?.readyState === WebSocket.OPEN) return;

        const token = useAuthStore.getState().token;
        if (!token) return;

        this.socket = new WebSocket(`${this.url}?token=${token}`);

        this.socket.onopen = () => {
            console.log('WebSocket Connected');
            if (this.reconnectTimeout) {
                clearTimeout(this.reconnectTimeout);
                this.reconnectTimeout = null;
            }
            this.send({ type: 'ping' });
        };

        this.socket.onmessage = (event) => {
            try {
                const message: WSMessage = JSON.parse(event.data);
                this.listeners.forEach(listener => listener(message));
            } catch (error) {
                console.error('Failed to parse WS message:', error);
            }
        };

        this.socket.onclose = () => {
            console.log('WebSocket Disconnected');
            this.reconnect();
        };

        this.socket.onerror = (error) => {
            console.error('WebSocket Error:', error);
        };
    }

    private reconnect() {
        if (this.reconnectTimeout) return;
        this.reconnectTimeout = setTimeout(() => {
            this.reconnectTimeout = null;
            this.connect();
        }, 5000);
    }

    disconnect() {
        if (this.socket) {
            this.socket.close();
            this.socket = null;
        }
    }

    send(message: WSMessage) {
        if (this.socket?.readyState === WebSocket.OPEN) {
            this.socket.send(JSON.stringify(message));
        } else {
            console.warn('Socket not open, message not sent:', message);
        }
    }

    subscribe(callback: (message: WSMessage) => void) {
        this.listeners.add(callback);
        return () => this.listeners.delete(callback);
    }

    subscribeToAuction(id: string) {
        this.send({ type: 'subscribe', auction_id: id });
    }

    unsubscribeFromAuction(id: string) {
        this.send({ type: 'unsubscribe', auction_id: id });
    }
}

export const wsService = new WebSocketService();
