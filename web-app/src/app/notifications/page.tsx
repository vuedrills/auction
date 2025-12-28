'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { formatDistanceToNow } from 'date-fns';
import {
    Bell,
    BellOff,
    Check,
    CheckCheck,
    Trash2,
    Gavel,
    MessageSquare,
    DollarSign,
    Trophy,
    AlertCircle,
    Settings,
    Filter
} from 'lucide-react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from '@/components/ui/card';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Skeleton } from '@/components/ui/skeleton';
import { useToast } from '@/hooks/use-toast';
import { notificationsService, type Notification } from '@/services/notifications';
import { cn } from '@/lib/utils';

const notificationIcons: Record<string, React.ElementType> = {
    bid: Gavel,
    outbid: DollarSign,
    message: MessageSquare,
    won: Trophy,
    default: Bell,
};

const notificationColors: Record<string, string> = {
    bid: 'bg-blue-100 text-blue-600 dark:bg-blue-500/20 dark:text-blue-400',
    outbid: 'bg-orange-100 text-orange-600 dark:bg-orange-500/20 dark:text-orange-400',
    message: 'bg-green-100 text-green-600 dark:bg-green-500/20 dark:text-green-400',
    won: 'bg-yellow-100 text-yellow-600 dark:bg-yellow-500/20 dark:text-yellow-400',
    default: 'bg-muted text-muted-foreground',
};

type FilterType = 'all' | 'unread' | 'bid' | 'message' | 'won';

