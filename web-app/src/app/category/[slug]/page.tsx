'use client';

import { useState } from 'react';
import { useParams, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import {
    ChevronRight,
    Grid2X2,
    List,
    SlidersHorizontal,
    Clock,
    Flame,
    DollarSign,
    ArrowUpDown,
    Smartphone,
    Car,
    Home,
    Shirt,
    Gem,
    Briefcase,
    Dumbbell,
    Baby,
    TreePine,
    Tag
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
import {
    Sheet,
    SheetContent,
    SheetDescription,
    SheetHeader,
    SheetTitle,
    SheetTrigger,
} from '@/components/ui/sheet';
import { Slider } from '@/components/ui/slider';
import { Label } from '@/components/ui/label';
import { Separator } from '@/components/ui/separator';
import { Skeleton } from '@/components/ui/skeleton';
import { AuctionCard } from '@/components/cards/AuctionCard';
import { auctionsService, type AuctionFilters } from '@/services/auctions';
import { categoriesService } from '@/services/categories';
import { useTownStore } from '@/stores/townStore';
import { cn } from '@/lib/utils';

// Category icons mapping
const categoryIcons: Record<string, React.ElementType> = {
    electronics: Smartphone,
    vehicles: Car,
    property: Home,
    fashion: Shirt,
    jewelry: Gem,
    services: Briefcase,
    sports: Dumbbell,
    kids: Baby,
    outdoors: TreePine,
};

type SortOption = 'ending_soon' | 'newest' | 'price_low' | 'price_high' | 'most_bids';

export default function CategoryPage() {
    const params = useParams();
    const searchParams = useSearchParams();
    const slug = params.slug as string;
    const { selectedTown } = useTownStore();

    // State for filters
    const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
    const [sortBy, setSortBy] = useState<SortOption>('ending_soon');
    const [priceRange, setPriceRange] = useState<[number, number]>([0, 10000]);
    const [filterOpen, setFilterOpen] = useState(false);

    // Fetch category info
    const { data: categories = [] } = useQuery({
        queryKey: ['categories'],
        queryFn: categoriesService.getCategories,
    });

    // Find current category by slug
    const currentCategory = categories.find(cat => cat.slug === slug);

    // Build filters
    const filters: AuctionFilters = {
        category_id: currentCategory?.id,
        town_id: selectedTown?.id,
        min_price: priceRange[0] > 0 ? priceRange[0] : undefined,
        max_price: priceRange[1] < 10000 ? priceRange[1] : undefined,
        sort_by: sortBy === 'ending_soon' ? 'end_time' :
            sortBy === 'newest' ? 'created_at' :
                sortBy === 'price_low' || sortBy === 'price_high' ? 'current_price' :
                    sortBy === 'most_bids' ? 'total_bids' : 'end_time',
        sort_order: sortBy === 'price_low' ? 'asc' : 'desc',
        status: 'active',
    };

    // Fetch auctions for this category
    const { data: auctionsData, isLoading: auctionsLoading } = useQuery({
        queryKey: ['auctions', 'category', slug, filters],
        queryFn: () => auctionsService.getAuctions(filters),
        enabled: !!currentCategory?.id,
    });

    const auctions = auctionsData?.auctions || [];
    const Icon = categoryIcons[slug] || Tag;

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
            <div className="relative bg-gradient-to-r from-primary/20 via-primary/10 to-background py-12 px-4 mb-8">
                <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_50%,rgba(var(--primary-rgb),0.15),transparent_70%)]" />
                <div className="max-w-7xl mx-auto relative">
                    {/* Breadcrumb */}
                    <nav className="flex items-center gap-2 text-sm text-muted-foreground mb-4">
                        <Link href="/" className="hover:text-foreground transition-colors">
                            Home
                        </Link>
                        <ChevronRight className="size-4" />
                        <Link href="/" className="hover:text-foreground transition-colors">
                            Categories
                        </Link>
                        <ChevronRight className="size-4" />
                        <span className="text-foreground font-medium">
                            {currentCategory?.name || slug}
                        </span>
                    </nav>

                    {/* Category Title */}
                    <div className="flex items-center gap-4">
                        <div className="p-4 rounded-2xl bg-primary/20 text-primary">
                            <Icon className="size-8" />
                        </div>
                        <div>
                            <h1 className="text-3xl font-bold tracking-tight">
                                {currentCategory?.name || slug.charAt(0).toUpperCase() + slug.slice(1)}
                            </h1>
                            {currentCategory?.description && (
                                <p className="text-muted-foreground mt-1">
                                    {currentCategory.description}
                                </p>
                            )}
                            <div className="flex items-center gap-3 mt-2">
                                <Badge variant="secondary" className="rounded-full">
                                    {auctionsData?.total || 0} auctions
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
                    {/* Results Count */}
                    <p className="text-sm text-muted-foreground">
                        Showing <span className="font-medium text-foreground">{auctions.length}</span> of{' '}
                        <span className="font-medium text-foreground">{auctionsData?.total || 0}</span> results
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

                        {/* Filters Sheet */}
                        <Sheet open={filterOpen} onOpenChange={setFilterOpen}>
                            <SheetTrigger asChild>
                                <Button variant="outline" size="icon">
                                    <SlidersHorizontal className="size-4" />
                                </Button>
                            </SheetTrigger>
                            <SheetContent>
                                <SheetHeader>
                                    <SheetTitle>Filters</SheetTitle>
                                    <SheetDescription>
                                        Narrow down your search results
                                    </SheetDescription>
                                </SheetHeader>
                                <div className="py-6 space-y-6">
                                    {/* Price Range */}
                                    <div className="space-y-4">
                                        <Label>Price Range</Label>
                                        <Slider
                                            value={priceRange}
                                            onValueChange={(values: number[]) => setPriceRange(values as [number, number])}
                                            max={10000}
                                            step={100}
                                            className="w-full"
                                        />
                                        <div className="flex items-center justify-between text-sm text-muted-foreground">
                                            <span>${priceRange[0]}</span>
                                            <span>${priceRange[1]}+</span>
                                        </div>
                                    </div>

                                    <Separator />

                                    <Button
                                        variant="outline"
                                        className="w-full"
                                        onClick={() => {
                                            setPriceRange([0, 10000]);
                                        }}
                                    >
                                        Reset Filters
                                    </Button>
                                </div>
                            </SheetContent>
                        </Sheet>

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
                {auctionsLoading ? (
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
                            <Icon className="size-10 text-muted-foreground" />
                        </div>
                        <h3 className="text-xl font-semibold mb-2">No auctions found</h3>
                        <p className="text-muted-foreground mb-6 max-w-md mx-auto">
                            There are no active auctions in the {currentCategory?.name || slug} category
                            {selectedTown && ` in ${selectedTown.name}`} right now.
                        </p>
                        <Button asChild>
                            <Link href="/auctions/create">
                                Be the first to list something!
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
