'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
    Globe2,
    Grid2X2,
    List,
    SlidersHorizontal,
    Clock,
    Flame,
    DollarSign,
    ArrowUpDown,
    MapPin
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import { Skeleton } from '@/components/ui/skeleton';
import { AuctionCard } from '@/components/cards/AuctionCard';
import { auctionsService, type AuctionFilters } from '@/services/auctions';
import { cn } from '@/lib/utils';
import Link from 'next/link';

type SortOption = 'ending_soon' | 'newest' | 'price_low' | 'price_high' | 'most_bids';

export default function NationalPage() {
    const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
    const [sortBy, setSortBy] = useState<SortOption>('ending_soon');

    // Build filters for national auctions
    const filters: AuctionFilters = {
        sort_by: sortBy === 'ending_soon' ? 'end_time' :
            sortBy === 'newest' ? 'created_at' :
                sortBy === 'price_low' || sortBy === 'price_high' ? 'current_price' :
                    sortBy === 'most_bids' ? 'total_bids' : 'end_time',
        sort_order: sortBy === 'price_low' ? 'asc' : 'desc',
        status: 'active',
    };

    // Fetch national auctions
    const { data: auctionsData, isLoading } = useQuery({
        queryKey: ['auctions', 'national', filters],
        queryFn: () => auctionsService.getNationalAuctions(filters),
    });

    const auctions = auctionsData?.auctions || [];

    const sortOptions: { value: SortOption; label: string; icon: React.ElementType }[] = [
        { value: 'ending_soon', label: 'Ending Soon', icon: Clock },
        { value: 'newest', label: 'Newest', icon: Flame },
        { value: 'price_low', label: 'Price: Low to High', icon: DollarSign },
        { value: 'price_high', label: 'Price: High to Low', icon: DollarSign },
        { value: 'most_bids', label: 'Most Bids', icon: ArrowUpDown },
    ];

    return (
        <div className="min-h-screen bg-background">
            {/* Hero Banner */}
            <div className="relative bg-gradient-to-r from-blue-500/20 via-purple-500/10 to-background py-12 px-4 mb-8">
                <div className="absolute inset-0 bg-[radial-gradient(circle_at_70%_30%,rgba(100,100,255,0.15),transparent_70%)]" />
                <div className="max-w-7xl mx-auto relative">
                    {/* Title Section */}
                    <div className="flex items-center gap-4">
                        <div className="p-4 rounded-2xl bg-gradient-to-br from-blue-500/30 to-purple-500/30 text-blue-600 dark:text-blue-400">
                            <Globe2 className="size-8" />
                        </div>
                        <div>
                            <h1 className="text-3xl font-bold tracking-tight">
                                National Auctions
                            </h1>
                            <p className="text-muted-foreground mt-1">
                                Browse auctions from all locations across Zimbabwe
                            </p>
                            <div className="flex items-center gap-3 mt-2">
                                <Badge variant="secondary" className="rounded-full">
                                    <Globe2 className="size-3 mr-1" />
                                    {auctionsData?.total || 0} auctions nationwide
                                </Badge>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Quick Location Links */}
            <div className="max-w-7xl mx-auto px-4 mb-6">
                <div className="flex items-center gap-2 overflow-x-auto py-2 no-scrollbar">
                    <Badge variant="outline" className="cursor-pointer hover:bg-primary/10 transition-colors">
                        <MapPin className="size-3 mr-1" />
                        All Locations
                    </Badge>
                    <Badge variant="outline" className="cursor-pointer hover:bg-primary/10 transition-colors whitespace-nowrap">
                        Harare
                    </Badge>
                    <Badge variant="outline" className="cursor-pointer hover:bg-primary/10 transition-colors whitespace-nowrap">
                        Bulawayo
                    </Badge>
                    <Badge variant="outline" className="cursor-pointer hover:bg-primary/10 transition-colors whitespace-nowrap">
                        Mutare
                    </Badge>
                    <Badge variant="outline" className="cursor-pointer hover:bg-primary/10 transition-colors whitespace-nowrap">
                        Gweru
                    </Badge>
                    <Badge variant="outline" className="cursor-pointer hover:bg-primary/10 transition-colors whitespace-nowrap">
                        Masvingo
                    </Badge>
                </div>
            </div>

            {/* Toolbar */}
            <div className="max-w-7xl mx-auto px-4 mb-6">
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    {/* Results Count */}
                    <p className="text-sm text-muted-foreground">
                        Showing <span className="font-medium text-foreground">{auctions.length}</span> of{' '}
                        <span className="font-medium text-foreground">{auctionsData?.total || 0}</span> national auctions
                    </p>

                    {/* Controls */}
                    <div className="flex items-center gap-3">
                        {/* Sort */}
                        <Select value={sortBy} onValueChange={(value) => setSortBy(value as SortOption)}>
                            <SelectTrigger className="w-[180px]">
                                <SelectValue placeholder="Sort by" />
                            </SelectTrigger>
                            <SelectContent>
                                {sortOptions.map((option) => (
                                    <SelectItem key={option.value} value={option.value}>
                                        <div className="flex items-center gap-2">
                                            <option.icon className="size-4" />
                                            {option.label}
                                        </div>
                                    </SelectItem>
                                ))}
                            </SelectContent>
                        </Select>

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
            </div>

            {/* Auctions Grid */}
            <div className="max-w-7xl mx-auto px-4 pb-12">
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
                ) : auctions.length === 0 ? (
                    <div className="text-center py-16">
                        <div className="inline-flex items-center justify-center size-20 rounded-full bg-muted mb-6">
                            <Globe2 className="size-10 text-muted-foreground" />
                        </div>
                        <h3 className="text-xl font-semibold mb-2">No national auctions found</h3>
                        <p className="text-muted-foreground mb-6 max-w-md mx-auto">
                            There are no national auctions available at the moment. Check back later or create your own!
                        </p>
                        <Button asChild>
                            <Link href="/auctions/create">
                                Create Auction
                            </Link>
                        </Button>
                    </div>
                ) : (
                    <div className={cn(
                        'grid gap-6',
                        viewMode === 'grid'
                            ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
                            : 'grid-cols-1'
                    )}>
                        {auctions.map((auction) => (
                            <AuctionCard
                                key={auction.id}
                                auction={auction}
                                variant={viewMode === 'list' ? 'horizontal' : 'default'}
                                showLocation
                            />
                        ))}
                    </div>
                )}

                {/* Pagination placeholder */}
                {auctionsData && auctionsData.total_pages > 1 && (
                    <div className="flex justify-center mt-8">
                        <p className="text-sm text-muted-foreground">
                            Page 1 of {auctionsData.total_pages} • More pagination coming soon
                        </p>
                    </div>
                )}
            </div>
        </div>
    );
}
