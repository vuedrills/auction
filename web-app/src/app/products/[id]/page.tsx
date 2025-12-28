'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation } from '@tanstack/react-query';
import {
    MessageCircle,
    MessageSquare,
    Share2,
    ShieldCheck,
    Package,
    ArrowLeft,
    Loader2,
    MapPin,
    Store as StoreIcon,
    ChevronRight,
    Info,
    CheckCircle2,
    Phone
} from 'lucide-react';
import { toast } from 'sonner';
import Image from 'next/image';
import Link from 'next/link';

import { shopsService } from '@/services/shops';
import { chatService } from '@/services/chat';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { cn } from '@/lib/utils';

export default function ProductDetailsPage() {
    const { id } = useParams() as { id: string };
    const router = useRouter();
    const [selectedImage, setSelectedImage] = useState(0);

    const { data: product, isLoading, error } = useQuery({
        queryKey: ['product', id],
        queryFn: () => shopsService.getProductById(id),
    });

    const startChatMutation = useMutation({
        mutationFn: () => chatService.startShopChat(product!.store_id, product!.id),
        onSuccess: (data) => {
            router.push(`/messages?id=${data.conversation_id}&type=shop`);
        },
        onError: (err: any) => {
            toast.error(err.response?.data?.error || 'Failed to start chat');
        }
    });

    if (isLoading) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
                <Loader2 className="size-10 animate-spin text-primary" />
                <p className="text-muted-foreground animate-pulse">Loading product details...</p>
            </div>
        );
    }

    if (error || !product) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh] gap-6 text-center px-4">
                <div className="size-20 bg-muted rounded-full flex items-center justify-center">
                    <Package className="size-10 text-muted-foreground" />
                </div>
                <div className="space-y-2">
                    <h2 className="text-2xl font-bold">Product Not Found</h2>
                    <p className="text-muted-foreground max-w-md">
                        This item might have been sold or removed by the seller.
                    </p>
                </div>
                <Button onClick={() => router.push('/shops')}>Continue Shopping</Button>
            </div>
        );
    }

    const hasDiscount = product.compare_at_price && product.compare_at_price > product.price;

    return (
        <div className="max-w-7xl mx-auto pb-20">
            {/* Breadcrumbs */}
            <nav className="flex items-center gap-2 text-sm text-muted-foreground mb-8">
                <Link href="/shops" className="hover:text-primary">Shops</Link>
                <ChevronRight className="size-4" />
                <Link href={`/shops/${product.store?.slug}`} className="hover:text-primary">{product.store?.store_name}</Link>
                <ChevronRight className="size-4" />
                <span className="text-foreground font-medium truncate">{product.title}</span>
            </nav>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
                {/* Images Section */}
                <div className="space-y-4">
                    <div className="relative aspect-square rounded-3xl overflow-hidden bg-muted group">
                        {product.images?.length ? (
                            <Image
                                src={product.images[selectedImage]}
                                alt={product.title}
                                fill
                                className="object-cover transition-transform duration-500 group-hover:scale-105"
                                onError={(e) => {
                                    const target = e.target as HTMLImageElement;
                                    target.src = 'https://via.placeholder.com/600x600?text=Product+Image+Unavailable';
                                }}
                            />
                        ) : (
                            <div className="flex items-center justify-center h-full">
                                <Package className="size-20 text-muted-foreground/20" />
                            </div>
                        )}
                        {hasDiscount && (
                            <Badge className="absolute top-6 left-6 bg-primary text-white text-lg px-4 py-1 border-none shadow-xl">
                                SALE
                            </Badge>
                        )}
                    </div>

                    {/* Thumbnails */}
                    {product.images && product.images.length > 1 && (
                        <div className="flex gap-4 overflow-x-auto pb-2">
                            {product.images.map((img, i) => (
                                <button
                                    key={i}
                                    onClick={() => setSelectedImage(i)}
                                    className={cn(
                                        "relative size-20 rounded-xl overflow-hidden flex-shrink-0 border-2 transition-all",
                                        selectedImage === i ? "border-primary scale-95 shadow-lg" : "border-transparent opacity-60 hover:opacity-100"
                                    )}
                                >
                                    <Image
                                        src={img}
                                        alt=""
                                        fill
                                        className="object-cover"
                                        onError={(e) => {
                                            const target = e.target as HTMLImageElement;
                                            target.src = 'https://via.placeholder.com/100x100?text=Error';
                                        }}
                                    />
                                </button>
                            ))}
                        </div>
                    )}
                </div>

                {/* Info Section */}
                <div className="space-y-8">
                    <div className="space-y-4">
                        <div className="flex items-center justify-between gap-4">
                            <Badge variant="secondary" className="capitalize text-sm px-3 py-1 bg-primary/10 text-primary border-none">
                                {product.condition}
                            </Badge>
                            <Button variant="ghost" size="icon" className="rounded-full">
                                <Share2 className="size-5" />
                            </Button>
                        </div>
                        <h1 className="text-3xl md:text-4xl font-black leading-tight tracking-tight">
                            {product.title}
                        </h1>
                        <div className="flex items-end gap-3">
                            <p className="text-4xl font-black text-primary">${product.price}</p>
                            {hasDiscount && (
                                <p className="text-xl text-muted-foreground line-through pb-1">${product.compare_at_price}</p>
                            )}
                        </div>
                    </div>

                    <div className="flex flex-col gap-3">
                        <Button
                            size="lg"
                            className="w-full h-14 rounded-2xl bg-primary text-white font-bold text-lg gap-3 shadow-lg shadow-primary/20"
                            onClick={() => startChatMutation.mutate()}
                            disabled={startChatMutation.isPending}
                        >
                            {startChatMutation.isPending ? <Loader2 className="size-5 animate-spin" /> : <MessageSquare className="size-6" />}
                            Chat In-App
                        </Button>
                        <div className="grid grid-cols-2 gap-3">
                            {product.store?.whatsapp && (
                                <Button
                                    className="h-12 rounded-xl bg-green-50 border-green-100 text-green-700 hover:bg-green-100 hover:text-green-800 font-bold gap-2"
                                    onClick={() => {
                                        shopsService.trackEvent(product.store?.id!, 'whatsapp_click');
                                        window.open(`https://wa.me/${product.store?.whatsapp}?text=Hi, I'm interested in ${product.title}`, '_blank');
                                    }}
                                >
                                    <MessageCircle className="size-5" />
                                    WhatsApp
                                </Button>
                            )}
                            <Button
                                variant="outline"
                                className="h-12 rounded-xl font-bold gap-2"
                                onClick={() => {
                                    if (product.store?.phone) {
                                        shopsService.trackEvent(product.store?.id!, 'call_click');
                                        window.open(`tel:${product.store?.phone}`, '_blank');
                                    }
                                }}
                            >
                                <Phone className="size-5" />
                                Call
                            </Button>
                        </div>
                    </div>

                    <Card className="rounded-2xl border-none bg-muted/30">
                        <CardContent className="p-6 space-y-4">
                            <h3 className="font-bold text-lg flex items-center gap-2">
                                <Info className="size-5 text-primary" />
                                Product Details
                            </h3>
                            <div className="grid grid-cols-2 gap-y-4 text-sm">
                                <div>
                                    <p className="text-muted-foreground font-medium uppercase text-xs tracking-wider mb-1">Availability</p>
                                    <p className="font-bold text-green-600 flex items-center gap-1.5">
                                        <CheckCircle2 className="size-4" />
                                        In Stock ({product.stock_quantity})
                                    </p>
                                </div>
                                <div>
                                    <p className="text-muted-foreground font-medium uppercase text-xs tracking-wider mb-1">Pricing Type</p>
                                    <p className="font-bold capitalize">{product.pricing_type}</p>
                                </div>
                                <div className="col-span-2 pt-2">
                                    <p className="text-muted-foreground font-medium uppercase text-xs tracking-wider mb-1">Description</p>
                                    <p className="text-base leading-relaxed text-muted-foreground whitespace-pre-wrap">
                                        {product.description || 'No description provided.'}
                                    </p>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Seller Mini Card */}
                    <Link href={`/shops/${product.store?.slug}`}>
                        <div className="group flex items-center justify-between p-6 rounded-3xl border-2 border-transparent hover:border-primary/20 hover:bg-primary/5 transition-all duration-300">
                            <div className="flex items-center gap-4">
                                <div className="relative size-16 rounded-2xl overflow-hidden border bg-white shadow-sm">
                                    {product.store?.logo_url ? (
                                        <Image src={product.store.logo_url} alt="" fill className="object-cover" />
                                    ) : (
                                        <div className="flex items-center justify-center h-full bg-primary/10 text-primary font-bold text-xl">
                                            {product.store?.store_name[0]}
                                        </div>
                                    )}
                                </div>
                                <div>
                                    <div className="flex items-center gap-1.5 mb-0.5">
                                        <h4 className="font-black text-lg group-hover:text-primary transition-colors">{product.store?.store_name}</h4>
                                        {product.store?.is_verified && <ShieldCheck className="size-5 text-primary fill-primary text-white" />}
                                    </div>
                                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                                        <div className="flex items-center gap-1">
                                            <MapPin className="size-3.5" />
                                            {product.store?.town?.name || 'Zimbabwe'}
                                        </div>
                                        <div className="flex items-center gap-1">
                                            <Package className="size-3.5" />
                                            {product.store?.total_products} items
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <Button variant="ghost" size="icon" className="group-hover:translate-x-1 transition-transform">
                                <ChevronRight className="size-6" />
                            </Button>
                        </div>
                    </Link>
                </div>
            </div>
        </div>
    );
}
