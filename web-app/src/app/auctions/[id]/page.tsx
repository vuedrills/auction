'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    ChevronLeft,
    Share2,
    MapPin,
    Clock,
    Gavel,
    Heart,
    MessageSquare,
    ArrowRight,
    Loader2,
    ShieldCheck,
    Star,
    AlertCircle
} from 'lucide-react';
import Image from 'next/image';
import Link from 'next/link';
import { toast } from 'sonner';

import { auctionsService } from '@/services/auctions';
import { chatService } from '@/services/chat';
import { useCountdown } from '@/hooks/useCountdown';
import { useWebSocket } from '@/hooks/useWebSocket';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';

export default function AuctionDetailsPage() {
    const { id } = useParams() as { id: string };
    const router = useRouter();
    const queryClient = useQueryClient();
    const [bidAmount, setBidAmount] = useState<string>('');

    // WebSocket integration
    const { subscribeToAuction, unsubscribeFromAuction } = useWebSocket((message) => {
        if (message.type === 'bid:new' && message.auction_id === id) {
            queryClient.invalidateQueries({ queryKey: ['auction', id] });
            queryClient.invalidateQueries({ queryKey: ['auction-bids', id] });
        }
    });

    useEffect(() => {
        subscribeToAuction(id);
        return () => unsubscribeFromAuction(id);
    }, [id, subscribeToAuction, unsubscribeFromAuction]);

    // Queries
    const { data: auction, isLoading, error } = useQuery({
        queryKey: ['auction', id],
        queryFn: () => auctionsService.getAuctionById(id),
    });

    const { data: bids } = useQuery({
        queryKey: ['auction-bids', id],
        queryFn: () => auctionsService.getBidHistory(id),
        enabled: !!auction,
    });

    // Mutations
    const bidMutation = useMutation({
        mutationFn: (amount: number) => auctionsService.placeBid(id, amount),
        onSuccess: () => {
            toast.success('Bid placed successfully!');
            setBidAmount('');
            queryClient.invalidateQueries({ queryKey: ['auction', id] });
            queryClient.invalidateQueries({ queryKey: ['auction-bids', id] });
        },
        onError: (error: any) => {
            const message = error.response?.data?.error || 'Failed to place bid. Please try again.';
            toast.error(message);
        },
    });

    const startChatMutation = useMutation({
        mutationFn: () => chatService.startAuctionChat(id),
        onSuccess: (data) => {
            router.push(`/messages`);
        },
        onError: (err: any) => {
            toast.error(err.response?.data?.error || 'Failed to start chat');
        }
    });

    const { timeLeft, isExpired, isEndingSoon } = useCountdown(auction?.end_time || '');

    if (isLoading) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh]">
                <Loader2 className="size-8 animate-spin text-primary mb-4" />
                <p className="text-muted-foreground animate-pulse">Loading auction details...</p>
            </div>
        );
    }

    if (error || !auction) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[40vh] space-y-4">
                <AlertCircle className="size-12 text-destructive opacity-20" />
                <h2 className="text-xl font-bold">Auction not found</h2>
                <p className="text-muted-foreground">The auction you are looking for does not exist or has been removed.</p>
                <Button onClick={() => router.back()} variant="outline">
                    Go Back
                </Button>
            </div>
        );
    }

    const currentPrice = auction.current_price || auction.starting_price;
    const minNextBid = auction.min_next_bid || (currentPrice + auction.bid_increment);

    const handlePlaceBid = () => {
        const amount = parseFloat(bidAmount);
        if (isNaN(amount)) {
            toast.error('Please enter a valid bid amount');
            return;
        }
        if (amount < minNextBid) {
            toast.error(`Minimum bid is $${minNextBid.toFixed(2)}`);
            return;
        }
        bidMutation.mutate(amount);
    };

    return (
        <div className="max-w-6xl mx-auto px-4 py-6 pb-32 lg:pb-12">
            {/* Header / Breadcrumbs */}
            <div className="flex items-center justify-between mb-6">
                <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => router.back()}
                    className="gap-2 -ml-2 text-muted-foreground hover:text-foreground"
                >
                    <ChevronLeft className="size-4" />
                    Back
                </Button>
                <div className="flex gap-2">
                    <Button variant="ghost" size="icon" className="rounded-full">
                        <Share2 className="size-4" />
                    </Button>
                    <Button variant="ghost" size="icon" className="rounded-full">
                        <Heart className="size-4" />
                    </Button>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                {/* Left Column: Images & Description */}
                <div className="lg:col-span-12 xl:col-span-8 flex flex-col gap-6">
                    {/* Location & Title Header */}
                    <div>
                        <div className="flex items-center gap-2 text-primary uppercase tracking-wider text-xs font-bold mb-2">
                            <MapPin className="size-3" />
                            {auction.town?.name} {auction.suburb?.name && `• ${auction.suburb.name}`}
                        </div>
                        <h1 className="text-3xl lg:text-4xl font-extrabold tracking-tight mb-2">
                            {auction.title}
                        </h1>
                        <div className="flex items-center gap-3">
                            <Badge variant="secondary" className="bg-primary/5 text-primary border-primary/10">
                                {auction.category?.name}
                            </Badge>
                            <span className="text-xs text-muted-foreground underline">
                                {auction.condition}
                            </span>
                        </div>
                    </div>

                    {/* Image Gallery */}
                    <div className="relative aspect-[16/9] lg:aspect-[21/9] rounded-2xl overflow-hidden bg-muted">
                        {auction.images?.[0] ? (
                            <Image
                                src={auction.images[0]}
                                alt={auction.title}
                                fill
                                className="object-cover"
                                priority
                                onError={(e) => {
                                    const target = e.target as HTMLImageElement;
                                    target.src = 'https://via.placeholder.com/800x450?text=Auction+Image+Unavailable';
                                }}
                            />
                        ) : (
                            <div className="flex items-center justify-center h-full">
                                <Gavel className="size-16 opacity-10" />
                            </div>
                        )}

                        {/* Featured Badge */}
                        {auction.is_featured && (
                            <Badge className="absolute top-4 left-4 bg-orange-500 hover:bg-orange-500">
                                Featured
                            </Badge>
                        )}

                        {/* Status Overlay */}
                        {isExpired && (
                            <div className="absolute inset-0 bg-background/60 backdrop-blur-[2px] flex items-center justify-center">
                                <Badge variant="secondary" className="text-xl px-6 py-2 uppercase tracking-widest font-black">
                                    Auction Ended
                                </Badge>
                            </div>
                        )}
                    </div>

                    {/* Description */}
                    <Card className="border-none shadow-sm bg-muted/30">
                        <CardContent className="p-6">
                            <h3 className="text-lg font-bold mb-3">Description</h3>
                            <p className="text-muted-foreground leading-relaxed whitespace-pre-wrap">
                                {auction.description || 'No description provided.'}
                            </p>

                            <hr className="my-6 border-foreground/5" />

                            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                                <div>
                                    <p className="text-xs text-muted-foreground mb-1 uppercase tracking-wider font-bold">Condition</p>
                                    <p className="text-sm font-semibold capitalize">{auction.condition.replace('_', ' ')}</p>
                                </div>
                                <div>
                                    <p className="text-xs text-muted-foreground mb-1 uppercase tracking-wider font-bold">Shipping</p>
                                    <p className="text-sm font-semibold">
                                        {auction.shipping_available ? 'Available' : 'Pickup Only'}
                                    </p>
                                </div>
                                <div>
                                    <p className="text-xs text-muted-foreground mb-1 uppercase tracking-wider font-bold">Starts</p>
                                    <p className="text-sm font-semibold">
                                        {auction.created_at ? new Date(auction.created_at).toLocaleDateString() : 'N/A'}
                                    </p>
                                </div>
                                <div>
                                    <p className="text-xs text-muted-foreground mb-1 uppercase tracking-wider font-bold">Ends</p>
                                    <p className="text-sm font-semibold">
                                        {auction.end_time ? new Date(auction.end_time).toLocaleDateString() : 'N/A'}
                                    </p>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Seller Information */}
                    <div className="flex items-center gap-4 p-4 rounded-2xl border bg-background hover:border-primary/50 transition-colors group">
                        <div className="relative">
                            <div className="size-12 rounded-full bg-muted border border-foreground/5 overflow-hidden">
                                {auction.seller?.avatar_url ? (
                                    <Image
                                        src={auction.seller.avatar_url}
                                        alt={auction.seller.full_name || 'Seller'}
                                        width={48}
                                        height={48}
                                        className="object-cover"
                                        onError={(e) => {
                                            const target = e.target as HTMLImageElement;
                                            target.src = `https://ui-avatars.com/api/?name=${auction.seller?.full_name || 'S'}&background=random`;
                                        }}
                                    />
                                ) : (
                                    <div className="size-full flex items-center justify-center bg-primary/10 text-primary font-bold">
                                        {auction.seller?.username?.[0].toUpperCase() || 'S'}
                                    </div>
                                )}
                            </div>
                            <div className="absolute -bottom-1 -right-1 bg-background p-0.5 rounded-full">
                                <ShieldCheck className="size-4 text-green-500 fill-green-100" />
                            </div>
                        </div>
                        <div className="flex-1">
                            <div className="flex items-center gap-2">
                                <h4 className="font-bold">{auction.seller?.full_name || auction.seller?.username}</h4>
                                <div className="flex items-center gap-1 text-xs font-bold px-2 py-0.5 rounded-full bg-yellow-400/10 text-yellow-600">
                                    <Star className="size-3 fill-current" />
                                    4.9
                                </div>
                            </div>
                            <p className="text-xs text-muted-foreground">Local Seller • 24 Sales</p>
                        </div>
                        <Button
                            variant="ghost"
                            size="sm"
                            className="gap-2 group-hover:bg-primary group-hover:text-white transition-all"
                            onClick={() => startChatMutation.mutate()}
                            disabled={startChatMutation.isPending}
                        >
                            <MessageSquare className="size-4" />
                            <span className="hidden sm:inline">Chat</span>
                        </Button>
                    </div>
                </div>

                {/* Right Column: Bidding Card */}
                <div className="lg:col-span-12 xl:col-span-4 space-y-6">
                    <Card className="border-none shadow-xl bg-background sticky top-24">
                        <CardContent className="p-6 space-y-6">
                            {/* Live Status */}
                            <div className="flex justify-between items-start gap-4">
                                <div>
                                    <p className="text-xs font-bold text-muted-foreground uppercase tracking-widest mb-1">Current Bid</p>
                                    <div className="text-4xl font-black tracking-tight text-primary">
                                        ${currentPrice.toFixed(2)}
                                    </div>
                                </div>
                                <div className="text-right">
                                    <p className="text-xs font-bold text-muted-foreground uppercase tracking-widest mb-1">Ends In</p>
                                    <div className={cn(
                                        "flex items-center justify-end gap-1.5 font-bold tabular-nums text-lg",
                                        isEndingSoon ? "text-destructive animate-pulse" : "text-primary"
                                    )}>
                                        <Clock className="size-4" />
                                        {timeLeft}
                                    </div>
                                </div>
                            </div>

                            <hr className="border-foreground/5" />

                            {/* Highest Bidder Status */}
                            {auction.user_is_high_bidder && !isExpired && (
                                <div className="flex items-center gap-3 p-4 bg-green-500/10 border border-green-500/20 rounded-xl">
                                    <div className="size-10 rounded-full bg-green-500/20 flex items-center justify-center">
                                        <Star className="size-5 text-green-500" />
                                    </div>
                                    <div>
                                        <p className="font-bold text-green-600 dark:text-green-400">You're the highest bidder!</p>
                                        <p className="text-xs text-muted-foreground">You'll win if no one outbids you</p>
                                    </div>
                                </div>
                            )}

                            {auction.user_has_bid && !auction.user_is_high_bidder && !isExpired && (
                                <div className="flex items-center gap-3 p-4 bg-destructive/10 border border-destructive/20 rounded-xl">
                                    <div className="size-10 rounded-full bg-destructive/20 flex items-center justify-center">
                                        <AlertCircle className="size-5 text-destructive" />
                                    </div>
                                    <div>
                                        <p className="font-bold text-destructive">You've been outbid!</p>
                                        <p className="text-xs text-muted-foreground">Place a higher bid to win this auction</p>
                                    </div>
                                </div>
                            )}

                            {/* Bidding Input */}
                            <div className="space-y-4">
                                {!isExpired ? (
                                    <>
                                        <div className="relative">
                                            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-muted-foreground font-bold">
                                                $
                                            </div>
                                            <Input
                                                type="number"
                                                placeholder={`${minNextBid}+`}
                                                value={bidAmount}
                                                onChange={(e) => setBidAmount(e.target.value)}
                                                className="pl-7 py-6 text-lg font-black bg-muted/30 border-none rounded-xl"
                                                disabled={bidMutation.isPending}
                                            />
                                        </div>
                                        <Button
                                            size="lg"
                                            className="w-full py-6 text-lg font-bold shadow-lg shadow-primary/20"
                                            onClick={handlePlaceBid}
                                            disabled={bidMutation.isPending}
                                        >
                                            {bidMutation.isPending ? (
                                                <Loader2 className="size-5 animate-spin mr-2" />
                                            ) : (
                                                <Gavel className="size-5 mr-2" />
                                            )}
                                            Place Real Bid
                                        </Button>
                                        <p className="text-[10px] text-center text-muted-foreground uppercase font-bold tracking-tighter">
                                            Minimum next bid: <span className="text-foreground">${minNextBid.toFixed(2)}</span>
                                        </p>
                                    </>
                                ) : (
                                    <div className="text-center py-4 bg-muted/30 rounded-xl space-y-2">
                                        <p className="font-bold text-muted-foreground">This auction has ended.</p>
                                        <Link href="/">
                                            <Button variant="link" className="text-primary font-bold">
                                                Browse more auctions
                                            </Button>
                                        </Link>
                                    </div>
                                )}
                            </div>

                            {/* Bid History Preview */}
                            <div className="space-y-4">
                                <div className="flex items-center justify-between">
                                    <h4 className="font-bold">Bid History</h4>
                                    <span className="text-xs text-muted-foreground">{auction.total_bids} bids total</span>
                                </div>
                                <div className="space-y-3">
                                    {bids && bids.length > 0 ? (
                                        bids.slice(0, 5).map((bid: any, index: number) => (
                                            <div key={bid.id} className="flex items-center justify-between group">
                                                <div className="flex items-center gap-2">
                                                    <div className="size-8 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[10px]">
                                                        {bid.bidder_name?.[0].toUpperCase() || 'B'}
                                                    </div>
                                                    <div className="flex flex-col">
                                                        <span className="text-xs font-bold leading-none">{bid.bidder_name || 'Anonymous'}</span>
                                                        <span className="text-[10px] text-muted-foreground">
                                                            {new Date(bid.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                        </span>
                                                    </div>
                                                </div>
                                                <span className={cn(
                                                    "text-sm font-bold",
                                                    index === 0 ? "text-primary" : "text-muted-foreground"
                                                )}>
                                                    ${bid.amount.toFixed(2)}
                                                </span>
                                            </div>
                                        ))
                                    ) : (
                                        <div className="text-center py-4 text-xs text-muted-foreground">
                                            No bids yet. Be the first!
                                        </div>
                                    )}
                                </div>
                                {bids && bids.length > 5 && (
                                    <Button variant="ghost" className="w-full text-xs font-bold text-muted-foreground gap-2">
                                        View all bids <ArrowRight className="size-3" />
                                    </Button>
                                )}
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    );
}
