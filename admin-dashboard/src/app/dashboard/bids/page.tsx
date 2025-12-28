'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getAdminBids } from '@/features/admin/adminService';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import { Loader2, Receipt } from 'lucide-react';
import { format } from 'date-fns';
import { TownFilter } from '@/components/filters/TownFilter';
import { Badge } from '@/components/ui/badge';

export default function BidsPage() {
    const [selectedTown, setSelectedTown] = useState<string | null>(null);
    const [selectedSuburb, setSelectedSuburb] = useState<string | null>(null);

    const { data, isLoading, isError } = useQuery({
        queryKey: ['adminBids', selectedTown, selectedSuburb],
        queryFn: () => getAdminBids({
            limit: 100,
            town_id: selectedTown || undefined,
            suburb_id: selectedSuburb || undefined,
        }),
    });

    const bids = data?.bids || [];
    const filteredCount = bids.length;

    if (isLoading) return <div className="flex justify-center p-8"><Loader2 className="animate-spin text-primary" /></div>;
    if (isError) return <div className="p-8 text-destructive">Error loading bids.</div>;

    return (
        <div className="space-y-4">
            <div className="flex items-center justify-between gap-4 flex-wrap">
                <div>
                    <h1 className="text-2xl font-bold flex items-center gap-2">
                        <Receipt className="h-6 w-6" />
                        All Bids
                        <Badge variant="secondary" className="ml-2">{filteredCount}</Badge>
                    </h1>
                    <p className="text-muted-foreground">Monitor all bidding activity across the platform.</p>
                </div>
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
                            <TableHead>Auction</TableHead>
                            <TableHead>Bidder</TableHead>
                            <TableHead>Amount</TableHead>
                            <TableHead>Winning?</TableHead>
                            <TableHead>Time</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {bids.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={5} className="text-center h-24 text-muted-foreground">
                                    No bids found{selectedTown ? ' for selected location' : ''}.
                                </TableCell>
                            </TableRow>
                        ) : (
                            bids.map((bid: any) => (
                                <TableRow key={bid.id}>
                                    <TableCell className="font-medium">{bid.auction_title}</TableCell>
                                    <TableCell>{bid.bidder_username}</TableCell>
                                    <TableCell className="font-bold text-green-600">${bid.amount}</TableCell>
                                    <TableCell>
                                        {bid.is_winning ? (
                                            <span className="px-2 py-1 rounded-full bg-green-100 text-green-800 text-xs font-bold">YES</span>
                                        ) : (
                                            <span className="px-2 py-1 rounded-full bg-gray-100 text-gray-500 text-xs">NO</span>
                                        )}
                                    </TableCell>
                                    <TableCell className="text-sm text-muted-foreground">
                                        {format(new Date(bid.created_at), 'MMM d, HH:mm:ss')}
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </div>
        </div>
    );
}
