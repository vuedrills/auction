'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Bell, BellOff, CheckCircle2, Gavel, Store as StoreIcon, Package, Info, Loader2 } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

import { notificationService, Notification } from '@/services/notifications';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useWebSocket } from '@/hooks/useWebSocket';
import { WSMessage } from '@/services/websocket';
import { cn } from '@/lib/utils';

export function NotificationCenter() {
    const router = useRouter();
    const queryClient = useQueryClient();

    const { data: notifications, isLoading } = useQuery({
        queryKey: ['notifications'],
        queryFn: notificationService.getNotifications,
    });

    const { data: unreadCount = 0 } = useQuery({
        queryKey: ['notifications', 'unread-count'],
        queryFn: notificationService.getUnreadCount,
    });

    const markAsReadMutation = useMutation({
        mutationFn: (id: string) => notificationService.markAsRead(id),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['notifications'] });
        },
    });

    const markAllAsReadMutation = useMutation({
        mutationFn: () => notificationService.markAllAsRead(),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['notifications'] });
        },
    });

    useWebSocket((msg: WSMessage) => {
        if (msg.type === 'notification:new') {
            queryClient.invalidateQueries({ queryKey: ['notifications'] });
        }
    });

    const getIcon = (type: string) => {
        switch (type) {
            case 'bid_outbid':
            case 'auction_ending':
            case 'auction_won':
                return <Gavel className="size-4 text-primary" />;
            case 'shop_order':
            case 'product_inquiry':
                return <StoreIcon className="size-4 text-blue-500" />;
            case 'system_announcement':
                return <Info className="size-4 text-orange-500" />;
            default:
                return <Bell className="size-4 text-muted-foreground" />;
        }
    };

    const handleNotificationClick = (notif: Notification) => {
        if (!notif.is_read) {
            markAsReadMutation.mutate(notif.id);
        }

        // Navigate based on type
        if (notif.related_auction_id) {
            router.push(`/auctions/${notif.related_auction_id}`);
        } else if (notif.data?.chat_id) {
            router.push('/messages');
        }
    };

    return (
        <DropdownMenu>
            <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="relative h-10 w-10 mt-1">
                    <Bell className="size-5" />
                    {unreadCount > 0 && (
                        <Badge className="absolute -top-1 -right-1 size-5 p-0 flex items-center justify-center text-[10px] font-bold ring-2 ring-background">
                            {unreadCount > 9 ? '9+' : unreadCount}
                        </Badge>
                    )}
                </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-80 md:w-96 p-0 rounded-2xl overflow-hidden shadow-2xl border-none">
                <div className="flex items-center justify-between p-4 bg-muted/30">
                    <DropdownMenuLabel className="p-0 font-black text-lg">Notifications</DropdownMenuLabel>
                    <Button
                        variant="ghost"
                        size="sm"
                        className="h-8 text-xs font-bold hover:bg-primary/10 hover:text-primary rounded-lg"
                        onClick={() => markAllAsReadMutation.mutate()}
                    >
                        Mark all as read
                    </Button>
                </div>
                <DropdownMenuSeparator className="m-0" />

                <div className="max-h-[70vh] overflow-y-auto">
                    {isLoading ? (
                        <div className="p-12 text-center">
                            <Loader2 className="size-8 animate-spin mx-auto text-primary/30" />
                        </div>
                    ) : notifications && notifications.length > 0 ? (
                        notifications.map((notif) => (
                            <DropdownMenuItem
                                key={notif.id}
                                className={cn(
                                    "p-4 cursor-pointer gap-4 focus:bg-muted/50 transition-colors",
                                    !notif.is_read && "bg-primary/[0.03]"
                                )}
                                onClick={() => handleNotificationClick(notif)}
                            >
                                <div className={cn(
                                    "size-10 rounded-xl flex items-center justify-center flex-shrink-0",
                                    !notif.is_read ? "bg-primary/10" : "bg-muted"
                                )}>
                                    {getIcon(notif.type)}
                                </div>
                                <div className="flex-1 space-y-1">
                                    <div className="flex items-start justify-between gap-2">
                                        <p className={cn(
                                            "text-sm font-bold leading-none",
                                            !notif.is_read ? "text-foreground" : "text-muted-foreground"
                                        )}>
                                            {notif.title}
                                        </p>
                                        {!notif.is_read && (
                                            <div className="size-2 rounded-full bg-primary flex-shrink-0" />
                                        )}
                                    </div>
                                    <p className="text-xs text-muted-foreground line-clamp-2 leading-relaxed">
                                        {notif.body}
                                    </p>
                                    <p className="text-[10px] text-muted-foreground/60 font-medium">
                                        {formatDistanceToNow(new Date(notif.created_at), { addSuffix: true })}
                                    </p>
                                </div>
                            </DropdownMenuItem>
                        ))
                    ) : (
                        <div className="p-12 text-center space-y-4 opacity-50">
                            <BellOff className="size-12 mx-auto" />
                            <p className="font-bold">No notifications yet</p>
                        </div>
                    )}
                </div>

                <DropdownMenuSeparator className="m-0" />
                <Button
                    variant="ghost"
                    className="w-full h-12 rounded-none text-sm font-bold opacity-70 hover:opacity-100"
                    onClick={() => router.push('/notifications')}
                >
                    View all notifications
                </Button>
            </DropdownMenuContent>
        </DropdownMenu>
    );
}
