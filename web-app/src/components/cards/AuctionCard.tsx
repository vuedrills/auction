'use client';

import Link from 'next/link';
import Image from 'next/image';
import { MapPin, Clock, Users, Heart } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { useCountdown } from '@/hooks/useCountdown';

interface AuctionCardProps {
    auction: {
        id: string;
        title: string;
        current_bid: number;
        starting_price: number;
        end_time: string;
        images: string[];
        town_name?: string;
        suburb_name?: string;
        category_name?: string;
        bid_count?: number;
        status?: string;
        is_watched?: boolean;
    };
    onWatchToggle?: (id: string) => void;
}

export function AuctionCard({ auction, onWatchToggle }: AuctionCardProps) {
    const { timeLeft, isExpired, isEndingSoon } = useCountdown(auction.end_time);

    const currentBid = auction.current_bid || auction.starting_price;
    const imageUrl = auction.images?.[0] || '/placeholder-auction.jpg';

    return (
        <Card className="group overflow-hidden transition-all hover:shadow-lg hover:-translate-y-1">
            <Link href={`/auctions/${auction.id}`}>
                {/* Image */}
                <div className="relative aspect-[4/3] overflow-hidden bg-muted">
                    <Image
                        src={imageUrl}
                        alt={auction.title}
                        fill
                        className="object-cover transition-transform group-hover:scale-105"
                        sizes="(max-width: 768px) 50vw, (max-width: 1200px) 33vw, 25vw"
                    />

                    {/* Status Badge */}
                    {isExpired ? (
                        <Badge className="absolute top-2 left-2 bg-muted text-muted-foreground">
                            Ended
                        </Badge>
                    ) : isEndingSoon ? (
                        <Badge className="absolute top-2 left-2 bg-destructive animate-pulse">
                            Ending Soon
                        </Badge>
                    ) : null}

                    {/* Category Badge */}
                    {auction.category_name && (
                        <Badge variant="secondary" className="absolute top-2 right-2 bg-background/80 backdrop-blur-sm">
                            {auction.category_name}
                        </Badge>
                    )}

                    {/* Watchlist Button */}
                    {onWatchToggle && (
                        <Button
                            variant="ghost"
                            size="icon"
                            className={cn(
                                "absolute bottom-2 right-2 size-8 bg-background/80 backdrop-blur-sm",
                                auction.is_watched && "text-primary"
                            )}
                            onClick={(e) => {
                                e.preventDefault();
                                onWatchToggle(auction.id);
                            }}
                        >
                            <Heart className={cn("size-4", auction.is_watched && "fill-current")} />
                        </Button>
                    )}
                </div>
            </Link>

            <CardContent className="p-3">
                {/* Location */}
                <div className="flex items-center gap-1 text-xs text-muted-foreground mb-1">
                    <MapPin className="size-3" />
                    <span className="truncate">
                        {auction.town_name || 'Unknown'}
                        {auction.suburb_name && ` • ${auction.suburb_name}`}
                    </span>
                </div>

                {/* Title */}
                <Link href={`/auctions/${auction.id}`}>
                    <h3 className="font-semibold text-sm line-clamp-2 group-hover:text-primary transition-colors mb-2">
                        {auction.title}
                    </h3>
                </Link>

                {/* Price and Timer */}
                <div className="flex items-end justify-between">
                    <div>
                        <p className="text-xs text-muted-foreground">Current Bid</p>
                        <p className="text-lg font-bold text-primary">
                            ${currentBid.toFixed(2)}
                        </p>
                    </div>

                    <div className="text-right">
                        {!isExpired && (
                            <>
                                <p className="text-xs text-muted-foreground">Time Left</p>
                                <p className={cn(
                                    "text-sm font-semibold tabular-nums",
                                    isEndingSoon && "text-destructive"
                                )}>
                                    <Clock className="size-3 inline mr-1" />
                                    {timeLeft}
                                </p>
                            </>
                        )}
                    </div>
                </div>

                {/* Bid Count */}
                {auction.bid_count !== undefined && auction.bid_count > 0 && (
                    <div className="flex items-center gap-1 text-xs text-muted-foreground mt-2 pt-2 border-t">
                        <Users className="size-3" />
                        <span>{auction.bid_count} bids</span>
                    </div>
                )}
            </CardContent>
        </Card>
    );
}
