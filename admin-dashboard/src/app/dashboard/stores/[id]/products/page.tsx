'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminGetStore, adminGetStoreProducts } from '@/features/stores/storeService';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Loader2, ArrowLeft, Package, Plus, Eye, Edit2, Trash2 } from 'lucide-react';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogFooter,
} from '@/components/ui/dialog';
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { format } from 'date-fns';
import api from '@/lib/api';

export default function StoreProductsPage() {
    const { id } = useParams();
    const router = useRouter();
    const queryClient = useQueryClient();

    const [isAddOpen, setIsAddOpen] = useState(false);
    const [editProduct, setEditProduct] = useState<any>(null);
    const [viewProduct, setViewProduct] = useState<any>(null);
    const [deleteProduct, setDeleteProduct] = useState<any>(null);

    const [formData, setFormData] = useState({
        title: '',
        description: '',
        price: '',
        condition: 'new',
        pricing_type: 'fixed',
    });

    const { data: store, isLoading: loadingStore } = useQuery({
        queryKey: ['admin-store', id],
        queryFn: () => adminGetStore(id as string),
        enabled: !!id,
    });

    const { data: productsData, isLoading: loadingProducts } = useQuery({
        queryKey: ['admin-store-products', id],
        queryFn: () => adminGetStoreProducts(id as string),
        enabled: !!id,
    });

    const products = productsData?.products || [];

    const createMutation = useMutation({
        mutationFn: async (data: any) => {
            const response = await api.post(`/admin/stores/${id}/products`, data);
            return response.data;
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['admin-store-products', id] });
            setIsAddOpen(false);
            resetForm();
        },
        onError: (err: any) => alert('Error: ' + (err.response?.data?.error || err.message)),
    });

    const updateMutation = useMutation({
        mutationFn: async ({ productId, data }: { productId: string; data: any }) => {
            const response = await api.put(`/admin/products/${productId}`, data);
            return response.data;
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['admin-store-products', id] });
            setEditProduct(null);
            resetForm();
        },
        onError: (err: any) => alert('Error: ' + (err.response?.data?.error || err.message)),
    });

    const deleteMutation = useMutation({
        mutationFn: async (productId: string) => {
            const response = await api.delete(`/admin/products/${productId}`);
            return response.data;
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['admin-store-products', id] });
            setDeleteProduct(null);
        },
        onError: (err: any) => alert('Error: ' + (err.response?.data?.error || err.message)),
    });

    const resetForm = () => {
        setFormData({ title: '', description: '', price: '', condition: 'new', pricing_type: 'fixed' });
    };

    const handleOpenEdit = (product: any) => {
        setFormData({
            title: product.title || '',
            description: product.description || '',
            price: product.price?.toString() || '',
            condition: product.condition || 'new',
            pricing_type: product.pricing_type || 'fixed',
        });
        setEditProduct(product);
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        const data = {
            ...formData,
            price: parseFloat(formData.price) || 0,
        };
        if (editProduct) {
            updateMutation.mutate({ productId: editProduct.id, data });
        } else {
            createMutation.mutate(data);
        }
    };

    if (loadingStore) {
        return <div className="flex justify-center p-12"><Loader2 className="animate-spin h-8 w-8" /></div>;
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                    <Button variant="ghost" size="icon" onClick={() => router.back()}>
                        <ArrowLeft className="h-4 w-4" />
                    </Button>
                    <div>
                        <h1 className="text-3xl font-bold tracking-tight">Manage Products</h1>
                        <p className="text-muted-foreground">{store?.store_name} • {products.length} products</p>
                    </div>
                </div>
                <Button onClick={() => setIsAddOpen(true)}>
                    <Plus className="mr-2 h-4 w-4" />
                    Add Product
                </Button>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Product Inventory</CardTitle>
                    <CardDescription>View and manage all products for this store.</CardDescription>
                </CardHeader>
                <CardContent>
                    {loadingProducts ? (
                        <div className="flex justify-center p-8"><Loader2 className="animate-spin h-6 w-6" /></div>
                    ) : products.length === 0 ? (
                        <div className="text-center py-12 text-muted-foreground">
                            <Package className="h-12 w-12 mx-auto mb-4 opacity-20" />
                            <p className="font-medium">No products found</p>
                            <p className="text-sm">This store hasn't added any products yet.</p>
                        </div>
                    ) : (
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead className="w-[80px]">Image</TableHead>
                                    <TableHead>Product</TableHead>
                                    <TableHead>Price</TableHead>
                                    <TableHead>Status</TableHead>
                                    <TableHead>Created</TableHead>
                                    <TableHead className="text-right">Actions</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {products.map((product: any) => (
                                    <TableRow key={product.id}>
                                        <TableCell>
                                            <div className="h-12 w-12 rounded overflow-hidden bg-muted flex items-center justify-center border">
                                                {product.images?.[0] ? (
                                                    <img src={product.images[0]} alt={product.title} className="h-full w-full object-cover" />
                                                ) : (
                                                    <Package className="h-5 w-5 text-muted-foreground" />
                                                )}
                                            </div>
                                        </TableCell>
                                        <TableCell>
                                            <div className="flex flex-col">
                                                <span className="font-medium">{product.title}</span>
                                                <span className="text-xs text-muted-foreground truncate max-w-[200px]">{product.description || 'No description'}</span>
                                            </div>
                                        </TableCell>
                                        <TableCell className="font-mono font-bold">${product.price?.toFixed(2)}</TableCell>
                                        <TableCell>
                                            {product.is_available ? (
                                                <Badge className="bg-green-100 text-green-800">Available</Badge>
                                            ) : (
                                                <Badge variant="outline" className="text-orange-600">Unavailable</Badge>
                                            )}
                                        </TableCell>
                                        <TableCell className="text-sm text-muted-foreground">
                                            {product.created_at ? format(new Date(product.created_at), 'MMM d, yyyy') : '-'}
                                        </TableCell>
                                        <TableCell className="text-right">
                                            <div className="flex justify-end gap-1">
                                                <Button variant="ghost" size="icon" title="View" onClick={() => setViewProduct(product)}>
                                                    <Eye className="h-4 w-4" />
                                                </Button>
                                                <Button variant="ghost" size="icon" title="Edit" onClick={() => handleOpenEdit(product)}>
                                                    <Edit2 className="h-4 w-4" />
                                                </Button>
                                                <Button variant="ghost" size="icon" className="text-destructive" title="Delete" onClick={() => setDeleteProduct(product)}>
                                                    <Trash2 className="h-4 w-4" />
                                                </Button>
                                            </div>
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    )}
                </CardContent>
            </Card>

            {/* Add/Edit Dialog */}
            <Dialog open={isAddOpen || !!editProduct} onOpenChange={(open) => { if (!open) { setIsAddOpen(false); setEditProduct(null); resetForm(); } }}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>{editProduct ? 'Edit Product' : 'Add New Product'}</DialogTitle>
                        <DialogDescription>{editProduct ? 'Update product details.' : 'Add a new product to this store.'}</DialogDescription>
                    </DialogHeader>
                    <form onSubmit={handleSubmit} className="space-y-4">
                        <div className="space-y-2">
                            <label className="text-sm font-medium">Title *</label>
                            <Input required value={formData.title} onChange={e => setFormData({ ...formData, title: e.target.value })} />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm font-medium">Description</label>
                            <Textarea value={formData.description} onChange={e => setFormData({ ...formData, description: e.target.value })} rows={3} />
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <label className="text-sm font-medium">Price *</label>
                                <Input type="number" step="0.01" required value={formData.price} onChange={e => setFormData({ ...formData, price: e.target.value })} />
                            </div>
                            <div className="space-y-2">
                                <label className="text-sm font-medium">Condition</label>
                                <select className="w-full h-10 rounded-md border border-input bg-background px-3" value={formData.condition} onChange={e => setFormData({ ...formData, condition: e.target.value })}>
                                    <option value="new">New</option>
                                    <option value="used">Used</option>
                                    <option value="refurbished">Refurbished</option>
                                </select>
                            </div>
                        </div>
                        <DialogFooter>
                            <Button type="submit" disabled={createMutation.isPending || updateMutation.isPending}>
                                {(createMutation.isPending || updateMutation.isPending) && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                {editProduct ? 'Update Product' : 'Add Product'}
                            </Button>
                        </DialogFooter>
                    </form>
                </DialogContent>
            </Dialog>

            {/* View Dialog */}
            <Dialog open={!!viewProduct} onOpenChange={() => setViewProduct(null)}>
                <DialogContent className="max-w-lg">
                    <DialogHeader>
                        <DialogTitle>{viewProduct?.title}</DialogTitle>
                    </DialogHeader>
                    {viewProduct && (
                        <div className="space-y-4">
                            {viewProduct.images?.[0] && (
                                <img src={viewProduct.images[0]} alt={viewProduct.title} className="w-full h-48 object-cover rounded-lg" />
                            )}
                            <div className="grid grid-cols-2 gap-4 text-sm">
                                <div><span className="text-muted-foreground">Price:</span> <strong>${viewProduct.price?.toFixed(2)}</strong></div>
                                <div><span className="text-muted-foreground">Condition:</span> <strong>{viewProduct.condition}</strong></div>
                                <div><span className="text-muted-foreground">Type:</span> <strong>{viewProduct.pricing_type}</strong></div>
                                <div><span className="text-muted-foreground">Available:</span> <strong>{viewProduct.is_available ? 'Yes' : 'No'}</strong></div>
                                <div><span className="text-muted-foreground">Views:</span> <strong>{viewProduct.views || 0}</strong></div>
                                <div><span className="text-muted-foreground">Stock:</span> <strong>{viewProduct.stock_quantity || 0}</strong></div>
                            </div>
                            <div>
                                <span className="text-muted-foreground text-sm">Description:</span>
                                <p className="mt-1">{viewProduct.description || 'No description'}</p>
                            </div>
                        </div>
                    )}
                </DialogContent>
            </Dialog>

            {/* Delete Confirmation */}
            <AlertDialog open={!!deleteProduct} onOpenChange={() => setDeleteProduct(null)}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>Delete Product</AlertDialogTitle>
                        <AlertDialogDescription>
                            Are you sure you want to delete "{deleteProduct?.title}"? This action cannot be undone.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>Cancel</AlertDialogCancel>
                        <AlertDialogAction onClick={() => deleteMutation.mutate(deleteProduct.id)} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                            {deleteMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Delete
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </div>
    );
}
