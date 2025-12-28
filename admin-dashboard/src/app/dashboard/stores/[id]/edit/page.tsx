'use client';

import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminGetStore, adminUpdateStore } from '@/features/stores/storeService';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Loader2, ArrowLeft, Save } from 'lucide-react';
import { useState, useEffect } from 'react';
import { Textarea } from '@/components/ui/textarea';

export default function StoreEditPage() {
    const { id } = useParams();
    const router = useRouter();
    const queryClient = useQueryClient();

    const { data: store, isLoading } = useQuery({
        queryKey: ['admin-store', id],
        queryFn: () => adminGetStore(id as string),
        enabled: !!id,
    });

    const [formData, setFormData] = useState({
        store_name: '',
        tagline: '',
        about: '',
        whatsapp: '',
        phone: '',
    });

    useEffect(() => {
        if (store) {
            setFormData({
                store_name: store.store_name || '',
                tagline: store.tagline || '',
                about: store.about || '',
                whatsapp: store.whatsapp || '',
                phone: store.phone || '',
            });
        }
    }, [store]);

    const mutation = useMutation({
        mutationFn: (data: any) => adminUpdateStore(id as string, data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['admin-store', id] });
            queryClient.invalidateQueries({ queryKey: ['stores'] });
            alert('Store updated successfully!');
            router.push(`/dashboard/stores/${id}`);
        },
        onError: (err: any) => {
            alert('Error: ' + (err.response?.data?.error || err.message));
        }
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        mutation.mutate(formData);
    };

    if (isLoading) {
        return <div className="flex justify-center p-12"><Loader2 className="animate-spin h-8 w-8" /></div>;
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center gap-4">
                <Button variant="ghost" size="icon" onClick={() => router.back()}>
                    <ArrowLeft className="h-4 w-4" />
                </Button>
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Edit Store</h1>
                    <p className="text-muted-foreground">{store?.store_name}</p>
                </div>
            </div>

            <form onSubmit={handleSubmit}>
                <Card>
                    <CardHeader>
                        <CardTitle>Store Details</CardTitle>
                        <CardDescription>Update the store's basic information.</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2 col-span-2">
                                <label className="text-sm font-medium">Store Name</label>
                                <Input
                                    value={formData.store_name}
                                    onChange={e => setFormData({ ...formData, store_name: e.target.value })}
                                    required
                                />
                            </div>
                            <div className="space-y-2 col-span-2">
                                <label className="text-sm font-medium">Tagline</label>
                                <Input
                                    value={formData.tagline}
                                    onChange={e => setFormData({ ...formData, tagline: e.target.value })}
                                    placeholder="A short description of the store"
                                />
                            </div>
                            <div className="space-y-2 col-span-2">
                                <label className="text-sm font-medium">About</label>
                                <Textarea
                                    value={formData.about}
                                    onChange={e => setFormData({ ...formData, about: e.target.value })}
                                    rows={3}
                                    placeholder="Full description about the store"
                                />
                            </div>
                            <div className="space-y-2">
                                <label className="text-sm font-medium">Phone</label>
                                <Input
                                    value={formData.phone}
                                    onChange={e => setFormData({ ...formData, phone: e.target.value })}
                                />
                            </div>
                            <div className="space-y-2">
                                <label className="text-sm font-medium">WhatsApp Number</label>
                                <Input
                                    value={formData.whatsapp}
                                    onChange={e => setFormData({ ...formData, whatsapp: e.target.value })}
                                />
                            </div>
                        </div>
                        <div className="flex justify-end pt-4">
                            <Button type="submit" disabled={mutation.isPending}>
                                {mutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                <Save className="mr-2 h-4 w-4" />
                                Save Changes
                            </Button>
                        </div>
                    </CardContent>
                </Card>
            </form>
        </div>
    );
}
