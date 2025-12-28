'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    MapPin,
    MessageCircle,
    MessageSquare,
    Share2,
    ShieldCheck,
    Star,
    Users,
    Package,
    Clock,
    ChevronRight,
    Search,
    Filter as FilterIcon,
    ArrowLeft,
    Loader2,
    Calendar,
    Phone
} from 'lucide-react';
import Image from 'next/image';
import Link from 'next/link';
import { toast } from 'sonner';

import { shopsService } from '@/services/shops';
import { chatService } from '@/services/chat';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { cn } from '@/lib/utils';
import { useAuthStore } from '@/stores/authStore';

export default function ShopDetailsPage() {
    const { slug } = useParams() as { slug: string };
    const router = useRouter();
    const queryClient = useQueryClient();
    const { isAuthenticated } = useAuthStore();
    const [search, setSearch] = useState('');

    // Queries
    const { data: shop, isLoading: isLoadingShop, error: shopError } = useQuery({
        queryKey: ['shop', slug],
        queryFn: () => shopsService.getShopBySlug(slug),
    });

    const { data: productsData, isLoading: isLoadingProducts } = useQuery({
        queryKey: ['shop-products', slug, search],
        queryFn: () => shopsService.getProducts(slug, { q: search }),
        enabled: !!shop,
    });

    // Mutations
    const followMutation = useMutation({
        mutationFn: () => shopsService.followShop(shop!.id),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['shop', slug] });
            toast.success(`Following ${shop?.store_name}`);
        },
    });

    const unfollowMutation = useMutation({
        mutationFn: () => shopsService.unfollowShop(shop!.id),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['shop', slug] });
            toast.success(`Unfollowed ${shop?.store_name}`);
        },
    });

    const startChatMutation = useMutation({
        mutationFn: () => chatService.startShopChat(shop!.id),
        onSuccess: (data) => {
            router.push(`/messages?id=${data.conversation_id}&type=shop`);
        },
        onError: (err: any) => {
            toast.error(err.response?.data?.error || 'Failed to start chat');
        }
    });

    if (isLoadingShop) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
                <Loader2 className="size-10 animate-spin text-primary" />
                <p className="text-muted-foreground animate-pulse">Loading shop profile...</p>
            </div>
        );
    }

    if (shopError || !shop) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh] gap-6 text-center px-4">
                <div className="size-20 bg-muted rounded-full flex items-center justify-center">
                    <Package className="size-10 text-muted-foreground" />
                </div>
                <div className="space-y-2">
                    <h2 className="text-2xl font-bold">Shop Not Found</h2>
                    <p className="text-muted-foreground max-w-md">
                        The shop you're looking for might have been closed or the link is incorrect.
                    </p>
                </div>
                <Button onClick={() => router.push('/shops')}>Browse All Shops</Button>
            </div>
        );
    }

    const products = productsData?.products || [];

    return (
        <div className="max-w-7xl mx-auto pb-12">
            {/* Cover and Header */}
            <div className="relative mb-24">
                {/* Cover Photo */}
                <div className="h-48 md:h-80 bg-muted relative rounded-3xl overflow-hidden">
                    {shop.cover_url ? (
                        <Image
                            src={shop.cover_url}
                            alt={shop.store_name}
                            fill
                            className="object-cover"
                        />
                    ) : (
                        <div className="absolute inset-0 bg-gradient-to-br from-primary/20 to-secondary/20" />
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

                    <Button
                        variant="secondary"
                        size="sm"
                        className="absolute top-4 left-4 rounded-full bg-white/20 backdrop-blur-md text-white border-white/20 hover:bg-white/40"
                        onClick={() => router.back()}
                    >
                        <ArrowLeft className="size-4 mr-2" />
                        Back
                    </Button>
                </div>

                {/* Profile Header Overlay */}
                <div className="absolute -bottom-16 left-0 right-0 px-6 md:px-12 flex flex-col md:flex-row items-end gap-6">
                    {/* Logo */}
                    <div className="relative size-32 md:size-40 rounded-3xl overflow-hidden border-4 border-background shadow-2xl bg-white flex-shrink-0">
                        {shop.logo_url ? (
                            <Image
                                src={shop.logo_url}
                                alt={shop.store_name}
                                fill
                                className="object-cover"
                            />
                        ) : (
                            <div className="flex items-center justify-center h-full bg-primary/10 text-primary font-bold text-4xl">
                                {shop.store_name.charAt(0)}
                            </div>
                        )}
                    </div>

                    {/* Shop Info */}
                    <div className="flex-1 pb-2 md:pb-4 space-y-2">
                        <div className="flex flex-wrap items-center gap-3">
                            <h1 className="text-3xl md:text-4xl font-black tracking-tight flex items-center gap-2">
                                {shop.store_name}
                                {shop.is_verified && <ShieldCheck className="size-6 text-primary fill-primary text-white" />}
                            </h1>
                            <Badge variant="secondary" className="bg-primary/10 text-primary border-none">
                                {shop.category?.display_name || 'Retailer'}
                            </Badge>
                        </div>
                        <p className="text-lg text-muted-foreground max-w-2xl line-clamp-1">
                            {shop.tagline || 'Welcome to our store!'}
                        </p>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2 pb-4">
                        {shop.is_following ? (
                            <Button variant="outline" className="rounded-xl border-primary text-primary" onClick={() => unfollowMutation.mutate()}>
                                Following
                            </Button>
                        ) : (
                            <Button className="rounded-xl px-8" onClick={() => followMutation.mutate()} disabled={!isAuthenticated}>
                                Follow
                            </Button>
                        )}
                        <Button variant="outline" size="icon" className="rounded-xl">
                            <Share2 className="size-5" />
                        </Button>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 px-4 md:px-0">
                {/* Left Column: Sidebar Info */}
                <div className="space-y-6">
                    <Card className="rounded-2xl border-none shadow-sm bg-muted/30">
                        <CardContent className="p-6 space-y-6">
                            <div className="space-y-4">
                                <h3 className="font-bold text-lg">About Store</h3>
                                <p className="text-muted-foreground leading-relaxed">
                                    {shop.about || 'No description available for this store.'}
                                </p>
                            </div>

                            <div className="space-y-4 pt-4 border-t">
                                <div className="flex items-center gap-3">
                                    <div className="size-10 rounded-xl bg-background flex items-center justify-center text-primary">
                                        <MapPin className="size-5" />
                                    </div>
                                    <div>
                                        <p className="text-xs text-muted-foreground uppercase font-semibold">Location</p>
                                        <p className="font-medium">{shop.town?.name}, {shop.suburb?.name || 'Central'}</p>
                                    </div>
                                </div>

                                <div className="flex items-center gap-3">
                                    <div className="size-10 rounded-xl bg-background flex items-center justify-center text-primary">
                                        <Clock className="size-5" />
                                    </div>
                                    <div>
                                        <p className="text-xs text-muted-foreground uppercase font-semibold">Response Time</p>
                                        <p className="font-medium">Usually within 30 mins</p>
                                    </div>
                                </div>

                                <div className="flex items-center gap-3">
                                    <div className="size-10 rounded-xl bg-background flex items-center justify-center text-primary">
                                        <Calendar className="size-5" />
                                    </div>
                                    <div>
                                        <p className="text-xs text-muted-foreground uppercase font-semibold">Joined</p>
                                        <p className="font-medium">{new Date(shop.created_at).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}</p>
                                    </div>
                                </div>
                            </div>

                            <div className="pt-4 border-t grid grid-cols-2 gap-4">
                                <div className="text-center p-3 bg-background rounded-2xl">
                                    <p className="text-2xl font-black text-primary">{shop.total_products}</p>
                                    <p className="text-xs text-muted-foreground font-bold uppercase mt-1">Products</p>
                                </div>
                                <div className="text-center p-3 bg-background rounded-2xl">
                                    <p className="text-2xl font-black text-primary">{shop.follower_count}</p>
                                    <p className="text-xs text-muted-foreground font-bold uppercase mt-1">Followers</p>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Contact Buttons */}
                    <div className="space-y-3">
                        <Button
                            size="lg"
                            className="w-full h-14 rounded-2xl bg-primary text-white font-bold text-lg gap-3 shadow-lg shadow-primary/20"
                            onClick={() => startChatMutation.mutate()}
                            disabled={startChatMutation.isPending || !isAuthenticated}
                        >
                            {startChatMutation.isPending ? <Loader2 className="size-5 animate-spin" /> : <MessageSquare className="size-6" />}
                            Chat In-App
                        </Button>
                        {shop.whatsapp && (
                            <Button
                                className="w-full h-14 rounded-2xl bg-green-600 hover:bg-green-700 text-white font-bold gap-3"
                                onClick={() => {
                                    shopsService.trackEvent(shop.id, 'whatsapp_click');
                                    window.open(`https://wa.me/${shop.whatsapp}`, '_blank');
                                }}
                            >
                                <MessageCircle className="size-6" />
                                Chat on WhatsApp
                            </Button>
                        )}
                        {shop.phone && (
                            <Button
                                variant="outline"
                                className="w-full h-14 rounded-2xl font-bold gap-3"
                                onClick={() => {
                                    shopsService.trackEvent(shop.id, 'call_click');
                                    window.open(`tel:${shop.phone}`, '_blank');
                                }}
                            >
                                <Phone className="size-5" />
                                Call Store
                            </Button>
                        )}
                    </div>
                </div>

                {/* Right Column: Products */}
                <div className="lg:col-span-2 space-y-6">
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                        <div className="relative flex-1">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
                            <Input
                                placeholder="Search in this store..."
                                className="pl-10 h-12 bg-muted/30 border-none rounded-xl"
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                            />
                        </div>
                        <div className="flex items-center gap-2">
                            <Button variant="outline" className="h-12 rounded-xl gap-2 px-4 font-semibold">
                                <FilterIcon className="size-4" />
                                Categorize
                            </Button>
                        </div>
                    </div>

                    <Tabs defaultValue="all" className="w-full">
                        <TabsList className="bg-transparent h-auto p-0 gap-6 border-b rounded-none w-full justify-start overflow-x-auto">
                            <TabsTrigger
                                value="all"
                                className="rounded-none border-b-2 border-transparent data-[state=active]:border-primary data-[state=active]:bg-transparent px-0 pb-4 h-auto font-bold text-lg"
                            >
                                All Items
                            </TabsTrigger>
                            <TabsTrigger
                                value="featured"
                                className="rounded-none border-b-2 border-transparent data-[state=active]:border-primary data-[state=active]:bg-transparent px-0 pb-4 h-auto font-bold text-lg"
                            >
                                Featured
                            </TabsTrigger>
                            <TabsTrigger
                                value="new"
                                className="rounded-none border-b-2 border-transparent data-[state=active]:border-primary data-[state=active]:bg-transparent px-0 pb-4 h-auto font-bold text-lg"
                            >
                                New Arrivals
                            </TabsTrigger>
                        </TabsList>

                        <TabsContent value="all" className="pt-6">
                            {isLoadingProducts ? (
                                <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
                                    {[...Array(6)].map((_, i) => (
                                        <div key={i} className="aspect-square bg-muted animate-pulse rounded-2xl" />
                                    ))}
                                </div>
                            ) : products.length > 0 ? (
                                <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
                                    {products.map((product) => (
                                        <Link key={product.id} href={`/products/${product.id}`} className="group">
                                            <div className="relative aspect-square rounded-2xl overflow-hidden bg-muted mb-3">
                                                {product.images?.[0] ? (
                                                    <Image
                                                        src={product.images[0]}
                                                        alt={product.title}
                                                        fill
                                                        className="object-cover transition-transform group-hover:scale-110"
                                                    />
                                                ) : (
                                                    <div className="flex items-center justify-center h-full">
                                                        <Package className="size-10 text-muted-foreground/20" />
                                                    </div>
                                                )}
                                                {product.compare_at_price && product.compare_at_price > product.price && (
                                                    <Badge className="absolute top-2 left-2 bg-primary text-white border-none">
                                                        Sale
                                                    </Badge>
                                                )}
                                            </div>
                                            <h4 className="font-bold line-clamp-2 group-hover:text-primary transition-colors">{product.title}</h4>
                                            <div className="flex items-center gap-2 mt-1">
                                                <p className="text-primary font-black">${product.price}</p>
                                                {product.compare_at_price && product.compare_at_price > product.price && (
                                                    <p className="text-muted-foreground text-sm line-through">${product.compare_at_price}</p>
                                                )}
                                            </div>
                                        </Link>
                                    ))}
                                </div>
                            ) : (
                                <div className="py-20 text-center space-y-4">
                                    <div className="size-16 bg-muted rounded-full flex items-center justify-center mx-auto opacity-50">
                                        <Search className="size-8" />
                                    </div>
                                    <p className="text-muted-foreground font-medium">No products match your criteria.</p>
                                </div>
                            )}
                        </TabsContent>
                    </Tabs>
                </div>
            </div>
        </div>
    );
}
