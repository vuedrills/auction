import { useEffect } from 'react';
import { wsService, WSMessage } from '@/services/websocket';
import { useAuthStore } from '@/stores/authStore';

export function useWebSocket(onMessage?: (message: WSMessage) => void) {
    const { isAuthenticated, token } = useAuthStore();

    useEffect(() => {
        if (!isAuthenticated || !token) return;

        wsService.connect();

        const unsubscribe = onMessage ? wsService.subscribe(onMessage) : undefined;

        return () => {
            if (unsubscribe) unsubscribe();
            // We usually don't want to disconnect the global service 
            // every time a component unmounts, unless it's the only one.
            // But if we want to be clean:
            // wsService.disconnect();
        };
    }, [isAuthenticated, token, onMessage]);

    return {
        send: wsService.send.bind(wsService),
        subscribeToAuction: wsService.subscribeToAuction.bind(wsService),
        unsubscribeFromAuction: wsService.unsubscribeFromAuction.bind(wsService),
    };
}
