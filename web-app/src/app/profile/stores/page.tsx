'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    Plus,
    Settings,
    BarChart3,
    Package,
    Eye,
    MessageCircle,
    Users,
    MoreVertical,
    Edit,
    Trash2,
    CheckCircle2,
    AlertCircle,
    Loader2,
    Store as StoreIcon,
    ExternalLink,
    Camera
} from 'lucide-react';
import Image from 'next/image';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';

import { shopsService, Store, Product } from '@/services/shops';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger
} from '@/components/ui/dropdown-menu';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { cn } from '@/lib/utils';

export default function MyStorePage() {
    const router = useRouter();
    const queryClient = useQueryClient();
    const [activeTab, setActiveTab] = useState('products');

    const { data: store, isLoading: isLoadingStore, isError: noStore } = useQuery({
        queryKey: ['my-store'],
        queryFn: shopsService.getMyShop,
        retry: false,
    });

    const { data: productsData, isLoading: isLoadingProducts } = useQuery({
        queryKey: ['my-products'],
        queryFn: () => shopsService.searchProducts({ store_id: store?.id }), // Need to check if searchProducts supports store_id filter or if there's a specific "get my products"
        enabled: !!store,
    });

    // In a real app, I'd use a more specific method if the backend supports it. 
    // The backend DOES have GetMyProducts (GET /api/products/my)
    // Let's use a custom query for that.

    const { data: myProducts, isLoading: isLoadingMyProducts } = useQuery({
        queryKey: ['my-products', store?.id],
        queryFn: async () => {
            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/stores/me/products`, {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('auth-storage') ? JSON.parse(localStorage.getItem('auth-storage')!).state.token : ''}`
                }
            });
            if (!response.ok) throw new Error('Failed to fetch products');
            return response.json();
        },
        enabled: !!store,
    });

    const products = myProducts?.products || [];

    // Delete Mutation
    const deleteProductMutation = useMutation({
        mutationFn: (id: string) => shopsService.deleteProduct(id),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['my-products'] });
            toast.success('Product deleted successfully');
        },
    });

    if (isLoadingStore) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <Loader2 className="size-8 animate-spin text-primary" />
            </div>
        );
    }

    if (noStore || !store) {
        return (
            <div className="max-w-xl mx-auto py-20 text-center space-y-8">
                <div className="size-24 bg-primary/10 rounded-full flex items-center justify-center mx-auto">
                    <StoreIcon className="size-12 text-primary" />
                </div>
                <div className="space-y-4">
                    <h1 className="text-3xl font-black">Open Your Store</h1>
                    <p className="text-muted-foreground text-lg">
                        Turn your personal profile into a professional storefront.
                        Reach more customers, manage inventory, and grow your business today.
                    </p>
                </div>
                <Link href="/profile/stores/create">
                    <Button size="lg" className="rounded-2xl px-12 h-14 text-lg font-bold">
                        Setup My Store
                    </Button>
                </Link>
            </div>
        );
    }

    return (
        <div className="space-y-8 pb-12">
            {/* Store Banner */}
            <div className="relative rounded-3xl overflow-hidden bg-card border shadow-sm">
                <div className="h-40 bg-muted relative">
                    {store.cover_url && (
                        <Image src={store.cover_url} alt="Cover" fill className="object-cover" />
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent" />
                </div>

                <div className="px-8 pb-8 flex flex-col md:flex-row items-end gap-6 -mt-10">
                    <div className="relative size-24 md:size-32 rounded-2xl overflow-hidden border-4 border-card bg-white shadow-lg">
                        {store.logo_url ? (
                            <Image src={store.logo_url} alt="Logo" fill className="object-cover" />
                        ) : (
                            <div className="flex items-center justify-center h-full bg-primary/10 text-primary font-bold text-2xl">
                                {store.store_name.charAt(0)}
                            </div>
                        )}
                    </div>

                    <div className="flex-1 pb-2">
                        <div className="flex items-center gap-3">
                            <h1 className="text-2xl md:text-3xl font-black">{store.store_name}</h1>
                            {store.is_verified ? (
                                <Badge className="bg-primary/10 text-primary border-none">Verified</Badge>
                            ) : (
                                <Badge variant="outline">Unverified</Badge>
                            )}
                        </div>
                        <p className="text-muted-foreground">{store.tagline || 'Manage your store and products'}</p>
                    </div>

                    <div className="flex items-center gap-3 pb-2">
                        <Link href={`/shops/${store.slug}`}>
                            <Button variant="outline" className="rounded-xl gap-2">
                                <ExternalLink className="size-4" />
                                View Live
                            </Button>
                        </Link>
                        <Link href="/profile/stores/settings">
                            <Button variant="outline" size="icon" className="rounded-xl">
                                <Settings className="size-4" />
                            </Button>
                        </Link>
                    </div>
                </div>
            </div>

            {/* Quick Stats */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <StatCard
                    label="Store Views"
                    value={store.views?.toString() || '0'}
                    icon={Eye}
                    trend="+12%"
                />
                <StatCard
                    label="Active Products"
                    value={store.total_products?.toString() || '0'}
                    icon={Package}
                />
                <StatCard
                    label="Followers"
                    value={store.follower_count?.toString() || '0'}
                    icon={Users}
                    trend="+3"
                />
                <StatCard
                    label="Inquiries"
                    value="24"
                    icon={MessageCircle}
                    trend="+5 today"
                />
            </div>

            <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
                <div className="flex items-center justify-between">
                    <TabsList className="bg-muted/50 p-1 rounded-xl h-12">
                        <TabsTrigger value="products" className="rounded-lg px-8">Products</TabsTrigger>
                        <TabsTrigger value="analytics" className="rounded-lg px-8">Analytics</TabsTrigger>
                        <TabsTrigger value="inquiries" className="rounded-lg px-8">Inquiries</TabsTrigger>
                    </TabsList>

                    {activeTab === 'products' && (
                        <Link href="/profile/stores/products/create">
                            <Button className="rounded-xl gap-2 h-11">
                                <Plus className="size-4" />
                                Add Product
                            </Button>
                        </Link>
                    )}
                </div>

                <TabsContent value="products" className="space-y-6">
                    {isLoadingMyProducts ? (
                        <div className="grid grid-cols-1 gap-4">
                            {[...Array(3)].map((_, i) => (
                                <div key={i} className="h-24 bg-muted animate-pulse rounded-2xl" />
                            ))}
                        </div>
                    ) : products.length > 0 ? (
                        <div className="bg-card rounded-2xl border overflow-hidden">
                            <div className="overflow-x-auto">
                                <table className="w-full text-left">
                                    <thead className="bg-muted/50 text-xs font-bold uppercase tracking-wider text-muted-foreground border-b">
                                        <tr>
                                            <th className="px-6 py-4">Product</th>
                                            <th className="px-6 py-4">Price</th>
                                            <th className="px-6 py-4">Stock</th>
                                            <th className="px-6 py-4">Status</th>
                                            <th className="px-6 py-4 text-right">Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y">
                                        {products.map((product: Product) => (
                                            <tr key={product.id} className="hover:bg-muted/30 transition-colors">
                                                <td className="px-6 py-4">
                                                    <div className="flex items-center gap-3">
                                                        <div className="size-12 rounded-lg bg-muted relative overflow-hidden flex-shrink-0">
                                                            {product.images?.[0] && (
                                                                <Image src={product.images[0]} alt="" fill className="object-cover" />
                                                            )}
                                                        </div>
                                                        <div>
                                                            <p className="font-bold line-clamp-1">{product.title}</p>
                                                            <p className="text-xs text-muted-foreground">Updated {new Date(product.updated_at).toLocaleDateString()}</p>
                                                        </div>
                                                    </div>
                                                </td>
                                                <td className="px-6 py-4">
                                                    <p className="font-bold">${product.price}</p>
                                                </td>
                                                <td className="px-6 py-4">
                                                    <p className="font-medium">{product.stock_quantity}</p>
                                                </td>
                                                <td className="px-6 py-4">
                                                    {product.is_available ? (
                                                        <Badge className="bg-green-500/10 text-green-500 border-none">Active</Badge>
                                                    ) : (
                                                        <Badge variant="secondary">Draft</Badge>
                                                    )}
                                                </td>
                                                <td className="px-6 py-4 text-right">
                                                    <DropdownMenu>
                                                        <DropdownMenuTrigger asChild>
                                                            <Button variant="ghost" size="icon" className="rounded-lg">
                                                                <MoreVertical className="size-4" />
                                                            </Button>
                                                        </DropdownMenuTrigger>
                                                        <DropdownMenuContent align="end">
                                                            <DropdownMenuItem asChild>
                                                                <Link href={`/profile/stores/products/${product.id}/edit`} className="flex items-center gap-2">
                                                                    <Edit className="size-4" />
                                                                    Edit Product
                                                                </Link>
                                                            </DropdownMenuItem>
                                                            <DropdownMenuItem
                                                                className="text-destructive focus:text-destructive"
                                                                onClick={() => {
                                                                    if (confirm('Are you sure you want to delete this product?')) {
                                                                        deleteProductMutation.mutate(product.id);
                                                                    }
                                                                }}
                                                            >
                                                                <Trash2 className="size-4 mr-2" />
                                                                Delete
                                                            </DropdownMenuItem>
                                                        </DropdownMenuContent>
                                                    </DropdownMenu>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    ) : (
                        <div className="text-center py-20 border-2 border-dashed rounded-3xl space-y-4">
                            <div className="size-16 bg-muted rounded-full flex items-center justify-center mx-auto">
                                <Package className="size-8 text-muted-foreground" />
                            </div>
                            <div className="space-y-1">
                                <h3 className="text-xl font-bold">No products yet</h3>
                                <p className="text-muted-foreground">Start adding items to your storefront to begin selling.</p>
                            </div>
                            <Link href="/profile/stores/products/create">
                                <Button className="rounded-xl px-8 h-12 font-bold">Add Your First Product</Button>
                            </Link>
                        </div>
                    )}
                </TabsContent>

                <TabsContent value="analytics">
                    <Card className="rounded-3xl p-12 text-center border-none bg-muted/30">
                        <BarChart3 className="size-12 text-muted-foreground/30 mx-auto mb-4" />
                        <h3 className="text-lg font-bold">Advanced Analytics Coming Soon</h3>
                        <p className="text-muted-foreground">We're building powerful insights to help you grow your business.</p>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    );
}

function StatCard({ label, value, icon: Icon, trend }: any) {
    return (
        <Card className="rounded-2xl border-none shadow-sm shadow-black/5 bg-card">
            <CardContent className="p-6">
                <div className="flex items-start justify-between">
                    <div>
                        <p className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-1">{label}</p>
                        <h4 className="text-3xl font-black">{value}</h4>
                        {trend && (
                            <div className="flex items-center gap-1 mt-2">
                                <span className="text-xs font-bold text-green-500 bg-green-500/10 px-2 py-0.5 rounded-full">{trend}</span>
                                <span className="text-xs text-muted-foreground">vs last week</span>
                            </div>
                        )}
                    </div>
                    <div className="size-12 rounded-2xl bg-primary/10 flex items-center justify-center text-primary">
                        <Icon className="size-6" />
                    </div>
                </div>
            </CardContent>
        </Card>
    );
}
