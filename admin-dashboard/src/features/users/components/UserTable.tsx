'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient, keepPreviousData } from '@tanstack/react-query';
import { getUsers } from '@/features/users/userService';
import { updateUserStatus, verifyUser } from '@/features/admin/adminService';
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
import { MoreHorizontal, Search, Loader2 } from 'lucide-react';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { format } from 'date-fns';
import { TownFilter } from '@/components/filters/TownFilter';

export function UserTable() {
    const [page, setPage] = useState(1);
    const [search, setSearch] = useState('');
    const [selectedTown, setSelectedTown] = useState<string | null>(null);
    const router = useRouter();

    const { data, isLoading, isError } = useQuery({
        queryKey: ['users', page, search, selectedTown],
        queryFn: () => getUsers({ page, limit: 10, search, town_id: selectedTown || undefined }),
        placeholderData: keepPreviousData,
    });

    const queryClient = useQueryClient();

    const statusMutation = useMutation({
        mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) => updateUserStatus(id, isActive),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['users'] });
        },
        onError: (err: any) => {
            alert('Error: ' + (err.response?.data?.error || err.message));
        }
    });

    const verifyMutation = useMutation({
        mutationFn: ({ id, isVerified }: { id: string; isVerified: boolean }) => verifyUser(id, isVerified),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['users'] });
        },
        onError: (err: any) => {
            alert('Error: ' + (err.response?.data?.error || err.message));
        }
    });

    const handleToggleStatus = (id: string, currentStatus: boolean) => {
        const action = currentStatus ? 'suspend' : 'activate';
        if (confirm(`Are you sure you want to ${action} this user?`)) {
            statusMutation.mutate({ id, isActive: !currentStatus });
        }
    };

    const handleToggleVerify = (id: string, currentVerify: boolean) => {
        const action = currentVerify ? 'unverify' : 'verify';
        if (confirm(`Are you sure you want to ${action} this user?`)) {
            verifyMutation.mutate({ id, isVerified: !currentVerify });
        }
    };

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        setPage(1);
    };

    if (isLoading) return <div className="flex justify-center p-8"><Loader2 className="animate-spin text-primary" /></div>;
    if (isError) return <div className="p-8 text-destructive border border-destructive/20 rounded-md bg-destructive/10">Error loading users. Please try again later.</div>;

    return (
        <div className="space-y-4">
            <div className="flex items-center justify-between gap-4 flex-wrap">
                <form onSubmit={handleSearch} className="flex items-center gap-2">
                    <Input
                        placeholder="Search users..."
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
                    selectedSuburb={null}
                    onTownChange={setSelectedTown}
                    onSuburbChange={() => { }}
                    showSuburb={false}
                />
            </div>

            <div className="rounded-md border bg-card shadow-sm">
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead className="w-[60px]">Avatar</TableHead>
                            <TableHead>User</TableHead>
                            <TableHead>Status</TableHead>
                            <TableHead>Role</TableHead>
                            <TableHead>Joined</TableHead>
                            <TableHead className="text-right">Actions</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {data?.users?.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={6} className="text-center h-24 text-muted-foreground">
                                    No users found.
                                </TableCell>
                            </TableRow>
                        ) : (
                            data?.users?.map((user) => (
                                <TableRow key={user.id}>
                                    <TableCell>
                                        <Avatar>
                                            <AvatarImage src={user.avatar_url} />
                                            <AvatarFallback>{user.username?.[0]?.toUpperCase() || 'U'}</AvatarFallback>
                                        </Avatar>
                                    </TableCell>
                                    <TableCell>
                                        <div className="flex flex-col">
                                            <span className="font-medium text-foreground">{user.username}</span>
                                            <span className="text-xs text-muted-foreground">{user.email}</span>
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        <div className="flex gap-1 flex-wrap">
                                            {user.is_verified && <Badge variant="secondary" className="bg-blue-100 text-blue-800 hover:bg-blue-200 dark:bg-blue-900/30 dark:text-blue-300">Verified</Badge>}
                                            {user.is_active ?
                                                <Badge variant="outline" className="text-green-600 border-green-200 bg-green-50 dark:bg-green-900/20 dark:border-green-800 dark:text-green-400">Active</Badge> :
                                                <Badge variant="destructive">Inactive</Badge>
                                            }
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        <Badge variant="outline" className="font-normal">{user.role || 'User'}</Badge>
                                    </TableCell>
                                    <TableCell className="text-muted-foreground text-sm">
                                        {user.created_at ? format(new Date(user.created_at), 'MMM d, yyyy') : '-'}
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
                                                <DropdownMenuItem onClick={() => router.push(`/dashboard/users/${user.id}`)}>View Details</DropdownMenuItem>
                                                <DropdownMenuItem onClick={() => handleToggleVerify(user.id, !!user.is_verified)}>
                                                    {user.is_verified ? 'Unverify User' : 'Verify User'}
                                                </DropdownMenuItem>
                                                <DropdownMenuItem
                                                    className="text-destructive focus:text-destructive"
                                                    onClick={() => handleToggleStatus(user.id, !!user.is_active)}
                                                >
                                                    {user.is_active ? 'Suspend User' : 'Activate User'}
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
