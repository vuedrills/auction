'use client';

import { useState } from 'react';
import { AuctionCard } from '@/components/cards/AuctionCard';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Pagination } from '@/components/ui/pagination';
import {
    Gavel,
    TrendingUp,
    Clock,
    Plus,
    ChevronRight,
    Grid3X3,
    Smartphone,
    Car,
    Home,
    Shirt,
    Gem,
    Briefcase,
    Dumbbell,
    Baby,
    TreePine,
    Package
} from 'lucide-react';
import Link from 'next/link';
import { useSearchParams, useRouter } from 'next/navigation';
import { cn } from '@/lib/utils';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { auctionsService } from '@/services/auctions';
import { categoriesService } from '@/services/categories'; // Import categoriesService
import { useTownStore } from '@/stores/townStore';
import { useAuthStore } from '@/stores/authStore';
import { toast } from 'sonner';

const ITEMS_PER_PAGE = 12;

const CATEGORY_ICONS: Record<string, any> = {
    electronics: Smartphone,
    vehicles: Car,
    property: Home,
    fashion: Shirt,
    jewelry: Gem,
    services: Briefcase,
    sports: Dumbbell,
    kids: Baby,
    outdoors: TreePine,
    furniture: Grid3X3,
};
export default function HomePage() {
    const { selectedTown, selectedSuburb } = useTownStore();
    const { user } = useAuthStore();
    const searchParams = useSearchParams();
    const searchQuery = searchParams.get('search') || '';

    // Pagination state
    const [townPage, setTownPage] = useState(1);
    const [nationalPage, setNationalPage] = useState(1);
    const [selectedCategory, setSelectedCategory] = useState<string | null>(null);

    // Fetch categories
    const { data: categories } = useQuery({
        queryKey: ['categories'],
        queryFn: categoriesService.getCategories,
    });

    // Use selected town, or fallback to user's home town
    const townId = selectedTown?.id || user?.home_town_id;
    const suburbId = selectedSuburb?.id || user?.home_suburb_id;

    // Queries
    const { data: townResponse, isLoading: isLoadingTown } = useQuery({
        queryKey: ['auctions', 'mytown', townId, suburbId, searchQuery, townPage],
        queryFn: () => auctionsService.getAuctions({
            town_id: townId,
            suburb_id: suburbId,
            status: 'active',
            search: searchQuery || undefined,
            page: townPage,
            limit: ITEMS_PER_PAGE,
            category_id: selectedCategory || undefined, // Add category filter
        }),
        enabled: !!townId,
    });

    const { data: nationalResponse, isLoading: isLoadingNational } = useQuery({
        queryKey: ['auctions', 'national', townId, suburbId, searchQuery, nationalPage, selectedCategory],
        queryFn: () => auctionsService.getNationalAuctions({
            status: 'active',
            search: searchQuery || undefined,
            town_id: townId || undefined,
            suburb_id: suburbId || undefined,
            page: nationalPage,
            limit: ITEMS_PER_PAGE,
            category_id: selectedCategory || undefined,
        }),
    });

    const townAuctions = townResponse?.auctions || [];
    const nationalAuctions = nationalResponse?.auctions || [];

    // Watchlist mutations
    const queryClient = useQueryClient();
    const watchlistMutation = useMutation({
        mutationFn: async ({ id, isWatched }: { id: string; isWatched: boolean }) => {
            if (isWatched) {
                await auctionsService.removeFromWatchlist(id);
            } else {
                await auctionsService.addToWatchlist(id);
            }
            return { id, newStatus: !isWatched };
        },
        onSuccess: ({ id, newStatus }) => {
            // Update the cache
            queryClient.invalidateQueries({ queryKey: ['auctions'] });
            queryClient.invalidateQueries({ queryKey: ['watchlist'] });
            toast.success(newStatus ? 'Added to watchlist' : 'Removed from watchlist');
        },
        onError: (error: any) => {
            toast.error(error.response?.data?.error || 'Failed to update watchlist');
        },
    });

    const handleWatchToggle = (auctionId: string, isWatched?: boolean) => {
        watchlistMutation.mutate({ id: auctionId, isWatched: !!isWatched });
    };

    return (
        <div className="space-y-10">
            {/* Hero Section - Premium Visuals */}
            <div className="relative overflow-hidden rounded-[2.5rem] bg-slate-900 border border-white/10 shadow-2xl">
                {/* Abstract Background Shapes */}
                <div className="absolute top-0 right-0 -translate-y-1/2 translate-x-1/4 size-[500px] bg-primary/20 rounded-full blur-[120px]" />
                <div className="absolute bottom-0 left-0 translate-y-1/2 -translate-x-1/4 size-[400px] bg-secondary/20 rounded-full blur-[100px]" />

                <div className="relative p-8 lg:p-12">
                    <div className="max-w-2xl space-y-6">
                        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-white/10 backdrop-blur-md">
                            <span className="relative flex h-2 w-2">
                                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
                                <span className="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
                            </span>
                            <span className="text-xs font-bold text-white/80 uppercase tracking-widest">Live Marketplace</span>
                        </div>

                        <div className="space-y-4">
                            <h1 className="text-4xl lg:text-7xl font-black tracking-tight text-white leading-[1.05]">
                                Find and Bid on <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary via-secondary to-primary animate-gradient">Amazing Items</span>
                            </h1>
                            <p className="text-lg text-white/60 leading-relaxed font-medium">
                                {townId
                                    ? `Join active auctions happening right now in ${selectedTown?.name || 'your local community'}.`
                                    : 'The #1 local community marketplace for verified auctions and premium shops in Zimbabwe.'
                                }
                            </p>
                        </div>

                        <div className="flex flex-wrap gap-4 pt-2">
                            <Link href="/auctions/create">
                                <Button className="h-14 px-8 rounded-2xl text-lg font-bold gap-3 shadow-xl shadow-primary/20 hover:scale-105 transition-transform bg-primary hover:bg-primary/90 text-white border-none">
                                    <Plus className="size-5" />
                                    List an Auction
                                </Button>
                            </Link>
                            <Link href="/shops">
                                <Button variant="outline" className="h-14 px-8 rounded-2xl text-lg font-bold bg-white/5 border-white/10 text-white hover:bg-white/10 transition-all backdrop-blur-md">
                                    Explore Shops
                                </Button>
                            </Link>
                        </div>
                    </div>

                    {/* Desktop Hero Accent */}
                    <div className="hidden lg:block absolute right-12 bottom-12 p-8 rounded-3xl bg-white/5 border border-white/10 backdrop-blur-2xl">
                        <div className="flex items-center gap-8">
                            <div className="space-y-1">
                                <p className="text-3xl font-black text-white">
                                    {isLoadingNational ? '...' : nationalResponse?.total || 0}
                                </p>
                                <p className="text-xs font-bold text-white/40 uppercase tracking-wider">Active Auctions</p>
                            </div>
                            <div className="w-px h-10 bg-white/10" />
                            <div className="space-y-1">
                                <p className="text-3xl font-black text-white">24h</p>
                                <p className="text-xs font-bold text-white/40 uppercase tracking-wider">Support</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Category Discovery */}
            <div className="space-y-4">
                <div className="flex items-center justify-between px-2">
                    <h2 className="text-xl font-black tracking-tight flex items-center gap-2">
                        <Grid3X3 className="size-5 text-primary" />
                        Explore Categories
                    </h2>
                </div>

                <div className="flex gap-3 overflow-x-auto pb-6 pt-2 px-2 scrollbar-hide">
                    <Button
                        variant={selectedCategory === null ? "default" : "outline"}
                        className={cn(
                            "rounded-2xl px-6 h-12 flex-shrink-0 font-bold border-2 transition-all",
                            selectedCategory === null
                                ? "bg-primary border-primary text-white shadow-lg shadow-primary/20"
                                : "bg-card border-border hover:border-primary/50 hover:bg-primary/5"
                        )}
                        onClick={() => setSelectedCategory(null)}
                    >
                        <Grid3X3 className="size-4 mr-2" />
                        All
                    </Button>
                    {categories?.map((cat: any) => {
                        const slug = cat.slug || cat.name.toLowerCase().replace(/\s+/g, '-');
                        const Icon = CATEGORY_ICONS[slug] || Package;
                        const isActive = selectedCategory === cat.id;

                        return (
                            <Button
                                key={cat.id}
                                variant={isActive ? "default" : "outline"}
                                className={cn(
                                    "rounded-2xl px-6 h-12 flex-shrink-0 font-bold border-2 transition-all",
                                    isActive
                                        ? "bg-primary border-primary text-white shadow-lg shadow-primary/20"
                                        : "bg-card border-border hover:border-primary/50 hover:bg-primary/5"
                                )}
                                onClick={() => setSelectedCategory(cat.id)}
                            >
                                <Icon className="size-4 mr-2" />
                                {cat.name}
                            </Button>
                        );
                    })}
                </div>
            </div>

            {/* Tabs */}
            <Tabs defaultValue="mytown" className="w-full">
                <div className="flex items-center justify-between mb-6">
                    <TabsList className="bg-muted p-1 rounded-2xl h-14">
                        <TabsTrigger
                            value="mytown"
                            className="rounded-xl px-8 h-full data-[state=active]:bg-primary data-[state=active]:text-primary-foreground data-[state=active]:shadow-lg font-bold text-base transition-all"
                        >
                            In My Town
                        </TabsTrigger>
                        <TabsTrigger
                            value="national"
                            className="rounded-xl px-8 h-full data-[state=active]:bg-primary data-[state=active]:text-primary-foreground data-[state=active]:shadow-lg font-bold text-base transition-all"
                        >
                            National
                        </TabsTrigger>
                    </TabsList>
                    {(selectedTown || user) && (
                        <Badge variant="secondary" className="hidden sm:inline-flex bg-primary/5 text-primary border-primary/10 px-3 py-1">
                            {selectedTown?.name || 'Your Town'}
                            {selectedSuburb?.name && ` • ${selectedSuburb.name}`}
                        </Badge>
                    )}
                </div>

                <TabsContent value="mytown" className="mt-0 outline-none">
                    {isLoadingTown ? (
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                            {[...Array(4)].map((_, i) => (
                                <div key={i} className="aspect-[4/5] rounded-xl bg-muted animate-pulse" />
                            ))}
                        </div>
                    ) : townAuctions.length > 0 ? (
                        <div className="space-y-6">
                            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                                {townAuctions.map((auction) => (
                                    <AuctionCard
                                        key={auction.id}
                                        auction={auction}
                                        onWatchToggle={() => handleWatchToggle(auction.id, auction.is_watched)}
                                    />
                                ))}
                            </div>
                            {townResponse && townResponse.total_pages > 1 && (
                                <Pagination
                                    currentPage={townPage}
                                    totalPages={townResponse.total_pages}
                                    totalItems={townResponse.total}
                                    itemsPerPage={ITEMS_PER_PAGE}
                                    onPageChange={setTownPage}
                                />
                            )}
                        </div>
                    ) : (
                        <div className="text-center py-20 bg-muted/20 rounded-2xl border-2 border-dashed">
                            <Gavel className="size-12 mx-auto mb-4 opacity-20" />
                            <p className="font-semibold text-lg">No active auctions in your town</p>
                            <p className="text-muted-foreground mb-6">Be the first to list something!</p>
                            <Link href="/auctions/create">
                                <Button>Create Auction</Button>
                            </Link>
                        </div>
                    )}
                </TabsContent>

                <TabsContent value="national" className="mt-0 outline-none">
                    {isLoadingNational ? (
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                            {[...Array(4)].map((_, i) => (
                                <div key={i} className="aspect-[4/5] rounded-xl bg-muted animate-pulse" />
                            ))}
                        </div>
                    ) : nationalAuctions.length > 0 ? (
                        <div className="space-y-6">
                            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                                {nationalAuctions.map((auction) => (
                                    <AuctionCard
                                        key={auction.id}
                                        auction={auction}
                                        onWatchToggle={() => handleWatchToggle(auction.id, auction.is_watched)}
                                    />
                                ))}
                            </div>
                            {nationalResponse && nationalResponse.total_pages > 1 && (
                                <Pagination
                                    currentPage={nationalPage}
                                    totalPages={nationalResponse.total_pages}
                                    totalItems={nationalResponse.total}
                                    itemsPerPage={ITEMS_PER_PAGE}
                                    onPageChange={setNationalPage}
                                />
                            )}
                        </div>
                    ) : (
                        <div className="text-center py-20 bg-muted/20 rounded-2xl">
                            <Gavel className="size-12 mx-auto mb-4 opacity-20" />
                            <p className="font-medium text-lg">No national auctions found</p>
                        </div>
                    )}
                </TabsContent>
            </Tabs>
        </div>
    );
}
