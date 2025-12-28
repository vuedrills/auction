'use client';

import { useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    LayoutDashboard,
    Package,
    Gavel,
    Heart,
    Settings,
    Store as StoreIcon,
    MapPin,
    LogOut,
    User as UserIcon,
    Loader2,
    Camera,
    Award
} from 'lucide-react';
import { format } from 'date-fns';

import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Separator } from '@/components/ui/separator';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { toast } from 'sonner';

import { authService } from '@/services/auth';
import { auctionsService } from '@/services/auctions';
import { shopsService } from '@/services/shops';
import { useAuthStore } from '@/stores/authStore';
import { AuctionCard } from '@/components/cards/AuctionCard';
import { ShopCard } from '@/components/cards/ShopCard';
import { api } from '@/services/api';
import { cn } from '@/lib/utils';

export default function ProfilePage() {
    const router = useRouter();
    const { logout, user: storedUser } = useAuthStore();
    const queryClient = useQueryClient();

    // Fetch fresh user data
    const { data: user, isLoading: isLoadingUser } = useQuery({
        queryKey: ['me'],
        queryFn: authService.getMe,
        initialData: storedUser || undefined,
    });

    // Fetch user's shop
    const { data: myShop, isLoading: isLoadingShop } = useQuery({
        queryKey: ['my-shop'],
        queryFn: shopsService.getMyShop,
        retry: false,
    });

    // Fetch auctions
    const { data: myAuctions, isLoading: isLoadingAuctions } = useQuery({
        queryKey: ['my-auctions'],
        queryFn: auctionsService.getMyAuctions,
    });

    // Fetch bids
    const { data: myBids, isLoading: isLoadingBids } = useQuery({
        queryKey: ['my-bids'],
        queryFn: auctionsService.getMyBids,
    });

    // Fetch won auctions
    const { data: wonAuctions, isLoading: isLoadingWon } = useQuery({
        queryKey: ['won-auctions'],
        queryFn: auctionsService.getWonAuctions,
    });

    // Fetch watchlist
    const { data: watchlist, isLoading: isLoadingWatchlist } = useQuery({
        queryKey: ['watchlist'],
        queryFn: auctionsService.getWatchlist,
    });

    // Fetch badges
    const { data: badges } = useQuery({
        queryKey: ['my-badges'],
        queryFn: authService.getMyBadges,
    });

    const handleLogout = () => {
        logout();
        toast.success('Logged out successfully');
        router.push('/login');
    };

    const fileInputRef = useRef<HTMLInputElement>(null);

    const uploadAvatarMutation = useMutation({
        mutationFn: async (file: File) => {
            const formData = new FormData();
            formData.append('image', file);
            const response = await api.post(`/upload/image?folder=avatars`, formData, {
                headers: { 'Content-Type': 'multipart/form-data' },
            });
            const avatarUrl = response.data.url;
            return authService.updateProfile({ avatar_url: avatarUrl });
        },
        onSuccess: (updatedUser) => {
            // Update the user in the store
            const userWithProperName = {
                ...updatedUser,
                full_name: updatedUser.full_name || updatedUser.username
            };
            useAuthStore.getState().setUser(userWithProperName);
            toast.success('Profile picture updated');
        },
        onError: (err: any) => {
            toast.error(err.response?.data?.error || 'Failed to update profile picture');
        }
    });

    const handleAvatarClick = () => {
        fileInputRef.current?.click();
    };

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            uploadAvatarMutation.mutate(file);
        }
    };

    if (isLoadingUser) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
                <Loader2 className="size-10 animate-spin text-primary" />
                <p className="text-muted-foreground animate-pulse">Loading profile...</p>
            </div>
        );
    }

    if (!user) {
        router.push('/login');
        return null;
    }

    return (
        <div className="max-w-7xl mx-auto py-8 px-4 space-y-8">
            <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                className="hidden"
                onChange={handleFileChange}
            />
            {/* Header / Profile Card */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                {/* Left Column: User Info */}
                <Card className="md:col-span-1 h-fit border-none shadow-lg shadow-black/5 bg-card rounded-3xl overflow-hidden">
                    <div className="h-24 bg-gradient-to-r from-primary/10 to-primary/5" />
                    <CardContent className="pt-0 relative">
                        <div className="absolute -top-12 left-1/2 -translate-x-1/2">
                            <div
                                className="relative group cursor-pointer"
                                onClick={handleAvatarClick}
                            >
                                <div className={cn(
                                    "relative rounded-full",
                                    uploadAvatarMutation.isPending && "opacity-50"
                                )}>
                                    <Avatar className="size-24 border-4 border-background shadow-xl">
                                        <AvatarImage src={user.avatar_url} className="object-cover" />
                                        <AvatarFallback className="text-2xl font-bold bg-primary/10 text-primary">
                                            {user.full_name?.charAt(0) || user.username?.charAt(0)}
                                        </AvatarFallback>
                                    </Avatar>
                                    {uploadAvatarMutation.isPending && (
                                        <div className="absolute inset-0 flex items-center justify-center bg-black/20 rounded-full">
                                            <Loader2 className="size-8 animate-spin text-white" />
                                        </div>
                                    )}
                                </div>
                                <div className="absolute inset-0 bg-black/40 rounded-full opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                                    <Camera className="size-6 text-white" />
                                </div>
                            </div>
                        </div>

                        <div className="mt-14 space-y-4">
                            <div>
                                <h1 className="text-2xl font-black">{user.full_name}</h1>
                                <p className="text-muted-foreground">@{user.username}</p>
                            </div>

                            <div className="flex items-center gap-2 text-sm text-muted-foreground">
                                <MapPin className="size-4" />
                                {user.town_name || 'Zimbabwe'}
                                {user.suburb_name && `, ${user.suburb_name}`}
                            </div>

                            <Separator />

                            <div className="space-y-2">
                                <h4 className="font-semibold text-sm">Account Status</h4>
                                <div className="flex gap-2">
                                    {user.is_verified && (
                                        <Badge variant="default" className="bg-primary/10 text-primary hover:bg-primary/20 border-primary/20">
                                            Verified User
                                        </Badge>
                                    )}
                                    <Badge variant="outline">
                                        Joined {format(new Date(user.created_at || new Date()), 'MMM yyyy')}
                                    </Badge>
                                </div>
                            </div>

                            {/* User Badges */}
                            {badges && badges.length > 0 && (
                                <div className="space-y-2">
                                    <h4 className="font-semibold text-sm">Badges</h4>
                                    <div className="flex flex-wrap gap-2">
                                        {badges.map((badge: any) => (
                                            <Badge key={badge.id} variant="secondary" className="gap-1 bg-gradient-to-r from-orange-100 to-amber-100 text-orange-800 border-orange-200">
                                                <Award className="size-3" />
                                                {badge.name}
                                            </Badge>
                                        ))}
                                    </div>
                                </div>
                            )}

                            <Separator />

                            {/* Store Link */}
                            {myShop ? (
                                <Link href="/profile/stores" className="block">
                                    <Button variant="outline" className="w-full justify-between h-12 rounded-xl group border-primary/20 hover:bg-primary/5 hover:border-primary/40">
                                        <span className="flex items-center gap-2 font-semibold">
                                            <StoreIcon className="size-4 text-primary" />
                                            Manage My Store
                                        </span>
                                        <Badge className="bg-primary text-primary-foreground group-hover:scale-105 transition-transform">
                                            Active
                                        </Badge>
                                    </Button>
                                </Link>
                            ) : (
                                <Link href="/profile/stores/create" className="block">
                                    <Button variant="default" className="w-full h-12 rounded-xl font-bold shadow-lg shadow-primary/20">
                                        <StoreIcon className="size-4 mr-2" />
                                        Open a Store
                                    </Button>
                                </Link>
                            )}

                            <Button
                                variant="ghost"
                                className="w-full justify-start text-destructive hover:text-destructive hover:bg-destructive/10"
                                onClick={handleLogout}
                            >
                                <LogOut className="size-4 mr-2" />
                                Sign Out
                            </Button>
                        </div>
                    </CardContent>
                </Card>

                {/* Right Column: Content Tabs */}
                <div className="md:col-span-2">
                    <Tabs defaultValue="bids" className="space-y-6">
                        <TabsList className="w-full justify-start h-14 p-1 bg-muted/50 rounded-2xl overflow-x-auto">
                            <TabsTrigger value="bids" className="h-12 rounded-xl px-6 data-[state=active]:bg-background data-[state=active]:shadow-sm">
                                <Gavel className="size-4 mr-2" />
                                My Bids
                            </TabsTrigger>
                            <TabsTrigger value="auctions" className="h-12 rounded-xl px-6 data-[state=active]:bg-background data-[state=active]:shadow-sm">
                                <Package className="size-4 mr-2" />
                                My Auctions
                            </TabsTrigger>
                            <TabsTrigger value="watchlist" className="h-12 rounded-xl px-6 data-[state=active]:bg-background data-[state=active]:shadow-sm">
                                <Heart className="size-4 mr-2" />
                                Watchlist
                            </TabsTrigger>
                            <TabsTrigger value="settings" className="h-12 rounded-xl px-6 data-[state=active]:bg-background data-[state=active]:shadow-sm">
                                <Settings className="size-4 mr-2" />
                                Settings
                            </TabsTrigger>
                        </TabsList>

                        {/* My Bids Content */}
                        <TabsContent value="bids" className="space-y-6">
                            <div className="flex items-center justify-between">
                                <h2 className="text-xl font-bold">Active Bids</h2>
                                <Badge variant="secondary">{myBids ? myBids.length : 0} Items</Badge>
                            </div>

                            {isLoadingBids ? (
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                    {[1, 2].map(i => <div key={i} className="aspect-[4/3] bg-muted animate-pulse rounded-2xl" />)}
                                </div>
                            ) : myBids && myBids.length > 0 ? (
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                    {/* Note: Backend needs to return Auction objects for bids, assuming simplified structure or full object */}
                                    {myBids.map((bid: any) => (
                                        <AuctionCard key={bid.auction_id || bid.id} auction={bid.auction || bid} />
                                    ))}
                                </div>
                            ) : (
                                <div className="text-center py-12 bg-muted/20 rounded-3xl border border-dashed">
                                    <Gavel className="size-12 text-muted-foreground mx-auto mb-4 opacity-20" />
                                    <h3 className="text-lg font-semibold">No active bids</h3>
                                    <p className="text-muted-foreground mb-6">Start bidding on items you love!</p>
                                    <Link href="/">
                                        <Button>Browse Auctions</Button>
                                    </Link>
                                </div>
                            )}
                        </TabsContent>

                        {/* My Auctions Content */}
                        <TabsContent value="auctions" className="space-y-6">
                            <div className="flex items-center justify-between">
                                <h2 className="text-xl font-bold">My Auctions</h2>
                                <Link href="/auctions/create">
                                    <Button size="sm">Create New Auction</Button>
                                </Link>
                            </div>

                            {isLoadingAuctions ? (
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                    {[1, 2].map(i => <div key={i} className="aspect-[4/3] bg-muted animate-pulse rounded-2xl" />)}
                                </div>
                            ) : myAuctions?.auctions && myAuctions.auctions.length > 0 ? (
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                    {myAuctions.auctions.map((auction: any) => (
                                        <AuctionCard key={auction.id} auction={auction} />
                                    ))}
                                </div>
                            ) : (
                                <div className="text-center py-12 bg-muted/20 rounded-3xl border border-dashed">
                                    <Package className="size-12 text-muted-foreground mx-auto mb-4 opacity-20" />
                                    <h3 className="text-lg font-semibold">You haven't listed any items</h3>
                                    <p className="text-muted-foreground mb-6">Turn your unused items into cash.</p>
                                    <Link href="/auctions/create">
                                        <Button>List an Item</Button>
                                    </Link>
                                </div>
                            )}
                        </TabsContent>

                        {/* Watchlist Content */}
                        <TabsContent value="watchlist" className="space-y-6">
                            <h2 className="text-xl font-bold">Saved Items</h2>
                            {isLoadingWatchlist ? (
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                    {[1, 2].map(i => <div key={i} className="aspect-[4/3] bg-muted animate-pulse rounded-2xl" />)}
                                </div>
                            ) : watchlist?.auctions && watchlist.auctions.length > 0 ? (
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                    {watchlist.auctions.map((auction: any) => (
                                        <AuctionCard
                                            key={auction.id}
                                            auction={{ ...auction, is_watched: true }}
                                            onWatchToggle={async (id) => {
                                                await auctionsService.removeFromWatchlist(id);
                                                queryClient.invalidateQueries({ queryKey: ['watchlist'] });
                                            }}
                                        />
                                    ))}
                                </div>
                            ) : (
                                <div className="text-center py-12 bg-muted/20 rounded-3xl border border-dashed">
                                    <Heart className="size-12 text-muted-foreground mx-auto mb-4 opacity-20" />
                                    <h3 className="text-lg font-semibold">Your watchlist is empty</h3>
                                    <p className="text-muted-foreground mb-6">Save items to track their progress.</p>
                                    <Link href="/auctions">
                                        <Button>Explore Items</Button>
                                    </Link>
                                </div>
                            )}
                        </TabsContent>

                        {/* Settings Content */}
                        <TabsContent value="settings" className="space-y-6">
                            <Card>
                                <CardHeader>
                                    <CardTitle>Profile Settings</CardTitle>
                                    <CardDescription>Manage your account preferences</CardDescription>
                                </CardHeader>
                                <CardContent className="space-y-4">
                                    <div className="grid gap-2">
                                        <Label htmlFor="email">Email Address</Label>
                                        <Input id="email" value={user.email} disabled className="bg-muted" />
                                    </div>
                                    <div className="grid gap-2">
                                        <Label htmlFor="phone">Phone Number</Label>
                                        <Input id="phone" value={user.phone || ''} placeholder="Add a phone number" readOnly className="bg-muted" />
                                    </div>
                                    <div className="pt-4">
                                        <Button>Save Changes</Button>
                                    </div>
                                </CardContent>
                            </Card>
                        </TabsContent>
                    </Tabs>
                </div>
            </div>
        </div>
    );
}
