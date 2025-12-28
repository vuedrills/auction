'use client';

import { AuctionCard } from '@/components/cards/AuctionCard';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Gavel, TrendingUp, Clock, Plus } from 'lucide-react';
import Link from 'next/link';

// Temporary mock data - will be replaced with API calls
const mockAuctions = [
    {
        id: '1',
        title: 'iPhone 14 Pro Max - Like New Condition',
        current_bid: 850,
        starting_price: 500,
        end_time: new Date(Date.now() + 3600000 * 4).toISOString(), // 4 hours from now
        images: ['https://images.unsplash.com/photo-1678652197831-2d180705cd2c?w=400'],
        town_name: 'Harare',
        suburb_name: 'Avondale',
        category_name: 'Electronics',
        bid_count: 12,
    },
    {
        id: '2',
        title: 'Toyota Hilux 2019 - Single Owner',
        current_bid: 25000,
        starting_price: 20000,
        end_time: new Date(Date.now() + 3600000 * 24 * 2).toISOString(), // 2 days from now
        images: ['https://images.unsplash.com/photo-1559416523-140ddc3d238c?w=400'],
        town_name: 'Harare',
        suburb_name: 'Borrowdale',
        category_name: 'Vehicles',
        bid_count: 8,
    },
    {
        id: '3',
        title: 'MacBook Pro M2 14" - 16GB RAM',
        current_bid: 1200,
        starting_price: 1000,
        end_time: new Date(Date.now() + 3600000 * 0.5).toISOString(), // 30 mins from now (ending soon!)
        images: ['https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400'],
        town_name: 'Harare',
        suburb_name: 'Mount Pleasant',
        category_name: 'Electronics',
        bid_count: 23,
    },
    {
        id: '4',
        title: 'Samsung 65" QLED Smart TV',
        current_bid: 700,
        starting_price: 600,
        end_time: new Date(Date.now() + 3600000 * 12).toISOString(), // 12 hours from now
        images: ['https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=400'],
        town_name: 'Harare',
        suburb_name: 'Highlands',
        category_name: 'Electronics',
        bid_count: 5,
    },
    {
        id: '5',
        title: 'Vintage Leather Office Chair',
        current_bid: 150,
        starting_price: 100,
        end_time: new Date(Date.now() + 3600000 * 48).toISOString(), // 2 days from now
        images: ['https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400'],
        town_name: 'Harare',
        suburb_name: 'Greendale',
        category_name: 'Furniture',
        bid_count: 3,
    },
    {
        id: '6',
        title: 'PlayStation 5 Console with 2 Controllers',
        current_bid: 480,
        starting_price: 400,
        end_time: new Date(Date.now() + 3600000 * 6).toISOString(), // 6 hours from now
        images: ['https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=400'],
        town_name: 'Harare',
        suburb_name: 'Chisipite',
        category_name: 'Gaming',
        bid_count: 15,
    },
];

export default function HomePage() {
    return (
        <div className="space-y-6">
            {/* Hero Section */}
            <div className="bg-gradient-to-br from-primary/10 via-secondary/5 to-background rounded-2xl p-6 lg:p-8">
                <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                    <div>
                        <h1 className="text-2xl lg:text-3xl font-bold tracking-tight">
                            Welcome to Trabab
                        </h1>
                        <p className="text-muted-foreground mt-1">
                            Bid on items in your local community
                        </p>
                    </div>
                    <div className="flex gap-3">
                        <Link href="/auctions/create">
                            <Button className="gap-2">
                                <Plus className="size-4" />
                                Create Auction
                            </Button>
                        </Link>
                    </div>
                </div>

                {/* Quick Stats */}
                <div className="grid grid-cols-3 gap-4 mt-6">
                    <div className="bg-background/60 backdrop-blur-sm rounded-lg p-3 text-center">
                        <div className="flex items-center justify-center gap-1 text-primary mb-1">
                            <Gavel className="size-4" />
                            <span className="text-lg font-bold">156</span>
                        </div>
                        <p className="text-xs text-muted-foreground">Active Auctions</p>
                    </div>
                    <div className="bg-background/60 backdrop-blur-sm rounded-lg p-3 text-center">
                        <div className="flex items-center justify-center gap-1 text-primary mb-1">
                            <TrendingUp className="size-4" />
                            <span className="text-lg font-bold">$45K</span>
                        </div>
                        <p className="text-xs text-muted-foreground">Total Bids Today</p>
                    </div>
                    <div className="bg-background/60 backdrop-blur-sm rounded-lg p-3 text-center">
                        <div className="flex items-center justify-center gap-1 text-destructive mb-1">
                            <Clock className="size-4" />
                            <span className="text-lg font-bold">12</span>
                        </div>
                        <p className="text-xs text-muted-foreground">Ending Soon</p>
                    </div>
                </div>
            </div>

            {/* Tabs */}
            <Tabs defaultValue="mytown" className="w-full">
                <div className="flex items-center justify-between mb-4">
                    <TabsList>
                        <TabsTrigger value="mytown">My Town</TabsTrigger>
                        <TabsTrigger value="national">National</TabsTrigger>
                    </TabsList>
                    <Badge variant="secondary" className="hidden sm:inline-flex">
                        Harare • Avondale
                    </Badge>
                </div>

                <TabsContent value="mytown" className="mt-0">
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                        {mockAuctions.map((auction) => (
                            <AuctionCard
                                key={auction.id}
                                auction={auction}
                                onWatchToggle={(id) => console.log('Toggle watch:', id)}
                            />
                        ))}
                    </div>
                </TabsContent>

                <TabsContent value="national" className="mt-0">
                    <div className="text-center py-12 text-muted-foreground">
                        <Gavel className="size-12 mx-auto mb-4 opacity-20" />
                        <p className="font-medium">National auctions from all towns</p>
                        <p className="text-sm">Coming soon...</p>
                    </div>
                </TabsContent>
            </Tabs>
        </div>
    );
}
