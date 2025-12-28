'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
    Search,
    Store as StoreIcon,
    SlidersHorizontal,
    ArrowRight,
    Loader2,
    PackageSearch,
    MapPin,
    LayoutGrid,
    LayoutList,
    Star
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Pagination } from '@/components/ui/pagination';
import { ShopCard } from '@/components/cards/ShopCard';
import { shopsService } from '@/services/shops';
import { useTownStore } from '@/stores/townStore';
import { cn } from '@/lib/utils';

import { useSearchParams } from 'next/navigation';

const ITEMS_PER_PAGE = 12;

export default function ShopsPage() {
    const { selectedTown } = useTownStore();
    const searchParams = useSearchParams();
    const [search, setSearch] = useState(searchParams.get('q') || '');
    const [activeTab, setActiveTab] = useState<'all' | 'nearby' | 'featured'>('all');
    const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
    const [page, setPage] = useState(1);

    // Queries
    const { data: featuredShops, isLoading: isLoadingFeatured } = useQuery({
        queryKey: ['shops', 'featured'],
        queryFn: shopsService.getFeaturedShops,
    });

    const { data: shopsData, isLoading: isLoadingShops } = useQuery({
        queryKey: ['shops', activeTab, selectedTown?.id, search, page],
        queryFn: () => {
            if (activeTab === 'featured') return shopsService.getFeaturedShops();
            if (activeTab === 'nearby' && selectedTown) return shopsService.getNearbyShops();
            return shopsService.getShops({
                town: selectedTown?.id,
                q: search || undefined,
                page,
                limit: ITEMS_PER_PAGE,
            });
        },
    });

    const shops = shopsData?.stores || [];

    return (
        <div className="max-w-7xl mx-auto space-y-8 pb-12">
            {/* Header Section */}
            <div className="relative rounded-3xl overflow-hidden bg-primary/10 p-8 md:p-12">
                <div className="relative z-10 max-w-2xl space-y-4">
                    <Badge variant="secondary" className="bg-primary/20 text-primary border-none text-sm px-4 py-1">
                        Marketplace Stores
                    </Badge>
                    <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight">
                        Discover Trusted <span className="text-primary">Local Shops</span>
                    </h1>
                    <p className="text-muted-foreground text-lg">
                        Browse verified stores in your community, chat directly via WhatsApp, and get the best deals on new items.
                    </p>

                    <div className="flex flex-col sm:flex-row gap-3 pt-4">
                        <div className="relative flex-1 group">
                            <Search className="absolute left-4 top-1/2 -translate-y-1/2 size-5 text-muted-foreground group-focus-within:text-primary transition-colors" />
                            <Input
                                placeholder="Search shops by name or products..."
                                className="pl-12 h-14 bg-background border-none rounded-2xl shadow-sm text-lg"
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                            />
                        </div>
                        <Button className="h-14 px-8 rounded-2xl text-lg font-bold">
                            Find Stores
                        </Button>
                    </div>
                </div>

                {/* Decorative Elements */}
                <div className="absolute top-0 right-0 w-1/3 h-full hidden lg:flex items-center justify-center opacity-10">
                    <StoreIcon className="size-64" />
                </div>
            </div>

            {/* Featured Section */}
            {isLoadingFeatured ? (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    {[...Array(3)].map((_, i) => (
                        <div key={i} className="aspect-[4/5] bg-muted animate-pulse rounded-2xl" />
                    ))}
                </div>
            ) : featuredShops?.stores && featuredShops.stores.length > 0 && (
                <section className="space-y-6">
                    <div className="flex items-center justify-between">
                        <h2 className="text-2xl font-bold flex items-center gap-2">
                            <Star className="size-6 text-yellow-500 fill-yellow-500" />
                            Featured Stores
                        </h2>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                        {featuredShops.stores.slice(0, 4).map((shop) => (
                            <ShopCard key={shop.id} shop={shop} variant="featured" />
                        ))}
                    </div>
                </section>
            )}

            {/* Filter Bar */}
            <div className="sticky top-[4.5rem] z-20 bg-background/95 backdrop-blur-md py-4 border-b flex flex-wrap items-center justify-between gap-4">
                <Tabs value={activeTab} onValueChange={(v: any) => setActiveTab(v)} className="w-full md:w-auto">
                    <TabsList className="bg-muted/50 p-1 rounded-xl h-12">
                        <TabsTrigger value="all" className="rounded-lg px-6 data-[state=active]:bg-background data-[state=active]:shadow-sm">
                            All Stores
                        </TabsTrigger>
                        <TabsTrigger value="nearby" className="rounded-lg px-6 data-[state=active]:bg-background data-[state=active]:shadow-sm">
                            Nearby
                        </TabsTrigger>
                        <TabsTrigger value="featured" className="rounded-lg px-6 data-[state=active]:bg-background data-[state=active]:shadow-sm">
                            Featured
                        </TabsTrigger>
                    </TabsList>
                </Tabs>

                <div className="flex items-center gap-2">
                    <div className="flex items-center p-1 bg-muted/50 rounded-xl h-11">
                        <Button
                            variant={viewMode === 'grid' ? 'secondary' : 'ghost'}
                            size="icon"
                            className="rounded-lg size-9"
                            onClick={() => setViewMode('grid')}
                        >
                            <LayoutGrid className="size-4" />
                        </Button>
                        <Button
                            variant={viewMode === 'list' ? 'secondary' : 'ghost'}
                            size="icon"
                            className="rounded-lg size-9"
                            onClick={() => setViewMode('list')}
                        >
                            <LayoutList className="size-4" />
                        </Button>
                    </div>
                    <Button variant="outline" className="h-11 rounded-xl gap-2 px-4 font-semibold">
                        <SlidersHorizontal className="size-4" />
                        Filters
                    </Button>
                </div>
            </div>

            {/* Shop Listing */}
            {isLoadingShops ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                    {[...Array(6)].map((_, i) => (
                        <div key={i} className="h-[400px] bg-muted animate-pulse rounded-2xl" />
                    ))}
                </div>
            ) : shops.length > 0 ? (
                <div className="space-y-8">
                    <div className={cn(
                        "grid gap-8",
                        viewMode === 'grid' ? "grid-cols-1 md:grid-cols-2 lg:grid-cols-3" : "grid-cols-1"
                    )}>
                        {shops.map((shop) => (
                            <ShopCard key={shop.id} shop={shop} variant={viewMode} />
                        ))}
                    </div>
                    {shopsData && shopsData.total_count > ITEMS_PER_PAGE && (
                        <Pagination
                            currentPage={page}
                            totalPages={Math.ceil(shopsData.total_count / ITEMS_PER_PAGE)}
                            totalItems={shopsData.total_count}
                            itemsPerPage={ITEMS_PER_PAGE}
                            onPageChange={setPage}
                        />
                    )}
                </div>
            ) : (
                <div className="flex flex-col items-center justify-center py-24 px-4 text-center">
                    <div className="size-24 bg-muted rounded-full flex items-center justify-center mb-6">
                        <PackageSearch className="size-12 text-muted-foreground/50" />
                    </div>
                    <h3 className="text-2xl font-bold mb-2">No shops found</h3>
                    <p className="text-muted-foreground max-w-md mx-auto mb-8">
                        Try adjusting your search filters or check back later for new stores in {selectedTown?.name || 'Zimbabwe'}.
                    </p>
                    <Button
                        variant="secondary"
                        className="rounded-xl px-8"
                        onClick={() => {
                            setSearch('');
                            setActiveTab('all');
                        }}
                    >
                        Reset All Filters
                    </Button>
                </div>
            )}
        </div>
    );
}