export default function NotificationsPage() {
    const { toast } = useToast();
    const queryClient = useQueryClient();
    const [filter, setFilter] = useState<FilterType>('all');

    const { data: notifications = [], isLoading } = useQuery({
        queryKey: ['notifications'],
        queryFn: notificationsService.getNotifications,
    });

    const markAsReadMutation = useMutation({
        mutationFn: (id: string) => notificationsService.markAsRead(id),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['notifications'] });
        },
    });

    const markAllAsReadMutation = useMutation({
        mutationFn: notificationsService.markAllAsRead,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['notifications'] });
            toast({
                title: 'All caught up!',
                description: 'All notifications marked as read.',
            });
        },
    });

    const deleteNotificationMutation = useMutation({
        mutationFn: (id: string) => notificationsService.deleteNotification(id),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['notifications'] });
            toast({
                title: 'Notification deleted',
            });
        },
    });

    const filteredNotifications = notifications.filter((notification: Notification) => {
        if (filter === 'all') return true;
        if (filter === 'unread') return !notification.read;
        return notification.type === filter;
    });

    const unreadCount = notifications.filter((n: Notification) => !n.read).length;

    return (
        <div className="min-h-screen bg-background">
            {/* Header */}
            <div className="border-b bg-card">
                <div className="max-w-3xl mx-auto px-4 py-6">
                    <div className="flex items-center justify-between">
                        <div>
                            <h1 className="text-2xl font-bold flex items-center gap-2">
                                Notifications
                                {unreadCount > 0 && (
                                    <Badge variant="destructive" className="rounded-full">
                                        {unreadCount} new
                                    </Badge>
                                )}
                            </h1>
                            <p className="text-muted-foreground mt-1">
                                Stay updated on your auctions and messages
                            </p>
                        </div>
                        <div className="flex items-center gap-2">
                            {unreadCount > 0 && (
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => markAllAsReadMutation.mutate()}
                                    disabled={markAllAsReadMutation.isPending}
                                >
                                    <CheckCheck className="size-4 mr-2" />
                                    Mark all read
                                </Button>
                            )}
                            <Link href="/settings">
                                <Button variant="ghost" size="icon">
                                    <Settings className="size-4" />
                                </Button>
                            </Link>
                        </div>
                    </div>
                </div>
            </div>

            {/* Filters */}
            <div className="max-w-3xl mx-auto px-4 py-4">
                <div className="flex items-center gap-2 overflow-x-auto no-scrollbar">
                    {[
                        { value: 'all', label: 'All' },
                        { value: 'unread', label: 'Unread' },
                        { value: 'bid', label: 'Bids' },
                        { value: 'message', label: 'Messages' },
                        { value: 'won', label: 'Wins' },
                    ].map((option) => (
                        <Button
                            key={option.value}
                            variant={filter === option.value ? 'default' : 'outline'}
                            size="sm"
                            onClick={() => setFilter(option.value as FilterType)}
                            className="rounded-full"
                        >
                            {option.label}
                        </Button>
                    ))}
                </div>
            </div>

            {/* Notifications List */}
            <div className="max-w-3xl mx-auto px-4 pb-12">
                {isLoading ? (
                    <div className="space-y-4">
                        {Array.from({ length: 5 }).map((_, i) => (
                            <Card key={i}>
                                <CardContent className="p-4">
                                    <div className="flex items-start gap-4">
                                        <Skeleton className="size-10 rounded-full" />
                                        <div className="flex-1 space-y-2">
                                            <Skeleton className="h-4 w-3/4" />
                                            <Skeleton className="h-3 w-1/2" />
                                        </div>
                                    </div>
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                ) : filteredNotifications.length === 0 ? (
                    <Card className="mt-8">
                        <CardContent className="py-16 text-center">
                            <div className="inline-flex items-center justify-center size-16 rounded-full bg-muted mb-4">
                                <BellOff className="size-8 text-muted-foreground" />
                            </div>
                            <h3 className="text-lg font-semibold mb-2">
                                {filter === 'all' ? 'No notifications yet' : `No ${filter} notifications`}
                            </h3>
                            <p className="text-muted-foreground">
                                {filter === 'all'
                                    ? "When you receive notifications, they'll appear here."
                                    : `You don't have any ${filter} notifications at the moment.`}
                            </p>
                        </CardContent>
                    </Card>
                ) : (
                    <div className="space-y-2">
                        {filteredNotifications.map((notification: Notification) => {
                            const Icon = notificationIcons[notification.type] || notificationIcons.default;
                            const colorClass = notificationColors[notification.type] || notificationColors.default;

                            return (
                                <Card
                                    key={notification.id}
                                    className={cn(
                                        'transition-colors cursor-pointer hover:bg-muted/50',
                                        !notification.read && 'border-primary/30 bg-primary/5'
                                    )}
                                    onClick={() => {
                                        if (!notification.read) {
                                            markAsReadMutation.mutate(notification.id);
                                        }
                                    }}
                                >
                                    <CardContent className="p-4">
                                        <div className="flex items-start gap-4">
                                            <div className={cn('size-10 rounded-full flex items-center justify-center', colorClass)}>
                                                <Icon className="size-5" />
                                            </div>
                                            <div className="flex-1 min-w-0">
                                                <div className="flex items-start justify-between gap-2">
                                                    <div>
                                                        <p className={cn(
                                                            'font-medium',
                                                            !notification.read && 'font-semibold'
                                                        )}>
                                                            {notification.title}
                                                        </p>
                                                        <p className="text-sm text-muted-foreground line-clamp-2">
                                                            {notification.message}
                                                        </p>
                                                    </div>
                                                    <DropdownMenu>
                                                        <DropdownMenuTrigger asChild>
                                                            <Button
                                                                variant="ghost"
                                                                size="icon"
                                                                className="size-8 shrink-0"
                                                                onClick={(e) => e.stopPropagation()}
                                                            >
                                                                <span className="sr-only">More options</span>
                                                                ···
                                                            </Button>
                                                        </DropdownMenuTrigger>
                                                        <DropdownMenuContent align="end">
                                                            {!notification.read && (
                                                                <DropdownMenuItem
                                                                    onClick={(e) => {
                                                                        e.stopPropagation();
                                                                        markAsReadMutation.mutate(notification.id);
                                                                    }}
                                                                >
                                                                    <Check className="size-4 mr-2" />
                                                                    Mark as read
                                                                </DropdownMenuItem>
                                                            )}
                                                            <DropdownMenuItem
                                                                className="text-destructive"
                                                                onClick={(e) => {
                                                                    e.stopPropagation();
                                                                    deleteNotificationMutation.mutate(notification.id);
                                                                }}
                                                            >
                                                                <Trash2 className="size-4 mr-2" />
                                                                Delete
                                                            </DropdownMenuItem>
                                                        </DropdownMenuContent>
                                                    </DropdownMenu>
                                                </div>
                                                <p className="text-xs text-muted-foreground mt-1">
                                                    {formatDistanceToNow(new Date(notification.created_at), { addSuffix: true })}
                                                </p>
                                            </div>
                                            {!notification.read && (
                                                <div className="size-2 rounded-full bg-primary shrink-0 mt-2" />
                                            )}
                                        </div>
                                    </CardContent>
                                </Card>
                            );
                        })}
                    </div>
                )}
            </div>
        </div>
    );
}
