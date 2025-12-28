'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getAdminNotifications, sendAdminNotification, searchUsers } from '@/features/admin/adminService';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Loader2, Bell, Send, Users, Search, X, CheckCircle } from 'lucide-react';
import { format } from 'date-fns';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { TownFilter } from '@/components/filters/TownFilter';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";

export default function NotificationsPage() {
    const queryClient = useQueryClient();
    const [title, setTitle] = useState('');
    const [body, setBody] = useState('');
    const [category, setCategory] = useState('everyone');
    const [userSearch, setUserSearch] = useState('');
    const [selectedUsers, setSelectedUsers] = useState<any[]>([]);
    const [selectedTown, setSelectedTown] = useState<string | null>(null);
    const [selectedSuburb, setSelectedSuburb] = useState<string | null>(null);

    const { data: recentNotifications, isLoading: loadingRecent } = useQuery({
        queryKey: ['admin-notifications'],
        queryFn: getAdminNotifications,
    });

    const { data: userData, isLoading: searchingUsers } = useQuery({
        queryKey: ['user-search', userSearch],
        queryFn: () => searchUsers(userSearch),
        enabled: userSearch.length > 2,
    });

    const mutation = useMutation({
        mutationFn: sendAdminNotification,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['admin-notifications'] });
            setTitle('');
            setBody('');
            setSelectedUsers([]);
            alert('Notifications sent successfully!');
        },
    });

    const handleSend = () => {
        if (!title || !body) return;
        mutation.mutate({
            title,
            body,
            category: selectedUsers.length > 0 ? undefined : category,
            user_ids: selectedUsers.map(u => u.id),
            town_id: selectedTown || undefined,
            suburb_id: selectedSuburb || undefined,
        });
    };

    const toggleUser = (user: any) => {
        if (selectedUsers.find(u => u.id === user.id)) {
            setSelectedUsers(selectedUsers.filter(u => u.id !== user.id));
        } else {
            setSelectedUsers([...selectedUsers, user]);
        }
    };

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">System Notifications</h1>
                <p className="text-muted-foreground">Broadcast messages and manage user alerts.</p>
            </div>

            <Tabs defaultValue="broadcast" className="space-y-4">
                <TabsList>
                    <TabsTrigger value="broadcast">Send Notification</TabsTrigger>
                    <TabsTrigger value="history">History</TabsTrigger>
                </TabsList>

                <TabsContent value="broadcast" className="space-y-4">
                    <div className="grid gap-6 md:grid-cols-2">
                        {/* Send Form */}
                        <Card>
                            <CardHeader>
                                <CardTitle>Compose Message</CardTitle>
                                <CardDescription>Create a new system-wide or targeted notification.</CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                <div className="space-y-4">
                                    <div className="space-y-2">
                                        <label className="text-sm font-medium">Target Audience</label>
                                        <Select
                                            disabled={selectedUsers.length > 0}
                                            value={category}
                                            onValueChange={setCategory}
                                        >
                                            <SelectTrigger>
                                                <SelectValue placeholder="Select group" />
                                            </SelectTrigger>
                                            <SelectContent>
                                                <SelectItem value="everyone">Everyone</SelectItem>
                                                <SelectItem value="store_owners">Store Owners</SelectItem>
                                                <SelectItem value="verified_users">Verified Users</SelectItem>
                                                <SelectItem value="by_town">Users by Town/Suburb</SelectItem>
                                            </SelectContent>
                                        </Select>
                                    </div>

                                    {(category === 'everyone' || category === 'store_owners' || category === 'verified_users' || category === 'by_town') && (
                                        <div className="space-y-2">
                                            <label className="text-sm font-medium">Filter by Region (Optional)</label>
                                            <TownFilter
                                                selectedTown={selectedTown}
                                                selectedSuburb={selectedSuburb}
                                                onTownChange={setSelectedTown}
                                                onSuburbChange={setSelectedSuburb}
                                                className="w-full justify-start"
                                            />
                                            <p className="text-[10px] text-muted-foreground">
                                                Leave blank to target all regions.
                                            </p>
                                        </div>
                                    )}

                                    {selectedUsers.length > 0 && (
                                        <p className="text-[10px] text-orange-600 font-medium">
                                            Region filters are ignored because specific users are selected.
                                        </p>
                                    )}
                                </div>

                                <div className="space-y-2">
                                    <label className="text-sm font-medium">Title</label>
                                    <Input placeholder="Notification Heading" value={title} onChange={(e) => setTitle(e.target.value)} />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-sm font-medium">Message Body</label>
                                    <Textarea
                                        placeholder="Detailed message content..."
                                        rows={4}
                                        value={body}
                                        onChange={(e) => setBody(e.target.value)}
                                    />
                                </div>
                                <Button
                                    className="w-full"
                                    disabled={mutation.isPending || !title || !body}
                                    onClick={handleSend}
                                >
                                    {mutation.isPending ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Send className="mr-2 h-4 w-4" />}
                                    Send Notification
                                </Button>
                            </CardContent>
                        </Card>

                        {/* User Targeting */}
                        <Card>
                            <CardHeader>
                                <CardTitle>Specific User Targeting</CardTitle>
                                <CardDescription>Search and select specific users to notify.</CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                <div className="relative">
                                    <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                                    <Input
                                        placeholder="Search by username or email..."
                                        className="pl-8"
                                        value={userSearch}
                                        onChange={(e) => setUserSearch(e.target.value)}
                                    />
                                </div>

                                {/* Selected Users Tags */}
                                {selectedUsers.length > 0 && (
                                    <div className="flex flex-wrap gap-2 p-2 border rounded-md min-h-[40px] bg-muted/20">
                                        {selectedUsers.map(u => (
                                            <Badge key={u.id} className="gap-1 bg-primary/20 text-primary border-primary/20 hover:bg-primary/30">
                                                {u.username}
                                                <X className="h-3 w-3 cursor-pointer" onClick={() => toggleUser(u)} />
                                            </Badge>
                                        ))}
                                    </div>
                                )}

                                {/* Search Results */}
                                <div className="space-y-2 max-h-[250px] overflow-y-auto pr-2">
                                    {searchingUsers ? (
                                        <div className="flex justify-center p-4"><Loader2 className="animate-spin h-4 w-4" /></div>
                                    ) : (
                                        userData?.users?.map((u: any) => (
                                            <div
                                                key={u.id}
                                                onClick={() => toggleUser(u)}
                                                className={cn(
                                                    "flex items-center justify-between p-2 rounded-md border cursor-pointer transition-colors",
                                                    selectedUsers.find(s => s.id === u.id) ? "bg-primary/10 border-primary/20" : "hover:bg-muted/50"
                                                )}
                                            >
                                                <div className="flex items-center gap-2">
                                                    <div className="h-8 w-8 rounded-full bg-muted flex items-center justify-center text-xs font-bold">
                                                        {u.username[0].toUpperCase()}
                                                    </div>
                                                    <div>
                                                        <p className="text-xs font-bold">{u.username}</p>
                                                        <p className="text-[10px] text-muted-foreground">{u.email}</p>
                                                    </div>
                                                </div>
                                                {selectedUsers.find(s => s.id === u.id) && <CheckCircle className="h-4 w-4 text-primary" />}
                                            </div>
                                        ))
                                    )}
                                    {userSearch.length > 2 && userData?.users?.length === 0 && (
                                        <p className="text-center text-xs text-muted-foreground py-4">No users found</p>
                                    )}
                                </div>
                            </CardContent>
                        </Card>
                    </div>
                </TabsContent>

                <TabsContent value="history">
                    <Card>
                        <CardHeader>
                            <CardTitle>Broadcast History</CardTitle>
                            <CardDescription>Review recently sent system notifications.</CardDescription>
                        </CardHeader>
                        <CardContent>
                            <div className="rounded-md border">
                                <Table>
                                    <TableHeader>
                                        <TableRow>
                                            <TableHead>Type</TableHead>
                                            <TableHead>Recipient</TableHead>
                                            <TableHead>Notification</TableHead>
                                            <TableHead>Date</TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {loadingRecent ? (
                                            <TableRow><TableCell colSpan={4} className="text-center py-10"><Loader2 className="animate-spin mx-auto h-6 w-6" /></TableCell></TableRow>
                                        ) : recentNotifications?.notifications?.length === 0 ? (
                                            <TableRow><TableCell colSpan={4} className="text-center py-10 text-muted-foreground">No history found</TableCell></TableRow>
                                        ) : (
                                            recentNotifications?.notifications?.map((n: any) => (
                                                <TableRow key={n.id}>
                                                    <TableCell>
                                                        <Badge variant="outline" className="text-[10px] uppercase">{n.type.replace('_', ' ')}</Badge>
                                                    </TableCell>
                                                    <TableCell className="font-mono text-[10px]">{n.username || 'Everyone'}</TableCell>
                                                    <TableCell>
                                                        <p className="text-sm font-bold">{n.title}</p>
                                                        <p className="text-xs text-muted-foreground truncate max-w-xs">{n.body}</p>
                                                    </TableCell>
                                                    <TableCell className="text-xs text-muted-foreground">
                                                        {format(new Date(n.created_at), 'MMM d, h:mm a')}
                                                    </TableCell>
                                                </TableRow>
                                            ))
                                        )}
                                    </TableBody>
                                </Table>
                            </div>
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    );
}

import { cn } from '@/lib/utils';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
