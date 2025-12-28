'use client';

import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getAdminUserDetails, updateUserStatus, verifyUser } from '@/features/admin/adminService';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Loader2, ArrowLeft, User, Mail, Phone, Calendar, ShieldCheck, Gavel, Award, Activity } from 'lucide-react';
import { format } from 'date-fns';

export default function UserDetailsPage() {
    const params = useParams();
    const router = useRouter();
    const queryClient = useQueryClient();
    const id = params.id as string;

    const { data, isLoading, isError } = useQuery({
        queryKey: ['user-details', id],
        queryFn: () => getAdminUserDetails(id),
    });

    const statusMutation = useMutation({
        mutationFn: ({ isActive }: { isActive: boolean }) => updateUserStatus(id, isActive),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['user-details', id] });
            alert('Status updated successfully');
        },
    });

    const verifyMutation = useMutation({
        mutationFn: ({ isVerified }: { isVerified: boolean }) => verifyUser(id, isVerified),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['user-details', id] });
            alert('Verification updated successfully');
        },
    });

    if (isLoading) return <div className="flex justify-center p-12"><Loader2 className="animate-spin h-8 w-8 text-primary" /></div>;
    if (isError) return <div className="p-8 text-destructive">Error loading user details.</div>;

    const { user, total_auctions, total_bids, total_wins } = data;

    return (
        <div className="space-y-6">
            <div className="flex items-center gap-4">
                <Button variant="outline" size="icon" onClick={() => router.back()}>
                    <ArrowLeft className="h-4 w-4" />
                </Button>
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">{user.username}</h1>
                    <p className="text-muted-foreground text-sm font-mono">{user.id}</p>
                </div>
            </div>

            <div className="grid gap-6 md:grid-cols-4">
                {/* Profile Card */}
                <Card className="md:col-span-1">
                    <CardHeader className="text-center">
                        <div className="mx-auto h-24 w-24 rounded-full bg-primary/10 flex items-center justify-center border-2 border-primary/20 overflow-hidden mb-4">
                            {user.avatar_url ? (
                                <img src={user.avatar_url} className="h-full w-full object-cover" />
                            ) : (
                                <User className="h-12 w-12 text-primary/40" />
                            )}
                        </div>
                        <CardTitle>{user.full_name || user.username}</CardTitle>
                        <CardDescription>{user.email}</CardDescription>
                        <div className="flex justify-center gap-2 mt-4">
                            {user.is_verified ? (
                                <Badge className="bg-blue-100 text-blue-800 border-blue-200">VERIFIED</Badge>
                            ) : (
                                <Badge variant="outline">UNVERIFIED</Badge>
                            )}
                            {user.is_active ? (
                                <Badge className="bg-green-100 text-green-800 border-green-200">ACTIVE</Badge>
                            ) : (
                                <Badge variant="destructive">SUSPENDED</Badge>
                            )}
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-4 pt-4 border-t">
                        <div className="flex items-center gap-2 text-sm">
                            <Mail className="h-4 w-4 text-muted-foreground" />
                            <span className="truncate">{user.email}</span>
                        </div>
                        <div className="flex items-center gap-2 text-sm">
                            <Phone className="h-4 w-4 text-muted-foreground" />
                            <span>{user.phone || 'No phone added'}</span>
                        </div>
                        <div className="flex items-center gap-2 text-sm">
                            <Calendar className="h-4 w-4 text-muted-foreground" />
                            <span>Joined {format(new Date(user.created_at), 'PPP')}</span>
                        </div>
                    </CardContent>
                </Card>

                {/* Stats & Actions */}
                <div className="md:col-span-3 space-y-6">
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                        <Card className="bg-primary/5 border-primary/10">
                            <CardHeader className="pb-2">
                                <CardDescription className="text-xs uppercase font-bold text-primary/60">Total Auctions</CardDescription>
                                <CardTitle className="text-3xl flex items-center justify-between">
                                    {total_auctions}
                                    <Activity className="h-5 w-5 text-primary/40" />
                                </CardTitle>
                            </CardHeader>
                        </Card>
                        <Card className="bg-orange-500/5 border-orange-500/10">
                            <CardHeader className="pb-2">
                                <CardDescription className="text-xs uppercase font-bold text-orange-600/60">Active Bids</CardDescription>
                                <CardTitle className="text-3xl flex items-center justify-between">
                                    {total_bids}
                                    <Gavel className="h-5 w-5 text-orange-500/40" />
                                </CardTitle>
                            </CardHeader>
                        </Card>
                        <Card className="bg-green-500/5 border-green-500/10">
                            <CardHeader className="pb-2">
                                <CardDescription className="text-xs uppercase font-bold text-green-600/60">Auctions Won</CardDescription>
                                <CardTitle className="text-3xl flex items-center justify-between">
                                    {total_wins}
                                    <Award className="h-5 w-5 text-green-500/40" />
                                </CardTitle>
                            </CardHeader>
                        </Card>
                    </div>

                    <Card>
                        <CardHeader>
                            <CardTitle>Management Actions</CardTitle>
                            <CardDescription>Administrative controls for this user account</CardDescription>
                        </CardHeader>
                        <CardContent className="flex flex-wrap gap-4">
                            {user.is_verified ? (
                                <Button variant="outline" onClick={() => verifyMutation.mutate({ isVerified: false })}>
                                    Remove Verification
                                </Button>
                            ) : (
                                <Button variant="default" className="bg-blue-600 hover:bg-blue-700" onClick={() => verifyMutation.mutate({ isVerified: true })}>
                                    <ShieldCheck className="mr-2 h-4 w-4" /> Verify User
                                </Button>
                            )}

                            {user.is_active ? (
                                <Button variant="destructive" onClick={() => {
                                    if (confirm('Are you sure you want to suspend this user?')) {
                                        statusMutation.mutate({ isActive: false });
                                    }
                                }}>
                                    Suspend Account
                                </Button>
                            ) : (
                                <Button variant="default" className="bg-green-600 hover:bg-green-700" onClick={() => statusMutation.mutate({ isActive: true })}>
                                    Activate Account
                                </Button>
                            )}

                            <Button variant="secondary" onClick={() => alert('Password reset link sent to registered email (Mock)')}>
                                Send Password Reset
                            </Button>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader>
                            <CardTitle>Recent Activity</CardTitle>
                            <CardDescription>Audit log and activity overview</CardDescription>
                        </CardHeader>
                        <CardContent>
                            <div className="text-sm text-muted-foreground italic">
                                Activity logs feature coming soon...
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    );
}
