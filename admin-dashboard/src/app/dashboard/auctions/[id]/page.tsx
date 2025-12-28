'use client';

import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getAdminAuctionDetails, updateAuctionStatus } from '@/features/admin/adminService';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Loader2, ArrowLeft, Gavel, Eye, Clock, User, Tag, MapPin, CheckCircle, XCircle } from 'lucide-react';
import { format } from 'date-fns';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';

export default function AuctionDetailsPage() {
    const params = useParams();
    const router = useRouter();
    const queryClient = useQueryClient();
    const id = params.id as string;

    const { data, isLoading, isError } = useQuery({
        queryKey: ['auction-details', id],
        queryFn: () => getAdminAuctionDetails(id),
    });

    const statusMutation = useMutation({
        mutationFn: ({ status }: { status: string }) => updateAuctionStatus(id, status),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['auction-details', id] });
            alert('Status updated successfully');
        },
    });

    if (isLoading) return <div className="flex justify-center p-12"><Loader2 className="animate-spin h-8 w-8 text-primary" /></div>;
    if (isError) return <div className="p-8 text-destructive">Error loading auction details.</div>;

    const { auction, bids } = data;

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'active': return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300';
            case 'pending': return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300';
            case 'cancelled': return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300';
            case 'sold': return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300';
            default: return 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300';
        }
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center gap-4">
                <Button variant="outline" size="icon" onClick={() => router.back()}>
                    <ArrowLeft className="h-4 w-4" />
                </Button>
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">{auction.title}</h1>
                    <p className="text-muted-foreground font-mono text-sm">{auction.id}</p>
                </div>
                <div className="ml-auto flex gap-2">
                    {auction.status === 'cancelled' && (
                        <Button variant="default" onClick={() => statusMutation.mutate({ status: 'active' })}>
                            Uncancel & Reactivate
                        </Button>
                    )}
                    {auction.status === 'pending' && (
                        <Button variant="default" onClick={() => statusMutation.mutate({ status: 'active' })}>
                            Approve Auction
                        </Button>
                    )}
                    {auction.status === 'active' && (
                        <Button variant="destructive" onClick={() => {
                            if (confirm('Are you sure you want to cancel this auction?')) {
                                statusMutation.mutate({ status: 'cancelled' });
                            }
                        }}>
                            Cancel Auction
                        </Button>
                    )}
                </div>
            </div>

            <div className="grid gap-6 md:grid-cols-3">
                {/* Left Column: Core Info */}
                <Card className="md:col-span-2">
                    <CardHeader>
                        <div className="flex justify-between items-start">
                            <div>
                                <CardTitle>Overview</CardTitle>
                                <CardDescription>Key auction details and status</CardDescription>
                            </div>
                            <Badge className={getStatusColor(auction.status)}>
                                {auction.status.toUpperCase()}
                            </Badge>
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-6">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-1">
                                <span className="text-sm text-muted-foreground flex items-center gap-1">
                                    <Tag className="h-3 w-3" /> Category
                                </span>
                                <p className="font-medium">{auction.category?.name || 'Uncategorized'}</p>
                            </div>
                            <div className="space-y-1">
                                <span className="text-sm text-muted-foreground flex items-center gap-1">
                                    <MapPin className="h-3 w-3" /> Location
                                </span>
                                <p className="font-medium">{auction.town?.name}, {auction.suburb?.name}</p>
                            </div>
                            <div className="space-y-1">
                                <span className="text-sm text-muted-foreground flex items-center gap-1">
                                    <Clock className="h-3 w-3" /> Created
                                </span>
                                <p className="font-medium">{format(new Date(auction.created_at), 'PPP pp')}</p>
                            </div>
                            <div className="space-y-1">
                                <span className="text-sm text-muted-foreground flex items-center gap-1">
                                    <Gavel className="h-3 w-3" /> Ending
                                </span>
                                <p className="font-medium">{auction.end_time ? format(new Date(auction.end_time), 'PPP pp') : 'N/A'}</p>
                            </div>
                        </div>

                        <div className="space-y-2">
                            <span className="text-sm text-muted-foreground">Description</span>
                            <div className="p-4 bg-muted/50 rounded-lg text-sm whitespace-pre-wrap">
                                {auction.description}
                            </div>
                        </div>

                        <div className="space-y-2">
                            <span className="text-sm text-muted-foreground">Images</span>
                            <div className="flex gap-2 overflow-x-auto pb-2">
                                {auction.images?.map((img: string, i: number) => (
                                    <img key={i} src={img} alt="" className="h-32 w-32 object-cover rounded-md border bg-muted" />
                                ))}
                            </div>
                        </div>
                    </CardContent>
                </Card>

                {/* Right Column: Pricing & Seller */}
                <div className="space-y-6">
                    <Card>
                        <CardHeader>
                            <CardTitle>Pricing & Stats</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div className="flex justify-between items-center py-2 border-b">
                                <span className="text-muted-foreground">Starting Price</span>
                                <span className="font-bold">${auction.starting_price}</span>
                            </div>
                            <div className="flex justify-between items-center py-2 border-b">
                                <span className="text-muted-foreground">Current Price</span>
                                <span className="font-bold text-primary text-lg">${auction.current_price}</span>
                            </div>
                            <div className="flex justify-between items-center py-2 border-b">
                                <span className="text-muted-foreground">Reserve Price</span>
                                <span className="font-medium">{auction.reserve_price ? `$${auction.reserve_price}` : 'None'}</span>
                            </div>
                            <div className="grid grid-cols-2 gap-4 mt-4">
                                <div className="p-3 bg-muted/50 rounded-lg text-center">
                                    <Eye className="h-4 w-4 mx-auto mb-1 text-muted-foreground" />
                                    <span className="block text-xl font-bold">{auction.views}</span>
                                    <span className="text-[10px] text-muted-foreground uppercase">Views</span>
                                </div>
                                <div className="p-3 bg-muted/50 rounded-lg text-center">
                                    <Gavel className="h-4 w-4 mx-auto mb-1 text-muted-foreground" />
                                    <span className="block text-xl font-bold">{auction.total_bids}</span>
                                    <span className="text-[10px] text-muted-foreground uppercase">Bids</span>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader>
                            <CardTitle>Seller</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="flex items-center gap-3">
                                <div className="h-12 w-12 rounded-full bg-primary/10 flex items-center justify-center border text-primary font-bold">
                                    {auction.seller?.avatar_url ? (
                                        <img src={auction.seller.avatar_url} className="h-full w-full rounded-full object-cover" />
                                    ) : (
                                        auction.seller?.username?.[0].toUpperCase()
                                    )}
                                </div>
                                <div>
                                    <p className="font-bold cursor-pointer hover:underline text-primary" onClick={() => router.push(`/dashboard/users/${auction.seller_id}`)}>
                                        {auction.seller?.username}
                                    </p>
                                    <p className="text-xs text-muted-foreground">{auction.seller?.email}</p>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>

            {/* Bid History */}
            <Card>
                <CardHeader>
                    <CardTitle>Bid History</CardTitle>
                    <CardDescription>All bids placed on this auction</CardDescription>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>User</TableHead>
                                <TableHead>Amount</TableHead>
                                <TableHead>Date</TableHead>
                                <TableHead>Status</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {bids?.length === 0 ? (
                                <TableRow>
                                    <TableCell colSpan={4} className="text-center py-8 text-muted-foreground">No bids yet</TableCell>
                                </TableRow>
                            ) : (
                                bids?.map((bid: any) => (
                                    <TableRow key={bid.id}>
                                        <TableCell className="font-medium">{bid.username}</TableCell>
                                        <TableCell className="font-bold text-primary">${bid.amount}</TableCell>
                                        <TableCell className="text-muted-foreground">{format(new Date(bid.created_at), 'MMM d, h:mm a')}</TableCell>
                                        <TableCell>
                                            {bid.is_winning ? (
                                                <Badge className="bg-green-100 text-green-800 border-green-200">Winning</Badge>
                                            ) : (
                                                <Badge variant="outline" className="text-muted-foreground">Outbid</Badge>
                                            )}
                                        </TableCell>
                                    </TableRow>
                                ))
                            )}
                        </TableBody>
                    </Table>
                </CardContent>
            </Card>
        </div>
    );
}
