'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { createCategory, updateCategory, deleteCategory } from '@/features/admin/adminService';
import { getCategories } from '@/features/categories/categoryService';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Loader2, Plus, Edit2, Trash2, Folder, Layers, MoreVertical } from 'lucide-react';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
    DialogFooter,
} from "@/components/ui/dialog";
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';

export default function CategoriesPage() {
    const queryClient = useQueryClient();
    const [isDialogOpen, setIsDialogOpen] = useState(false);
    const [editingCategory, setEditingCategory] = useState<any>(null);

    // Form State
    const [formData, setFormData] = useState({
        name: '',
        icon: '',
        description: '',
        sort_order: 0,
        is_active: true
    });

    const { data: catData, isLoading } = useQuery({
        queryKey: ['categories'],
        queryFn: () => getCategories(),
    });

    const createMutation = useMutation({
        mutationFn: createCategory,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['categories'] });
            setIsDialogOpen(false);
            resetForm();
            alert('Category created successfully');
        }
    });

    const updateMutation = useMutation({
        mutationFn: ({ id, data }: { id: string; data: any }) => updateCategory(id, data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['categories'] });
            setIsDialogOpen(false);
            resetForm();
            alert('Category updated successfully');
        }
    });

    const deleteMutation = useMutation({
        mutationFn: deleteCategory,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['categories'] });
            alert('Category deleted successfully');
        }
    });

    const resetForm = () => {
        setFormData({ name: '', icon: '', description: '', sort_order: 0, is_active: true });
        setEditingCategory(null);
    };

    const handleEdit = (cat: any) => {
        setEditingCategory(cat);
        setFormData({
            name: cat.name,
            icon: cat.icon || '',
            description: cat.description || '',
            sort_order: cat.sort_order || 0,
            is_active: cat.is_active
        });
        setIsDialogOpen(true);
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (editingCategory) {
            updateMutation.mutate({ id: editingCategory.id, data: formData });
        } else {
            createMutation.mutate(formData);
        }
    };

    const handleDeactivate = (cat: any) => {
        if (confirm(`Are you sure you want to ${cat.is_active ? 'deactivate' : 'reactivate'} this category?`)) {
            updateMutation.mutate({ id: cat.id, data: { is_active: !cat.is_active } });
        }
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Taxonomy & Categories</h1>
                    <p className="text-muted-foreground">Manage platform product categories and hierarchy.</p>
                </div>
                <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
                    <DialogTrigger asChild>
                        <Button onClick={resetForm}><Plus className="mr-2 h-4 w-4" /> Add Category</Button>
                    </DialogTrigger>
                    <DialogContent>
                        <DialogHeader>
                            <DialogTitle>{editingCategory ? 'Edit Category' : 'Create New Category'}</DialogTitle>
                            <DialogDescription>Define a new category for the platform.</DialogDescription>
                        </DialogHeader>
                        <form onSubmit={handleSubmit} className="space-y-4 py-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-2 col-span-2">
                                    <label className="text-sm font-medium">Category Name</label>
                                    <Input required value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-sm font-medium">Icon Code (Emoji/Slug)</label>
                                    <Input value={formData.icon} onChange={e => setFormData({ ...formData, icon: e.target.value })} placeholder="e.g. 🚗" />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-sm font-medium">Sort Order</label>
                                    <Input type="number" value={formData.sort_order} onChange={e => setFormData({ ...formData, sort_order: parseInt(e.target.value) })} />
                                </div>
                                <div className="space-y-2 col-span-2">
                                    <label className="text-sm font-medium">Description</label>
                                    <Input value={formData.description} onChange={e => setFormData({ ...formData, description: e.target.value })} />
                                </div>
                            </div>
                            <DialogFooter>
                                <Button type="submit" disabled={createMutation.isPending || updateMutation.isPending}>
                                    {(createMutation.isPending || updateMutation.isPending) && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                    {editingCategory ? 'Update Category' : 'Create Category'}
                                </Button>
                            </DialogFooter>
                        </form>
                    </DialogContent>
                </Dialog>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Platform Categories</CardTitle>
                    <CardDescription>All top-level and subcategories currently active in the system.</CardDescription>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead className="w-[50px]">Icon</TableHead>
                                <TableHead>Name</TableHead>
                                <TableHead>Listings</TableHead>
                                <TableHead>Order</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead className="text-right">Actions</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {isLoading ? (
                                <TableRow><TableCell colSpan={6} className="text-center py-10"><Loader2 className="animate-spin mx-auto h-6 w-6" /></TableCell></TableRow>
                            ) : catData?.categories?.map((cat: any) => (
                                <TableRow key={cat.id} className={!cat.is_active ? 'opacity-50' : ''}>
                                    <TableCell className="text-base">{cat.icon || '📁'}</TableCell>
                                    <TableCell>
                                        <p className="font-bold">{cat.name}</p>
                                        <p className="text-[10px] text-muted-foreground truncate max-w-xs">{cat.description || 'No description'}</p>
                                    </TableCell>
                                    <TableCell>
                                        <Badge variant="secondary" className="gap-1">
                                            <Layers className="h-3 w-3" />
                                            {cat.active_auctions || 0}
                                        </Badge>
                                    </TableCell>
                                    <TableCell className="font-mono text-xs">{cat.sort_order}</TableCell>
                                    <TableCell>
                                        {cat.is_active ? (
                                            <Badge className="bg-green-100 text-green-800">Active</Badge>
                                        ) : (
                                            <Badge variant="outline">Hidden</Badge>
                                        )}
                                    </TableCell>
                                    <TableCell className="text-right">
                                        <div className="flex justify-end gap-2">
                                            <Button variant="ghost" size="icon" onClick={() => handleEdit(cat)}>
                                                <Edit2 className="h-4 w-4" />
                                            </Button>
                                            <Button
                                                variant="ghost"
                                                size="sm"
                                                className={cat.is_active ? "text-orange-600 hover:text-orange-700" : "text-green-600 hover:text-green-700"}
                                                onClick={() => handleDeactivate(cat)}
                                            >
                                                {cat.is_active ? 'Deactivate' : 'Reactivate'}
                                            </Button>
                                        </div>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </CardContent>
            </Card>
        </div>
    );
}
