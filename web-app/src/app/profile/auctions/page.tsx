'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import {
    Plus,
    Grid2X2,
    List,
    Filter,
    Clock,
    CheckCircle,
    XCircle,
    Pause,
    Eye,
    Edit,
    Trash2,
    MoreVertical
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
    Card,
    CardContent,
} from '@/components/ui/card';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import { Skeleton } from '@/components/ui/skeleton';
import { AuctionCard } from '@/components/cards/AuctionCard';
import { auctionsService, type Auction, type AuctionStatus } from '@/services/auctions';
import { useAuthStore } from '@/stores/authStore';
import { cn } from '@/lib/utils';

const statusConfig: Record<AuctionStatus, { label: string; icon: React.ElementType; color: string }> = {
    draft: { label: 'Draft', icon: Edit, color: 'bg-muted text-muted-foreground' },
    pending: { label: 'Pending', icon: Pause, color: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-500/20 dark:text-yellow-400' },
    active: { label: 'Active', icon: Clock, color: 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' },
    ending_soon: { label: 'Ending Soon', icon: Clock, color: 'bg-orange-100 text-orange-700 dark:bg-orange-500/20 dark:text-orange-400' },
    ended: { label: 'Ended', icon: CheckCircle, color: 'bg-blue-100 text-blue-700 dark:bg-blue-500/20 dark:text-blue-400' },
    sold: { label: 'Sold', icon: CheckCircle, color: 'bg-primary/10 text-primary' },
    cancelled: { label: 'Cancelled', icon: XCircle, color: 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400' },
};

type FilterStatus = 'all' | AuctionStatus;

export default function MyAuctionsPage() {
    const { user } = useAuthStore();
    const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
    const [statusFilter, setStatusFilter] = useState<FilterStatus>('all');

    const { data: auctionsData, isLoading } = useQuery({
        queryKey: ['my-auctions'],
        queryFn: auctionsService.getMyAuctions,
        enabled: !!user,
    });

    const allAuctions = auctionsData?.auctions || [];

    const filteredAuctions = statusFilter === 'all'
        ? allAuctions
        : allAuctions.filter((a: Auction) => a.status === statusFilter);

    // Stats
    const stats = {
        total: allAuctions.length,
        active: allAuctions.filter((a: Auction) => a.status === 'active' || a.status === 'ending_soon').length,
        sold: allAuctions.filter((a: Auction) => a.status === 'sold').length,
        pending: allAuctions.filter((a: Auction) => a.status === 'pending').length,
    };

    if (!user) {
        return (
            <div className="min-h-screen flex items-center justify-center">
                <div className="text-center">
                    <p className="text-muted-foreground mb-4">Please log in to view your auctions.</p>
                    <Link href="/login">
                        <Button>Log In</Button>
                    </Link>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-background">
            {/* Header */}
            <div className="border-b bg-card">
                <div className="max-w-7xl mx-auto px-4 py-6">
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                        <div>
                            <h1 className="text-2xl font-bold">My Auctions</h1>
                            <p className="text-muted-foreground mt-1">
                                Manage your auction listings
                            </p>
                        </div>
                        <Link href="/auctions/create">
                            <Button>
                                <Plus className="size-4 mr-2" />
                                Create Auction
                            </Button>
                        </Link>
                    </div>
                </div>
            </div>

            {/* Stats Cards */}
            <div className="max-w-7xl mx-auto px-4 py-6">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <Card>
                        <CardContent className="p-4">
                            <p className="text-sm text-muted-foreground">Total Listings</p>
                            <p className="text-2xl font-bold">{stats.total}</p>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardContent className="p-4">
                            <p className="text-sm text-muted-foreground">Active</p>
                            <p className="text-2xl font-bold text-green-600">{stats.active}</p>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardContent className="p-4">
                            <p className="text-sm text-muted-foreground">Sold</p>
                            <p className="text-2xl font-bold text-primary">{stats.sold}</p>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardContent className="p-4">
                            <p className="text-sm text-muted-foreground">In Waiting List</p>
                            <p className="text-2xl font-bold text-yellow-600">{stats.pending}</p>
                        </CardContent>
                    </Card>
                </div>
            </div>

            {/* Toolbar */}
            <div className="max-w-7xl mx-auto px-4 mb-6">
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    {/* Filter Chips */}
                    <div className="flex items-center gap-2 overflow-x-auto no-scrollbar">
                        <Button
                            variant={statusFilter === 'all' ? 'default' : 'outline'}
                            size="sm"
                            onClick={() => setStatusFilter('all')}
                            className="rounded-full"
                        >
                            All ({allAuctions.length})
                        </Button>
                        <Button
                            variant={statusFilter === 'active' ? 'default' : 'outline'}
                            size="sm"
                            onClick={() => setStatusFilter('active')}
                            className="rounded-full"
                        >
                            Active
                        </Button>
                        <Button
                            variant={statusFilter === 'pending' ? 'default' : 'outline'}
                            size="sm"
                            onClick={() => setStatusFilter('pending')}
                            className="rounded-full"
                        >
                            Pending
                        </Button>
                        <Button
                            variant={statusFilter === 'ended' ? 'default' : 'outline'}
                            size="sm"
                            onClick={() => setStatusFilter('ended')}
                            className="rounded-full"
                        >
                            Ended
                        </Button>
                        <Button
                            variant={statusFilter === 'sold' ? 'default' : 'outline'}
                            size="sm"
                            onClick={() => setStatusFilter('sold')}
                            className="rounded-full"
                        >
                            Sold
                        </Button>
                    </div>

                    {/* View Mode Toggle */}
                    <div className="flex items-center rounded-lg border bg-muted/50 p-1">
                        <Button
                            variant={viewMode === 'grid' ? 'default' : 'ghost'}
                            size="icon"
                            className="size-8"
                            onClick={() => setViewMode('grid')}
                        >
                            <Grid2X2 className="size-4" />
                        </Button>
                        <Button
                            variant={viewMode === 'list' ? 'default' : 'ghost'}
                            size="icon"
                            className="size-8"
                            onClick={() => setViewMode('list')}
                        >
                            <List className="size-4" />
                        </Button>
                    </div>
                </div>
            </div>

            {/* Auctions List */}
            <div className="max-w-7xl mx-auto px-4 pb-12">
                {isLoading ? (
                    <div className={cn(
                        'grid gap-6',
                        viewMode === 'grid'
                            ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
                            : 'grid-cols-1'
                    )}>
                        {Array.from({ length: 4 }).map((_, i) => (
                            <div key={i} className="rounded-xl border bg-card overflow-hidden">
                                <Skeleton className="aspect-[4/3]" />
                                <div className="p-4 space-y-3">
                                    <Skeleton className="h-4 w-3/4" />
                                    <Skeleton className="h-4 w-1/2" />
                                    <Skeleton className="h-8 w-full" />
                                </div>
                            </div>
                        ))}
                    </div>
                ) : filteredAuctions.length === 0 ? (
                    <Card className="mt-8">
                        <CardContent className="py-16 text-center">
                            <div className="inline-flex items-center justify-center size-16 rounded-full bg-muted mb-4">
                                <Plus className="size-8 text-muted-foreground" />
                            </div>
                            <h3 className="text-lg font-semibold mb-2">
                                {statusFilter === 'all'
                                    ? 'No auctions yet'
                                    : `No ${statusFilter} auctions`}
                            </h3>
                            <p className="text-muted-foreground mb-6 max-w-md mx-auto">
                                {statusFilter === 'all'
                                    ? "You haven't created any auctions yet. Start selling!"
                                    : `You don't have any ${statusFilter} auctions at the moment.`}
                            </p>
                            <Link href="/auctions/create">
                                <Button>
                                    <Plus className="size-4 mr-2" />
                                    Create Your First Auction
                                </Button>
                            </Link>
                        </CardContent>
                    </Card>
                ) : viewMode === 'grid' ? (
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                        {filteredAuctions.map((auction: Auction) => (
                            <div key={auction.id} className="relative group">
                                <AuctionCard auction={auction} />
                                {/* Status Badge Overlay */}
                                <Badge
                                    className={cn(
                                        'absolute top-2 left-2 z-10',
                                        statusConfig[auction.status]?.color
                                    )}
                                >
                                    {statusConfig[auction.status]?.label}
                                </Badge>
                                {/* Action Menu */}
                                <div className="absolute top-2 right-2 z-10 opacity-0 group-hover:opacity-100 transition-opacity">
                                    <DropdownMenu>
                                        <DropdownMenuTrigger asChild>
                                            <Button variant="secondary" size="icon" className="size-8">
                                                <MoreVertical className="size-4" />
                                            </Button>
                                        </DropdownMenuTrigger>
                                        <DropdownMenuContent align="end">
                                            <DropdownMenuItem asChild>
                                                <Link href={`/auctions/${auction.id}`}>
                                                    <Eye className="size-4 mr-2" />
                                                    View
                                                </Link>
                                            </DropdownMenuItem>
                                            {(auction.status === 'draft' || auction.status === 'pending') && (
                                                <DropdownMenuItem asChild>
                                                    <Link href={`/auctions/${auction.id}/edit`}>
                                                        <Edit className="size-4 mr-2" />
                                                        Edit
                                                    </Link>
                                                </DropdownMenuItem>
                                            )}
                                            <DropdownMenuSeparator />
                                            {auction.status !== 'active' && auction.status !== 'ending_soon' && (
                                                <DropdownMenuItem className="text-destructive">
                                                    <Trash2 className="size-4 mr-2" />
                                                    Delete
                                                </DropdownMenuItem>
                                            )}
                                        </DropdownMenuContent>
                                    </DropdownMenu>
                                </div>
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="space-y-4">
                        {filteredAuctions.map((auction: Auction) => (
                            <Card key={auction.id} className="overflow-hidden">
                                <CardContent className="p-0">
                                    <div className="flex items-center gap-4 p-4">
                                        {/* Image */}
                                        <div className="size-20 rounded-lg bg-muted overflow-hidden shrink-0">
                                            <img
                                                src={auction.images?.[0] || 'https://via.placeholder.com/80'}
                                                alt={auction.title}
                                                className="size-full object-cover"
                                            />
                                        </div>

                                        {/* Info */}
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-center gap-2 mb-1">
                                                <Badge className={statusConfig[auction.status]?.color}>
                                                    {statusConfig[auction.status]?.label}
                                                </Badge>
                                            </div>
                                            <h3 className="font-semibold truncate">{auction.title}</h3>
                                            <p className="text-sm text-muted-foreground">
                                                Current: ${(auction.current_price || auction.starting_price).toFixed(2)}
                                                {auction.total_bids > 0 && ` • ${auction.total_bids} bids`}
                                            </p>
                                        </div>

                                        {/* Actions */}
                                        <div className="flex items-center gap-2">
                                            <Link href={`/auctions/${auction.id}`}>
                                                <Button variant="outline" size="sm">
                                                    <Eye className="size-4 mr-2" />
                                                    View
                                                </Button>
                                            </Link>
                                            <DropdownMenu>
                                                <DropdownMenuTrigger asChild>
                                                    <Button variant="ghost" size="icon">
                                                        <MoreVertical className="size-4" />
                                                    </Button>
                                                </DropdownMenuTrigger>
                                                <DropdownMenuContent align="end">
                                                    {(auction.status === 'draft' || auction.status === 'pending') && (
                                                        <DropdownMenuItem asChild>
                                                            <Link href={`/auctions/${auction.id}/edit`}>
                                                                <Edit className="size-4 mr-2" />
                                                                Edit
                                                            </Link>
                                                        </DropdownMenuItem>
                                                    )}
                                                    {auction.status !== 'active' && auction.status !== 'ending_soon' && (
                                                        <DropdownMenuItem className="text-destructive">
                                                            <Trash2 className="size-4 mr-2" />
                                                            Delete
                                                        </DropdownMenuItem>
                                                    )}
                                                </DropdownMenuContent>
                                            </DropdownMenu>
                                        </div>
                                    </div>
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}
