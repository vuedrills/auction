'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    Store,
    ArrowLeft,
    Save,
    Loader2,
    ShieldAlert,
    Trash2,
    MapPin,
    MessageCircle,
    Phone,
    Info
} from 'lucide-react';
import { toast } from 'sonner';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
    Form,
    FormControl,
    FormField,
    FormItem,
    FormLabel,
    FormMessage,
    FormDescription,
} from '@/components/ui/form';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { shopsService } from '@/services/shops';
import { Switch } from '@/components/ui/switch';
import { ImageUpload } from '@/components/ui/image-upload';

const settingsSchema = z.object({
    store_name: z.string().min(2).max(100),
    tagline: z.string().max(100).optional(),
    about: z.string().optional(),
    whatsapp: z.string().optional(),
    phone: z.string().optional(),
    address: z.string().optional(),
    is_active: z.boolean().default(true),
    logo_url: z.string().optional(),
    cover_url: z.string().optional(),
});

type SettingsFormValues = z.infer<typeof settingsSchema>;

export default function StoreSettingsPage() {
    const router = useRouter();
    const queryClient = useQueryClient();

    const { data: store, isLoading: isLoadingStore } = useQuery({
        queryKey: ['my-store'],
        queryFn: shopsService.getMyShop,
    });

    const form = useForm<SettingsFormValues>({
        resolver: zodResolver(settingsSchema) as any,
        defaultValues: {
            store_name: '',
            tagline: '',
            about: '',
            whatsapp: '',
            phone: '',
            address: '',
            is_active: true,
            logo_url: '',
            cover_url: '',
        },
    });

    useEffect(() => {
        if (store) {
            form.reset({
                store_name: store.store_name,
                tagline: store.tagline || '',
                about: store.about || '',
                whatsapp: store.whatsapp || '',
                phone: store.phone || '',
                address: store.address || '',
                is_active: store.is_active,
                logo_url: store.logo_url || '',
                cover_url: store.cover_url || '',
            });
        }
    }, [store, form]);

    const updateSettingsMutation = useMutation({
        mutationFn: (data: SettingsFormValues) => shopsService.updateShop(data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['my-store'] });
            toast.success('Store settings updated');
            router.push('/profile/stores');
        },
        onError: (error: any) => {
            toast.error(error.response?.data?.error || 'Failed to update settings');
        },
    });

    const onSubmit = (data: SettingsFormValues) => {
        updateSettingsMutation.mutate(data);
    };

    if (isLoadingStore) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <Loader2 className="size-8 animate-spin text-primary" />
            </div>
        );
    }

    return (
        <div className="max-w-4xl mx-auto py-12 px-4">
            <div className="flex items-center gap-4 mb-8">
                <Button variant="ghost" size="icon" className="rounded-full" onClick={() => router.back()}>
                    <ArrowLeft className="size-5" />
                </Button>
                <div>
                    <h1 className="text-3xl font-black">Store Settings</h1>
                    <p className="text-muted-foreground">Manage your shop's public profile and operational status.</p>
                </div>
            </div>

            <Form {...form}>
                <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
                    <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <Info className="size-5 text-primary" />
                                Store Identity
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-6">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-6">
                                <FormField
                                    control={form.control}
                                    name="logo_url"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Store Logo</FormLabel>
                                            <FormControl>
                                                <ImageUpload
                                                    value={field.value ? [field.value] : []}
                                                    onChange={(urls) => field.onChange(urls[0] || '')}
                                                    maxImages={1}
                                                    folder="logos"
                                                />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                                <FormField
                                    control={form.control}
                                    name="cover_url"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Store Banner</FormLabel>
                                            <FormControl>
                                                <ImageUpload
                                                    value={field.value ? [field.value] : []}
                                                    onChange={(urls) => field.onChange(urls[0] || '')}
                                                    maxImages={1}
                                                    folder="banners"
                                                />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                            </div>

                            <FormField
                                control={form.control}
                                name="store_name"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Store Name</FormLabel>
                                        <FormControl>
                                            <Input {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />

                            <FormField
                                control={form.control}
                                name="tagline"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Tagline</FormLabel>
                                        <FormControl>
                                            <Input {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />

                            <FormField
                                control={form.control}
                                name="about"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>About Store</FormLabel>
                                        <FormControl>
                                            <Textarea {...field} className="bg-muted/30 border-none rounded-xl min-h-[150px]" />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                        </CardContent>
                    </Card>

                    <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <Phone className="size-5 text-primary" />
                                Contact Information
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-6">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <FormField
                                    control={form.control}
                                    name="whatsapp"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>WhatsApp Number</FormLabel>
                                            <FormControl>
                                                <Input {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />

                                <FormField
                                    control={form.control}
                                    name="phone"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Store Phone</FormLabel>
                                            <FormControl>
                                                <Input {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                            </div>

                            <FormField
                                control={form.control}
                                name="address"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Business Address</FormLabel>
                                        <FormControl>
                                            <Textarea {...field} className="bg-muted/30 border-none rounded-xl" />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                        </CardContent>
                    </Card>

                    <Card className="rounded-3xl border border-destructive/20 shadow-xl shadow-destructive/5 bg-destructive/5">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2 text-destructive">
                                <ShieldAlert className="size-5" />
                                Danger Zone
                            </CardTitle>
                            <CardDescription>Actions here cannot be undone easily.</CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-6">
                            <FormField
                                control={form.control}
                                name="is_active"
                                render={({ field }) => (
                                    <FormItem className="flex items-center justify-between p-4 bg-background/50 rounded-2xl border">
                                        <div className="space-y-0.5">
                                            <FormLabel className="text-base font-bold">Store Active Status</FormLabel>
                                            <p className="text-sm text-muted-foreground">When inactive, your store and products are hidden from search.</p>
                                        </div>
                                        <FormControl>
                                            <Switch checked={field.value} onCheckedChange={field.onChange} />
                                        </FormControl>
                                    </FormItem>
                                )}
                            />

                            <Button type="button" variant="ghost" className="text-destructive hover:bg-destructive/10 hover:text-destructive w-full justify-start h-12 rounded-xl gap-2 font-bold transition-all">
                                <Trash2 className="size-5" />
                                Delete Store Permanently
                            </Button>
                        </CardContent>
                    </Card>

                    <div className="flex justify-end pt-4">
                        <Button
                            type="submit"
                            className="h-14 rounded-2xl px-12 text-lg font-bold gap-2"
                            disabled={updateSettingsMutation.isPending}
                        >
                            {updateSettingsMutation.isPending ? (
                                <Loader2 className="size-5 animate-spin" />
                            ) : (
                                <Save className="size-5" />
                            )}
                            Save All Settings
                        </Button>
                    </div>
                </form>
            </Form>
        </div>
    );
}
