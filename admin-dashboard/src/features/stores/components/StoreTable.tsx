'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient, keepPreviousData } from '@tanstack/react-query';
import { getStores, verifyStore, adminUpdateStore } from '@/features/stores/storeService';
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
import { useRouter } from 'next/navigation';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { MoreHorizontal, Search, Loader2 } from 'lucide-react';
import { format } from 'date-fns';
import { TownFilter } from '@/components/filters/TownFilter';
import { cn } from '@/lib/utils';

export function StoreTable() {
    const router = useRouter();
    const [page, setPage] = useState(1);
    const [search, setSearch] = useState('');
    const [selectedTown, setSelectedTown] = useState<string | null>(null);
    const [selectedSuburb, setSelectedSuburb] = useState<string | null>(null);

    const { data, isLoading, isError } = useQuery({
        queryKey: ['stores', page, search, selectedTown, selectedSuburb],
        queryFn: () => getStores({
            page,
            limit: 10,
            search,
            town_id: selectedTown || undefined,
            suburb_id: selectedSuburb || undefined,
            include_inactive: true, // Include deactivated stores
        }),
        placeholderData: keepPreviousData,
    });

    const queryClient = useQueryClient();

    const verifyMutation = useMutation({
        mutationFn: (id: string) => verifyStore(id),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['stores'] });
            alert('Store verified successfully');
        },
        onError: (err: any) => {
            alert('Error: ' + (err.response?.data?.error || err.message));
        }
    });

    const deactivateMutation = useMutation({
        mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
            adminUpdateStore(id, { is_active: isActive }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['stores'] });
        },
        onError: (err: any) => {
            alert('Error: ' + (err.response?.data?.error || err.message));
        }
    });

    const handleVerify = (id: string) => {
        if (confirm('Are you sure you want to verify this store?')) {
            verifyMutation.mutate(id);
        }
    };

    const handleToggleActive = (id: string, currentlyActive: boolean) => {
        const action = currentlyActive ? 'deactivate' : 'reactivate';
        if (confirm(`Are you sure you want to ${action} this store?`)) {
            deactivateMutation.mutate({ id, isActive: !currentlyActive });
        }
    };

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        setPage(1);
    };

    if (isLoading) return <div className="flex justify-center p-8"><Loader2 className="animate-spin text-primary" /></div>;
    if (isError) return <div className="p-8 text-destructive border border-destructive/20 rounded-md bg-destructive/10">Error loading stores.</div>;

    return (
        <div className="space-y-4">
            <div className="flex items-center justify-between gap-4 flex-wrap">
                <form onSubmit={handleSearch} className="flex items-center gap-2">
                    <Input
                        placeholder="Search stores..."
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
                            <TableHead className="w-[80px]">Logo</TableHead>
                            <TableHead>Store Name</TableHead>
                            <TableHead>Owner</TableHead>
                            <TableHead>Status</TableHead>
                            <TableHead>Products</TableHead>
                            <TableHead>Created At</TableHead>
                            <TableHead className="text-right">Actions</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {data?.stores?.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={7} className="text-center h-24 text-muted-foreground">
                                    No stores found.
                                </TableCell>
                            </TableRow>
                        ) : (
                            data?.stores?.map((store) => (
                                <TableRow
                                    key={store.id}
                                    className={cn(!store.is_active && "opacity-60 bg-muted/30")}
                                >
                                    <TableCell>
                                        <div className={cn(
                                            "h-10 w-10 rounded-full overflow-hidden bg-muted flex items-center justify-center border",
                                            !store.is_active && "grayscale"
                                        )}>
                                            {store.logo_url ? (
                                                <img src={store.logo_url} alt={store.store_name} className="h-full w-full object-cover" />
                                            ) : (
                                                <span className="text-xs font-bold text-muted-foreground">{store.store_name?.substring(0, 2).toUpperCase()}</span>
                                            )}
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        <div className="flex flex-col">
                                            <span className="font-medium text-foreground">{store.store_name}</span>
                                            <span className="text-xs text-muted-foreground">{store.slug}</span>
                                        </div>
                                    </TableCell>
                                    <TableCell>{store.owner?.username || 'Unknown'}</TableCell>
                                    <TableCell>
                                        <div className="flex flex-col gap-1">
                                            {!store.is_active ? (
                                                <Badge variant="destructive">Deactivated</Badge>
                                            ) : store.is_verified ? (
                                                <Badge variant="secondary" className="bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300">Verified</Badge>
                                            ) : (
                                                <Badge variant="outline" className="text-muted-foreground">Unverified</Badge>
                                            )}
                                        </div>
                                    </TableCell>
                                    <TableCell>{store.total_products}</TableCell>
                                    <TableCell className="text-sm text-muted-foreground">
                                        {store.created_at ? format(new Date(store.created_at), 'MMM d, yyyy') : '-'}
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
                                                <DropdownMenuItem onClick={() => router.push(`/dashboard/stores/${store.id}`)}>View Details</DropdownMenuItem>
                                                <DropdownMenuItem onClick={() => router.push(`/dashboard/stores/${store.id}/edit`)}>Edit Store</DropdownMenuItem>
                                                <DropdownMenuItem onClick={() => router.push(`/dashboard/stores/${store.id}/products`)}>Manage Products</DropdownMenuItem>
                                                {!store.is_verified && store.is_active && (
                                                    <DropdownMenuItem className="text-blue-600" onClick={() => handleVerify(store.id)}>
                                                        Verify Store
                                                    </DropdownMenuItem>
                                                )}
                                                {store.is_active ? (
                                                    <DropdownMenuItem className="text-destructive" onClick={() => handleToggleActive(store.id, true)}>
                                                        Deactivate
                                                    </DropdownMenuItem>
                                                ) : (
                                                    <DropdownMenuItem className="text-green-600" onClick={() => handleToggleActive(store.id, false)}>
                                                        Reactivate
                                                    </DropdownMenuItem>
                                                )}
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
                    Showing {(page - 1) * 10 + 1} to {Math.min(page * 10, data?.total_count || 0)} of {data?.total_count || 0} entries
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
                        onClick={() => setPage((old) => ((data?.total_count && page * 10 < data.total_count) ? old + 1 : old))}
                        disabled={!data?.total_count || page * 10 >= data.total_count}
                    >
                        Next
                    </Button>
                </div>
            </div>
        </div>
    );
}
