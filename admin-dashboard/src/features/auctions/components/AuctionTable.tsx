'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient, keepPreviousData } from '@tanstack/react-query';
import { getAuctions } from '@/features/auctions/auctionService';
import { deleteAdminAuction, approveAdminAuction } from '@/features/admin/adminService';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { MoreHorizontal, Search, Loader2, Ban } from 'lucide-react';
import { format } from 'date-fns';
import { AuctionStatus } from '@/types';
import { TownFilter } from '@/components/filters/TownFilter';

export function AuctionTable() {
    const [page, setPage] = useState(1);
    const [search, setSearch] = useState('');
    const [selectedTown, setSelectedTown] = useState<string | null>(null);
    const [selectedSuburb, setSelectedSuburb] = useState<string | null>(null);
    const router = useRouter();

    const queryClient = useQueryClient();

    const deleteMutation = useMutation({
        mutationFn: deleteAdminAuction,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['auctions'] });
            alert('Auction cancelled successfully');
        },
        onError: (err: any) => {
            alert('Error: ' + (err.response?.data?.error || err.message));
        }
    });

    const handleCancelAuction = (id: string) => {
        if (confirm('Are you sure you want to cancel this auction?')) {
            deleteMutation.mutate(id);
        }
    };

    const approveMutation = useMutation({
        mutationFn: approveAdminAuction,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['auctions'] });
            alert('Auction approved successfully');
        },
        onError: (err: any) => {
            alert('Error: ' + (err.response?.data?.error || err.message));
        }
    });

    const handleApproveAuction = (id: string) => {
        if (confirm('Are you sure you want to approve this auction?')) {
            approveMutation.mutate(id);
        }
    };

    const { data, isLoading, isError } = useQuery({
        queryKey: ['auctions', page, search, selectedTown, selectedSuburb],
        queryFn: () => getAuctions({
            page,
            limit: 50,
            search,
            status: 'all',
            town_id: selectedTown || undefined,
            suburb_id: selectedSuburb || undefined,
        }),
        placeholderData: keepPreviousData,
    });

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        setPage(1);
    };

    const getStatusColor = (status: AuctionStatus) => {
        switch (status) {
            case 'active': return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300';
            case 'pending': return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300';
            case 'ending_soon': return 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-300';
            case 'ended': return 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300';
            case 'sold': return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300';
            case 'cancelled': return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300';
            default: return 'bg-gray-100 text-gray-800';
        }
    };

    if (isLoading) return <div className="flex justify-center p-8"><Loader2 className="animate-spin text-primary" /></div>;
    if (isError) return <div className="p-8 text-destructive border border-destructive/20 rounded-md bg-destructive/10">Error loading auctions.</div>;

    return (
        <div className="space-y-4">
            <div className="flex items-center justify-between gap-4 flex-wrap">
                <form onSubmit={handleSearch} className="flex items-center gap-2">
                    <Input
                        placeholder="Search auctions..."
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        className="w-64 bg-background"
                    />
                    <Button type="submit" variant="secondary" size="icon">
                        <Search className="h-4 w-4" />
                    </Button>
                </form>
                <TownFilter
                    selectedTown={selectedTown}
                    selectedSuburb={selectedSuburb}
                    onTownChange={setSelectedTown}
                    onSuburbChange={setSelectedSuburb}
                />
            </div>

            <div className="rounded-md border bg-card shadow-sm">
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead className="w-[80px]">Image</TableHead>
                            <TableHead>Title</TableHead>
                            <TableHead>Price</TableHead>
                            <TableHead>Status</TableHead>
                            <TableHead>Ends At</TableHead>
                            <TableHead className="text-right">Actions</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {data?.auctions?.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={6} className="text-center h-24 text-muted-foreground">
                                    No auctions found.
                                </TableCell>
                            </TableRow>
                        ) : (
                            data?.auctions?.map((auction) => (
                                <TableRow key={auction.id}>
                                    <TableCell>
                                        <div className="h-10 w-10 rounded overflow-hidden bg-muted flex items-center justify-center border">
                                            {auction.images?.[0] ? (
                                                <img
                                                    src={auction.images[0]}
                                                    alt={auction.title}
                                                    className="h-full w-full object-cover"
                                                    onError={(e) => {
                                                        (e.target as HTMLImageElement).src = 'https://placehold.co/100x100?text=No+Image';
                                                    }}
                                                />
                                            ) : (
                                                <span className="text-[10px] font-medium text-muted-foreground uppercase">No Image</span>
                                            )}
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        <div className="flex flex-col">
                                            <span className="font-medium truncate max-w-[200px]">{auction.title}</span>
                                            <span className="text-xs text-muted-foreground truncate max-w-[200px]">By {auction.seller?.username || 'Unknown'}</span>
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        ${auction.current_price || auction.starting_price}
                                    </TableCell>
                                    <TableCell>
                                        <Badge variant="outline" className={`border-0 ${getStatusColor(auction.status)}`}>
                                            {auction.status.replace('_', ' ')}
                                        </Badge>
                                    </TableCell>
                                    <TableCell className="text-sm">
                                        {auction.end_time ? format(new Date(auction.end_time), 'MMM d, HH:mm') : '-'}
                                    </TableCell>
                                    <TableCell className="text-right">
                                        <DropdownMenu>
                                            <DropdownMenuTrigger asChild>
                                                <Button variant="ghost" size="icon">
                                                    <MoreHorizontal className="h-4 w-4" />
                                                </Button>
                                            </DropdownMenuTrigger>
                                            <DropdownMenuContent align="end">
                                                <DropdownMenuLabel>Actions</DropdownMenuLabel>
                                                <DropdownMenuItem onClick={() => router.push(`/dashboard/auctions/${auction.id}`)}>View Details</DropdownMenuItem>
                                                <DropdownMenuItem>Edit Auction</DropdownMenuItem>
                                                {auction.status === 'pending' && (
                                                    <DropdownMenuItem
                                                        className="text-green-600 focus:text-green-600"
                                                        onClick={() => handleApproveAuction(auction.id)}
                                                    >
                                                        Approve Auction
                                                    </DropdownMenuItem>
                                                )}
                                                <DropdownMenuItem
                                                    className="text-destructive focus:text-destructive"
                                                    onClick={() => handleCancelAuction(auction.id)}
                                                >
                                                    <Ban className="mr-2 h-4 w-4" />
                                                    Cancel Auction
                                                </DropdownMenuItem>
                                            </DropdownMenuContent>
                                        </DropdownMenu>
                                    </TableCell>
                                </TableRow>
                            )))}
                    </TableBody>
                </Table>
            </div>

            {/* Pagination Controls */}
            <div className="flex items-center justify-between">
                <div className="text-sm text-muted-foreground">
                    Showing {(page - 1) * 10 + 1} to {Math.min(page * 10, data?.total || 0)} of {data?.total || 0} entries
                </div>
                <div className="space-x-2">
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPage((old) => Math.max(old - 1, 1))}
                        disabled={page === 1}
                    >
                        Previous
                    </Button>
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPage((old) => (data?.total_pages && old < data.total_pages ? old + 1 : old))}
                        disabled={!data?.total_pages || page >= data.total_pages}
                    >
                        Next
                    </Button>
                </div>
            </div>
        </div>
    );
}
