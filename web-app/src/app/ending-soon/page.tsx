'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
    Timer,
    Grid2X2,
    List,
    Flame,
    Clock,
    AlertTriangle,
    Zap
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { AuctionCard } from '@/components/cards/AuctionCard';
import { auctionsService, type AuctionFilters, type Auction } from '@/services/auctions';
import { useTownStore } from '@/stores/townStore';
import { cn } from '@/lib/utils';
import Link from 'next/link';

export default function EndingSoonPage() {
    const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
    const { selectedTown } = useTownStore();

    // Fetch auctions ending soon (sorted by end time)
    const filters: AuctionFilters = {
        town_id: selectedTown?.id,
        sort_by: 'end_time',
        sort_order: 'asc',
        status: 'active',
    };

    const { data: auctionsData, isLoading } = useQuery({
        queryKey: ['auctions', 'ending-soon', filters],
        queryFn: () => auctionsService.getAuctions(filters),
    });

    // Filter to only show auctions ending within 24 hours
    const now = new Date();
    const twentyFourHoursFromNow = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    const endingSoonAuctions = (auctionsData?.auctions || []).filter((auction: Auction) => {
        const endTime = new Date(auction.end_time);
        return endTime <= twentyFourHoursFromNow && endTime > now;
    });

    // Group by urgency
    const criticalAuctions = endingSoonAuctions.filter((auction: Auction) => {
        const endTime = new Date(auction.end_time);
        const hoursLeft = (endTime.getTime() - now.getTime()) / (1000 * 60 * 60);
        return hoursLeft <= 1;
    });

    const urgentAuctions = endingSoonAuctions.filter((auction: Auction) => {
        const endTime = new Date(auction.end_time);
        const hoursLeft = (endTime.getTime() - now.getTime()) / (1000 * 60 * 60);
        return hoursLeft > 1 && hoursLeft <= 6;
    });

    const soonAuctions = endingSoonAuctions.filter((auction: Auction) => {
        const endTime = new Date(auction.end_time);
        const hoursLeft = (endTime.getTime() - now.getTime()) / (1000 * 60 * 60);
        return hoursLeft > 6;
    });

    return (
        <div className="min-h-screen bg-background">
            {/* Hero Banner */}
            <div className="relative bg-gradient-to-r from-orange-500/20 via-red-500/15 to-background py-12 px-4 mb-8 overflow-hidden">
                <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_80%,rgba(255,100,50,0.2),transparent_50%)]" />
                {/* Animated pulse effect */}
                <div className="absolute top-1/2 left-1/4 size-32 bg-orange-500/20 rounded-full blur-3xl animate-pulse" />
                <div className="max-w-7xl mx-auto relative">
                    {/* Title Section */}
                    <div className="flex items-center gap-4">
                        <div className="p-4 rounded-2xl bg-gradient-to-br from-orange-500/30 to-red-500/30 text-orange-600 dark:text-orange-400 relative">
                            <Timer className="size-8" />
                            <span className="absolute -top-1 -right-1 size-3 bg-red-500 rounded-full animate-ping" />
                            <span className="absolute -top-1 -right-1 size-3 bg-red-500 rounded-full" />
                        </div>
                        <div>
                            <h1 className="text-3xl font-bold tracking-tight flex items-center gap-2">
                                Ending Soon
                                <Flame className="size-6 text-orange-500 animate-pulse" />
                            </h1>
                            <p className="text-muted-foreground mt-1">
                                Don&apos;t miss out! These auctions are closing within 24 hours
                            </p>
                            <div className="flex items-center gap-3 mt-2">
                                <Badge variant="destructive" className="rounded-full animate-pulse">
                                    <AlertTriangle className="size-3 mr-1" />
                                    {criticalAuctions.length} ending in &lt; 1 hour
                                </Badge>
                                <Badge variant="secondary" className="rounded-full">
                                    {endingSoonAuctions.length} total
                                </Badge>
                                {selectedTown && (
                                    <Badge variant="outline" className="rounded-full">
                                        in {selectedTown.name}
                                    </Badge>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Toolbar */}
            <div className="max-w-7xl mx-auto px-4 mb-6">
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    {/* Stats */}
                    <div className="flex items-center gap-4">
                        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-red-100 dark:bg-red-500/20 text-red-600 dark:text-red-400 text-sm font-medium">
                            <Zap className="size-4" />
                            {criticalAuctions.length} critical
                        </div>
                        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-orange-100 dark:bg-orange-500/20 text-orange-600 dark:text-orange-400 text-sm font-medium">
                            <Clock className="size-4" />
                            {urgentAuctions.length} urgent
                        </div>
                        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-yellow-100 dark:bg-yellow-500/20 text-yellow-600 dark:text-yellow-400 text-sm font-medium">
                            <Timer className="size-4" />
                            {soonAuctions.length} soon
                        </div>
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

            {/* Content */}
            <div className="max-w-7xl mx-auto px-4 pb-12 space-y-8">
                {isLoading ? (
                    <div className={cn(
                        'grid gap-6',
                        viewMode === 'grid'
                            ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
                            : 'grid-cols-1'
                    )}>
                        {Array.from({ length: 8 }).map((_, i) => (
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
                ) : endingSoonAuctions.length === 0 ? (
                    <div className="text-center py-16">
                        <div className="inline-flex items-center justify-center size-20 rounded-full bg-muted mb-6">
                            <Timer className="size-10 text-muted-foreground" />
                        </div>
                        <h3 className="text-xl font-semibold mb-2">No auctions ending soon</h3>
                        <p className="text-muted-foreground mb-6 max-w-md mx-auto">
                            There are no auctions ending within the next 24 hours
                            {selectedTown && ` in ${selectedTown.name}`}. Check back later!
                        </p>
                        <Button asChild>
                            <Link href="/">
                                Browse All Auctions
                            </Link>
                        </Button>
                    </div>
                ) : (
                    <>
                        {/* Critical - Less than 1 hour */}
                        {criticalAuctions.length > 0 && (
                            <section>
                                <div className="flex items-center gap-2 mb-4">
                                    <div className="size-3 bg-red-500 rounded-full animate-pulse" />
                                    <h2 className="text-lg font-semibold text-red-600 dark:text-red-400">
                                        Ending in less than 1 hour
                                    </h2>
                                </div>
                                <div className={cn(
                                    'grid gap-6',
                                    viewMode === 'grid'
                                        ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
                                        : 'grid-cols-1'
                                )}>
                                    {criticalAuctions.map((auction) => (
                                        <AuctionCard
                                            key={auction.id}
                                            auction={auction}
                                            variant={viewMode === 'list' ? 'horizontal' : 'default'}
                                            urgent
                                        />
                                    ))}
                                </div>
                            </section>
                        )}

                        {/* Urgent - 1-6 hours */}
                        {urgentAuctions.length > 0 && (
                            <section>
                                <div className="flex items-center gap-2 mb-4">
                                    <div className="size-3 bg-orange-500 rounded-full" />
                                    <h2 className="text-lg font-semibold text-orange-600 dark:text-orange-400">
                                        Ending in 1-6 hours
                                    </h2>
                                </div>
                                <div className={cn(
                                    'grid gap-6',
                                    viewMode === 'grid'
                                        ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
                                        : 'grid-cols-1'
                                )}>
                                    {urgentAuctions.map((auction) => (
                                        <AuctionCard
                                            key={auction.id}
                                            auction={auction}
                                            variant={viewMode === 'list' ? 'horizontal' : 'default'}
                                        />
                                    ))}
                                </div>
                            </section>
                        )}

                        {/* Soon - 6-24 hours */}
                        {soonAuctions.length > 0 && (
                            <section>
                                <div className="flex items-center gap-2 mb-4">
                                    <div className="size-3 bg-yellow-500 rounded-full" />
                                    <h2 className="text-lg font-semibold text-yellow-600 dark:text-yellow-400">
                                        Ending in 6-24 hours
                                    </h2>
                                </div>
                                <div className={cn(
                                    'grid gap-6',
                                    viewMode === 'grid'
                                        ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
                                        : 'grid-cols-1'
                                )}>
                                    {soonAuctions.map((auction) => (
                                        <AuctionCard
                                            key={auction.id}
                                            auction={auction}
                                            variant={viewMode === 'list' ? 'horizontal' : 'default'}
                                        />
                                    ))}
                                </div>
                            </section>
                        )}
                    </>
                )}
            </div>
        </div>
    );
}
