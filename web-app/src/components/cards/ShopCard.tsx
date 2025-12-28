'use client';

import Link from 'next/link';
import Image from 'next/image';
import { MapPin, Star, Package, ShieldCheck, ArrowRight, MessageCircle } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Store } from '@/services/shops';
import { cn } from '@/lib/utils';

interface ShopCardProps {
    shop: Store;
    variant?: 'grid' | 'list' | 'featured';
}

export function ShopCard({ shop, variant = 'grid' }: ShopCardProps) {
    const isStale = shop.is_stale;

    if (variant === 'featured') {
        return (
            <Link href={`/shops/${shop.slug}`}>
                <div className="group relative overflow-hidden rounded-2xl aspect-[4/5] bg-muted">
                    {shop.cover_url ? (
                        <Image
                            src={shop.cover_url}
                            alt={shop.store_name}
                            fill
                            className="object-cover transition-transform duration-500 group-hover:scale-110"
                        />
                    ) : (
                        <div className="absolute inset-0 bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
                            <Package className="size-12 text-primary/20" />
                        </div>
                    )}

                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />

                    <div className="absolute bottom-0 left-0 right-0 p-6">
                        <div className="flex items-center gap-3 mb-3">
                            <div className="relative size-12 rounded-xl overflow-hidden border-2 border-white/20 bg-white">
                                {shop.logo_url ? (
                                    <Image
                                        src={shop.logo_url}
                                        alt={shop.store_name}
                                        fill
                                        className="object-cover"
                                    />
                                ) : (
                                    <div className="flex items-center justify-center h-full bg-primary/10 text-primary font-bold">
                                        {shop.store_name.charAt(0)}
                                    </div>
                                )}
                            </div>
                            <div>
                                <h3 className="text-lg font-bold text-white leading-tight flex items-center gap-1.5">
                                    {shop.store_name}
                                    {shop.is_verified && <ShieldCheck className="size-4 text-primary fill-primary text-white" />}
                                </h3>
                                <p className="text-white/70 text-sm line-clamp-1">{shop.tagline}</p>
                            </div>
                        </div>
                        <div className="flex items-center gap-3">
                            <Badge variant="secondary" className="bg-white/10 text-white border-none backdrop-blur-md">
                                {shop.total_products} Products
                            </Badge>
                            <div className="flex items-center gap-1 text-white/80 text-sm">
                                <MapPin className="size-3" />
                                {shop.town?.name || 'Local'}
                            </div>
                        </div>
                    </div>
                </div>
            </Link>
        );
    }

    return (
        <Card className={cn(
            "group overflow-hidden transition-all duration-300 hover:shadow-xl hover:-translate-y-1 border-none bg-card",
            isStale && "opacity-75 grayscale-[0.5]"
        )}>
            <div className="relative aspect-video overflow-hidden">
                {shop.cover_url ? (
                    <Image
                        src={shop.cover_url}
                        alt={shop.store_name}
                        fill
                        className="object-cover transition-transform duration-500 group-hover:scale-105"
                    />
                ) : (
                    <div className="absolute inset-0 bg-muted flex items-center justify-center">
                        <Package className="size-12 text-muted-foreground/20" />
                    </div>
                )}

                {shop.is_featured && (
                    <Badge className="absolute top-3 left-3 bg-primary text-white border-none shadow-lg">
                        Featured
                    </Badge>
                )}

                <div className="absolute top-3 right-3">
                    <div className="flex items-center gap-1.5 px-2 py-1 rounded-full bg-black/50 backdrop-blur-md text-white text-xs font-semibold">
                        <div className="size-1.5 rounded-full bg-green-500 animate-pulse" />
                        Online
                    </div>
                </div>
            </div>

            <CardContent className="p-5 relative">
                <div className="absolute -top-10 left-5">
                    <div className="relative size-16 rounded-2xl overflow-hidden border-4 border-card shadow-lg bg-card bg-white">
                        {shop.logo_url ? (
                            <Image
                                src={shop.logo_url}
                                alt={shop.store_name}
                                fill
                                className="object-cover"
                            />
                        ) : (
                            <div className="flex items-center justify-center h-full bg-primary/10 text-primary font-bold text-xl">
                                {shop.store_name.charAt(0)}
                            </div>
                        )}
                    </div>
                </div>

                <div className="mt-8">
                    <div className="flex items-start justify-between gap-2 mb-1">
                        <h3 className="font-bold text-lg leading-tight group-hover:text-primary transition-colors flex items-center gap-1.5">
                            {shop.store_name}
                            {shop.is_verified && <ShieldCheck className="size-4 text-primary" />}
                        </h3>
                    </div>

                    <p className="text-muted-foreground text-sm line-clamp-1 mb-4">
                        {shop.tagline || 'Local trusted seller'}
                    </p>

                    <div className="flex items-center gap-4 mb-5 text-sm">
                        <div className="flex items-center gap-1 text-muted-foreground">
                            <MapPin className="size-4" />
                            {shop.town?.name || 'Zimbabwe'}
                        </div>
                        <div className="flex items-center gap-1 text-muted-foreground">
                            <Package className="size-4" />
                            {shop.total_products} items
                        </div>
                    </div>

                    <div className="flex items-center gap-2">
                        <Link href={`/shops/${shop.slug}`} className="flex-1">
                            <Button className="w-full group/btn rounded-xl" variant="outline">
                                View Shop
                                <ArrowRight className="size-4 ml-2 transition-transform group-hover/btn:translate-x-1" />
                            </Button>
                        </Link>
                        {shop.whatsapp && (
                            <Button size="icon" variant="secondary" className="rounded-xl text-green-600 hover:bg-green-50 transition-colors">
                                <MessageCircle className="size-5" />
                            </Button>
                        )}
                    </div>
                </div>
            </CardContent>
        </Card>
    );
}
