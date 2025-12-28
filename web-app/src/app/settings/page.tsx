'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import {
    User,
    Bell,
    Shield,
    Palette,
    MapPin,
    LogOut,
    Save,
    Loader2,
    Moon,
    Sun,
    Monitor
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Separator } from '@/components/ui/separator';
import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from '@/components/ui/card';
import {
    Tabs,
    TabsContent,
    TabsList,
    TabsTrigger,
} from '@/components/ui/tabs';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import { useAuthStore } from '@/stores/authStore';
import { useTownStore } from '@/stores/townStore';
import { useUIStore } from '@/stores/uiStore';
import { usersService } from '@/services/users';
import { cn } from '@/lib/utils';

const profileSchema = z.object({
    full_name: z.string().min(2, 'Name must be at least 2 characters'),
    email: z.string().email('Invalid email address'),
});

type ProfileFormData = z.infer<typeof profileSchema>;

export default function SettingsPage() {
    const router = useRouter();
    const { toast } = useToast();
    const queryClient = useQueryClient();
    const { user, logout } = useAuthStore();
    const { selectedTown } = useTownStore();
    const { setTownFilterOpen } = useUIStore();

    const [activeTab, setActiveTab] = useState('profile');

    // Notification preferences state
    const [notifications, setNotifications] = useState({
        email_bids: true,
        email_outbid: true,
        email_won: true,
        email_messages: true,
        push_bids: true,
        push_outbid: true,
        push_won: true,
        push_messages: true,
    });

    // Appearance state
    const [theme, setTheme] = useState<'light' | 'dark' | 'system'>('system');

    const form = useForm<ProfileFormData>({
        resolver: zodResolver(profileSchema),
        defaultValues: {
            full_name: user?.full_name || '',
            email: user?.email || '',
        },
    });

    const updateProfileMutation = useMutation({
        mutationFn: (data: ProfileFormData) => usersService.updateProfile(data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['user'] });
            toast({
                title: 'Profile updated',
                description: 'Your profile has been updated successfully.',
            });
        },
        onError: () => {
            toast({
                title: 'Error',
                description: 'Failed to update profile. Please try again.',
                variant: 'destructive',
            });
        },
    });

    const handleLogout = () => {
        logout();
        router.push('/login');
    };

    if (!user) {
        return (
            <div className="min-h-screen flex items-center justify-center">
                <p className="text-muted-foreground">Please log in to access settings.</p>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-background">
            {/* Header */}
            <div className="border-b bg-card">
                <div className="max-w-4xl mx-auto px-4 py-6">
                    <h1 className="text-2xl font-bold">Settings</h1>
                    <p className="text-muted-foreground mt-1">
                        Manage your account settings and preferences
                    </p>
                </div>
            </div>

            <div className="max-w-4xl mx-auto px-4 py-8">
                <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
                    <TabsList className="grid w-full grid-cols-4 lg:w-[400px]">
                        <TabsTrigger value="profile" className="gap-2">
                            <User className="size-4 hidden sm:inline" />
                            Profile
                        </TabsTrigger>
                        <TabsTrigger value="notifications" className="gap-2">
                            <Bell className="size-4 hidden sm:inline" />
                            Alerts
                        </TabsTrigger>
                        <TabsTrigger value="appearance" className="gap-2">
                            <Palette className="size-4 hidden sm:inline" />
                            Theme
                        </TabsTrigger>
                        <TabsTrigger value="security" className="gap-2">
                            <Shield className="size-4 hidden sm:inline" />
                            Security
                        </TabsTrigger>
                    </TabsList>

                    {/* Profile Tab */}
                    <TabsContent value="profile" className="space-y-6">
                        <Card>
                            <CardHeader>
                                <CardTitle>Profile Information</CardTitle>
                                <CardDescription>
                                    Update your personal information
                                </CardDescription>
                            </CardHeader>
                            <CardContent>
                                <form
                                    onSubmit={form.handleSubmit((data) => updateProfileMutation.mutate(data))}
                                    className="space-y-4"
                                >
                                    <div className="space-y-2">
                                        <Label htmlFor="full_name">Full Name</Label>
                                        <Input
                                            id="full_name"
                                            {...form.register('full_name')}
                                            placeholder="Your full name"
                                        />
                                        {form.formState.errors.full_name && (
                                            <p className="text-sm text-destructive">
                                                {form.formState.errors.full_name.message}
                                            </p>
                                        )}
                                    </div>

                                    <div className="space-y-2">
                                        <Label htmlFor="email">Email</Label>
                                        <Input
                                            id="email"
                                            type="email"
                                            {...form.register('email')}
                                            placeholder="your@email.com"
                                        />
                                        {form.formState.errors.email && (
                                            <p className="text-sm text-destructive">
                                                {form.formState.errors.email.message}
                                            </p>
                                        )}
                                    </div>

                                    <Button
                                        type="submit"
                                        disabled={updateProfileMutation.isPending}
                                    >
                                        {updateProfileMutation.isPending ? (
                                            <Loader2 className="size-4 mr-2 animate-spin" />
                                        ) : (
                                            <Save className="size-4 mr-2" />
                                        )}
                                        Save Changes
                                    </Button>
                                </form>
                            </CardContent>
                        </Card>

                        <Card>
                            <CardHeader>
                                <CardTitle>Default Location</CardTitle>
                                <CardDescription>
                                    Your preferred location for browsing auctions
                                </CardDescription>
                            </CardHeader>
                            <CardContent>
                                <Button
                                    variant="outline"
                                    className="w-full justify-between max-w-sm"
                                    onClick={() => setTownFilterOpen(true)}
                                >
                                    <div className="flex items-center gap-2">
                                        <MapPin className="size-4 text-primary" />
                                        {selectedTown?.name || 'Select your town'}
                                    </div>
                                </Button>
                            </CardContent>
                        </Card>
                    </TabsContent>

                    {/* Notifications Tab */}
                    <TabsContent value="notifications" className="space-y-6">
                        <Card>
                            <CardHeader>
                                <CardTitle>Email Notifications</CardTitle>
                                <CardDescription>
                                    Choose what emails you want to receive
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <p className="font-medium">New Bids</p>
                                        <p className="text-sm text-muted-foreground">
                                            Get notified when someone bids on your auctions
                                        </p>
                                    </div>
                                    <Switch
                                        checked={notifications.email_bids}
                                        onCheckedChange={(checked: boolean) =>
                                            setNotifications({ ...notifications, email_bids: checked })
                                        }
                                    />
                                </div>
                                <Separator />
                                <div className="flex items-center justify-between">
                                    <div>
                                        <p className="font-medium">Outbid Alerts</p>
                                        <p className="text-sm text-muted-foreground">
                                            Get notified when you&apos;ve been outbid
                                        </p>
                                    </div>
                                    <Switch
                                        checked={notifications.email_outbid}
                                        onCheckedChange={(checked: boolean) =>
                                            setNotifications({ ...notifications, email_outbid: checked })
                                        }
                                    />
                                </div>
                                <Separator />
                                <div className="flex items-center justify-between">
                                    <div>
                                        <p className="font-medium">Auction Won</p>
                                        <p className="text-sm text-muted-foreground">
                                            Get notified when you win an auction
                                        </p>
                                    </div>
                                    <Switch
                                        checked={notifications.email_won}
                                        onCheckedChange={(checked: boolean) =>
                                            setNotifications({ ...notifications, email_won: checked })
                                        }
                                    />
                                </div>
                                <Separator />
                                <div className="flex items-center justify-between">
                                    <div>
                                        <p className="font-medium">Messages</p>
                                        <p className="text-sm text-muted-foreground">
                                            Get notified when you receive new messages
                                        </p>
                                    </div>
                                    <Switch
                                        checked={notifications.email_messages}
                                        onCheckedChange={(checked: boolean) =>
                                            setNotifications({ ...notifications, email_messages: checked })
                                        }
                                    />
                                </div>
                            </CardContent>
                        </Card>

                        <Card>
                            <CardHeader>
                                <CardTitle>Push Notifications</CardTitle>
                                <CardDescription>
                                    Real-time notifications in your browser
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <p className="font-medium">New Bids</p>
                                        <p className="text-sm text-muted-foreground">
                                            Real-time bid notifications
                                        </p>
                                    </div>
                                    <Switch
                                        checked={notifications.push_bids}
                                        onCheckedChange={(checked: boolean) =>
                                            setNotifications({ ...notifications, push_bids: checked })
                                        }
                                    />
                                </div>
                                <Separator />
                                <div className="flex items-center justify-between">
                                    <div>
                                        <p className="font-medium">Outbid Alerts</p>
                                        <p className="text-sm text-muted-foreground">
                                            Instant outbid notifications
                                        </p>
                                    </div>
                                    <Switch
                                        checked={notifications.push_outbid}
                                        onCheckedChange={(checked: boolean) =>
                                            setNotifications({ ...notifications, push_outbid: checked })
                                        }
                                    />
                                </div>
                            </CardContent>
                        </Card>
                    </TabsContent>

                    {/* Appearance Tab */}
                    <TabsContent value="appearance" className="space-y-6">
                        <Card>
                            <CardHeader>
                                <CardTitle>Theme</CardTitle>
                                <CardDescription>
                                    Choose your preferred color scheme
                                </CardDescription>
                            </CardHeader>
                            <CardContent>
                                <div className="grid grid-cols-3 gap-4">
                                    <Button
                                        variant={theme === 'light' ? 'default' : 'outline'}
                                        className="h-auto py-4 flex flex-col gap-2"
                                        onClick={() => setTheme('light')}
                                    >
                                        <Sun className="size-5" />
                                        Light
                                    </Button>
                                    <Button
                                        variant={theme === 'dark' ? 'default' : 'outline'}
                                        className="h-auto py-4 flex flex-col gap-2"
                                        onClick={() => setTheme('dark')}
                                    >
                                        <Moon className="size-5" />
                                        Dark
                                    </Button>
                                    <Button
                                        variant={theme === 'system' ? 'default' : 'outline'}
                                        className="h-auto py-4 flex flex-col gap-2"
                                        onClick={() => setTheme('system')}
                                    >
                                        <Monitor className="size-5" />
                                        System
                                    </Button>
                                </div>
                            </CardContent>
                        </Card>
                    </TabsContent>

                    {/* Security Tab */}
                    <TabsContent value="security" className="space-y-6">
                        <Card>
                            <CardHeader>
                                <CardTitle>Change Password</CardTitle>
                                <CardDescription>
                                    Update your password regularly for security
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                <div className="space-y-2">
                                    <Label htmlFor="current_password">Current Password</Label>
                                    <Input
                                        id="current_password"
                                        type="password"
                                        placeholder="••••••••"
                                    />
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="new_password">New Password</Label>
                                    <Input
                                        id="new_password"
                                        type="password"
                                        placeholder="••••••••"
                                    />
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="confirm_password">Confirm New Password</Label>
                                    <Input
                                        id="confirm_password"
                                        type="password"
                                        placeholder="••••••••"
                                    />
                                </div>
                                <Button>Update Password</Button>
                            </CardContent>
                        </Card>

                        <Card className="border-destructive/30">
                            <CardHeader>
                                <CardTitle className="text-destructive">Danger Zone</CardTitle>
                                <CardDescription>
                                    Irreversible account actions
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <p className="font-medium">Sign Out</p>
                                        <p className="text-sm text-muted-foreground">
                                            Sign out from this device
                                        </p>
                                    </div>
                                    <Button variant="outline" onClick={handleLogout}>
                                        <LogOut className="size-4 mr-2" />
                                        Sign Out
                                    </Button>
                                </div>
                            </CardContent>
                        </Card>
                    </TabsContent>
                </Tabs>
            </div>
        </div>
    );
}
