'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getAdmins, addAdmin, removeAdmin, searchUsers } from '@/features/admin/adminService';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Loader2, Plus, Trash2, Shield, Search, User, CheckCircle } from 'lucide-react';
import { format } from 'date-fns';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import { cn } from '@/lib/utils';

export function AdminUserTable() {
    const queryClient = useQueryClient();
    const [searchTerm, setSearchTerm] = useState('');
    const [userSearch, setUserSearch] = useState('');

    const { data: adminData, isLoading } = useQuery({
        queryKey: ['admin-list'],
        queryFn: getAdmins,
    });

    const { data: userData, isLoading: searchingUsers } = useQuery({
        queryKey: ['user-search-admin', userSearch],
        queryFn: () => searchUsers(userSearch),
        enabled: userSearch.length > 2,
    });

    const addMutation = useMutation({
        mutationFn: addAdmin,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['admin-list'] });
            setUserSearch('');
            alert('User elevated to admin successfully');
        },
    });

    const removeMutation = useMutation({
        mutationFn: removeAdmin,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['admin-list'] });
            alert('Admin rights removed');
        },
    });

    const handleAddAdmin = (userId: string) => {
        if (confirm('Are you sure you want to give this user admin rights?')) {
            addMutation.mutate(userId);
        }
    };

    const handleRemoveAdmin = (id: string) => {
        if (confirm('Are you sure you want to remove admin rights for this user?')) {
            removeMutation.mutate(id);
        }
    };

    const admins = adminData?.admins || [];

    return (
        <div className="space-y-6">
            <div className="grid gap-6 md:grid-cols-3">
                {/* List of Admins */}
                <Card className="md:col-span-2">
                    <CardHeader>
                        <CardTitle>System Administrators</CardTitle>
                        <CardDescription>Users with full access to the admin dashboard.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="rounded-md border">
                            <Table>
                                <TableHeader>
                                    <TableRow>
                                        <TableHead>User</TableHead>
                                        <TableHead>Status</TableHead>
                                        <TableHead>Joined</TableHead>
                                        <TableHead className="text-right">Actions</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {isLoading ? (
                                        <TableRow><TableCell colSpan={4} className="text-center py-10"><Loader2 className="animate-spin h-6 w-6 mx-auto" /></TableCell></TableRow>
                                    ) : admins.length === 0 ? (
                                        <TableRow><TableCell colSpan={4} className="text-center py-10 text-muted-foreground">No admins found</TableCell></TableRow>
                                    ) : (
                                        admins.map((admin: any) => (
                                            <TableRow key={admin.id}>
                                                <TableCell>
                                                    <div className="flex items-center gap-2">
                                                        <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center text-[10px] font-bold text-primary">
                                                            {admin.username[0].toUpperCase()}
                                                        </div>
                                                        <div>
                                                            <p className="text-sm font-medium leading-none">{admin.username}</p>
                                                            <p className="text-[10px] text-muted-foreground mt-1">{admin.email}</p>
                                                        </div>
                                                    </div>
                                                </TableCell>
                                                <TableCell>
                                                    {admin.is_active ? (
                                                        <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">Active</Badge>
                                                    ) : (
                                                        <Badge variant="outline" className="bg-red-50 text-red-700 border-red-200">Suspended</Badge>
                                                    )}
                                                </TableCell>
                                                <TableCell className="text-xs text-muted-foreground">
                                                    {format(new Date(admin.created_at), 'MMM d, yyyy')}
                                                </TableCell>
                                                <TableCell className="text-right">
                                                    <Button variant="ghost" size="icon" className="text-destructive h-8 w-8" onClick={() => handleRemoveAdmin(admin.id)}>
                                                        <Trash2 className="h-4 w-4" />
                                                    </Button>
                                                </TableCell>
                                            </TableRow>
                                        ))
                                    )}
                                </TableBody>
                            </Table>
                        </div>
                    </CardContent>
                </Card>

                {/* Add New Admin */}
                <Card>
                    <CardHeader>
                        <CardTitle>Add Administrator</CardTitle>
                        <CardDescription>Search for an existing user to elevate.</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="relative">
                            <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                placeholder="Search by username..."
                                className="pl-8"
                                value={userSearch}
                                onChange={(e) => setUserSearch(e.target.value)}
                            />
                        </div>

                        <div className="space-y-2 max-h-[300px] overflow-y-auto pr-2">
                            {searchingUsers ? (
                                <div className="flex justify-center p-4"><Loader2 className="animate-spin h-4 w-4 text-muted-foreground" /></div>
                            ) : (
                                userData?.users?.filter((u: any) => !admins.some((a: any) => a.id === u.id)).map((u: any) => (
                                    <div
                                        key={u.id}
                                        className="flex items-center justify-between p-2 rounded-md border hover:bg-muted/50 transition-colors"
                                    >
                                        <div className="flex items-center gap-2">
                                            <div className="h-8 w-8 rounded-full bg-muted flex items-center justify-center text-xs font-bold">
                                                {u.username[0].toUpperCase()}
                                            </div>
                                            <div>
                                                <p className="text-xs font-bold">{u.username}</p>
                                                <p className="text-[10px] text-muted-foreground truncate max-w-[100px]">{u.email}</p>
                                            </div>
                                        </div>
                                        <Button
                                            size="sm"
                                            variant="ghost"
                                            className="h-7 px-2 text-primary hover:text-primary hover:bg-primary/10"
                                            onClick={() => handleAddAdmin(u.id)}
                                            disabled={addMutation.isPending}
                                        >
                                            <Shield className="h-3.5 w-3.5 mr-1" />
                                            Add
                                        </Button>
                                    </div>
                                ))
                            )}
                            {userSearch.length > 2 && userData?.users?.filter((u: any) => !admins.some((a: any) => a.id === u.id)).length === 0 && (
                                <p className="text-center text-xs text-muted-foreground py-4">No eligible users found</p>
                            )}
                            {userSearch.length <= 2 && (
                                <p className="text-center text-[10px] text-muted-foreground py-10 opacity-50">
                                    Type 3+ characters to search...
                                </p>
                            )}
                        </div>
                    </CardContent>
                </Card>
            </div>
        </div>
    );
}
