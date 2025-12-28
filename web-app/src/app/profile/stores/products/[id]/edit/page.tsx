'use client';

import { useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useQuery, useMutation } from '@tanstack/react-query';
import {
    Package,
    ArrowLeft,
    X,
    Info,
    DollarSign,
    Layers,
    Loader2,
    Check,
    Save
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
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { shopsService } from '@/services/shops';
import { categoriesService } from '@/services/categories';
import { Switch } from '@/components/ui/switch';

const productSchema = z.object({
    title: z.string().min(2, 'Title is too short').max(200),
    description: z.string().optional(),
    price: z.preprocess((val) => Number(val), z.number().gt(0, 'Price must be greater than 0')),
    compare_at_price: z.preprocess((val) => val === '' ? undefined : Number(val), z.number().optional()),
    pricing_type: z.enum(['fixed', 'negotiable', 'service']),
    category_id: z.string().min(1, 'Category is required'),
    condition: z.enum(['new', 'used', 'refurbished']),
    images: z.array(z.string()).optional(),
    stock_quantity: z.preprocess((val) => Number(val), z.number().int().min(0, 'Stock cannot be negative')),
    is_available: z.boolean().default(true),
});

type ProductFormValues = z.infer<typeof productSchema>;

export default function EditProductPage() {
    const router = useRouter();
    const { id } = useParams() as { id: string };

    const { data: product, isLoading: isLoadingProduct } = useQuery({
        queryKey: ['product', id],
        queryFn: () => shopsService.getProductById(id),
    });

    const form = useForm<ProductFormValues>({
        resolver: zodResolver(productSchema) as any,
        defaultValues: {
            title: '',
            description: '',
            price: 0,
            pricing_type: 'fixed',
            category_id: '',
            condition: 'new',
            images: [],
            stock_quantity: 1,
            is_available: true,
        },
    });

    useEffect(() => {
        if (product) {
            form.reset({
                title: product.title,
                description: product.description || '',
                price: product.price,
                compare_at_price: product.compare_at_price || undefined,
                pricing_type: product.pricing_type as any,
                category_id: product.category_id || '',
                condition: product.condition as any,
                images: product.images || [],
                stock_quantity: product.stock_quantity,
                is_available: product.is_available,
            });
        }
    }, [product, form]);

    // Queries
    const { data: categories } = useQuery({
        queryKey: ['categories'],
        queryFn: categoriesService.getCategories,
    });

    // Mutation
    const updateProductMutation = useMutation({
        mutationFn: (data: ProductFormValues) => shopsService.updateProduct(id, data),
        onSuccess: () => {
            toast.success('Product updated successfully!');
            router.push('/profile/stores');
        },
        onError: (error: any) => {
            toast.error(error.response?.data?.error || 'Failed to update product');
        },
    });

    const onSubmit = (data: ProductFormValues) => {
        updateProductMutation.mutate(data);
    };

    if (isLoadingProduct) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <Loader2 className="size-8 animate-spin text-primary" />
            </div>
        );
    }

    return (
        <div className="max-w-4xl mx-auto py-12">
            <div className="flex items-center gap-4 mb-8">
                <Button variant="ghost" size="icon" className="rounded-full" onClick={() => router.back()}>
                    <ArrowLeft className="size-5" />
                </Button>
                <div>
                    <h1 className="text-3xl font-black">Edit Product</h1>
                    <p className="text-muted-foreground">Modify your product details and availability.</p>
                </div>
            </div>

            <Form {...form}>
                <form onSubmit={form.handleSubmit(onSubmit)} className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                    <div className="lg:col-span-2 space-y-6">
                        <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <Info className="size-5 text-primary" />
                                    General Information
                                </CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                <FormField
                                    control={form.control}
                                    name="title"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Product Title</FormLabel>
                                            <FormControl>
                                                <Input {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />

                                <FormField
                                    control={form.control}
                                    name="description"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Description</FormLabel>
                                            <FormControl>
                                                <Textarea
                                                    {...field}
                                                    className="bg-muted/30 border-none rounded-xl min-h-[200px]"
                                                />
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
                                    <DollarSign className="size-5 text-primary" />
                                    Pricing & Stock
                                </CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <FormField
                                        control={form.control}
                                        name="price"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel>Selling Price ($)</FormLabel>
                                                <FormControl>
                                                    <Input type="number" step="0.01" {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
                                                </FormControl>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />

                                    <FormField
                                        control={form.control}
                                        name="compare_at_price"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel>Original Price ($) - Optional</FormLabel>
                                                <FormControl>
                                                    <Input type="number" step="0.01" {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
                                                </FormControl>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />
                                </div>

                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <FormField
                                        control={form.control}
                                        name="pricing_type"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel>Pricing Type</FormLabel>
                                                <Select onValueChange={field.onChange} value={field.value}>
                                                    <FormControl>
                                                        <SelectTrigger className="h-12 bg-muted/30 border-none rounded-xl">
                                                            <SelectValue />
                                                        </SelectTrigger>
                                                    </FormControl>
                                                    <SelectContent className="rounded-xl">
                                                        <SelectItem value="fixed">Fixed Price</SelectItem>
                                                        <SelectItem value="negotiable">Negotiable</SelectItem>
                                                        <SelectItem value="service">Service Rate</SelectItem>
                                                    </SelectContent>
                                                </Select>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />

                                    <FormField
                                        control={form.control}
                                        name="stock_quantity"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel>Stock Quantity</FormLabel>
                                                <FormControl>
                                                    <Input type="number" {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
                                                </FormControl>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />
                                </div>
                            </CardContent>
                        </Card>
                    </div>

                    <div className="space-y-6">
                        <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2 text-lg">Status & Category</CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                <FormField
                                    control={form.control}
                                    name="is_available"
                                    render={({ field }) => (
                                        <FormItem className="flex items-center justify-between p-4 bg-muted/30 rounded-2xl">
                                            <div className="space-y-0.5">
                                                <FormLabel>Available for Sale</FormLabel>
                                                <p className="text-xs text-muted-foreground">Turn off to hide from store</p>
                                            </div>
                                            <FormControl>
                                                <Switch checked={field.value} onCheckedChange={field.onChange} />
                                            </FormControl>
                                        </FormItem>
                                    )}
                                />

                                <FormField
                                    control={form.control}
                                    name="category_id"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Category</FormLabel>
                                            <Select onValueChange={field.onChange} value={field.value}>
                                                <FormControl>
                                                    <SelectTrigger className="h-12 bg-muted/30 border-none rounded-xl">
                                                        <SelectValue />
                                                    </SelectTrigger>
                                                </FormControl>
                                                <SelectContent className="rounded-xl">
                                                    {categories?.map((cat) => (
                                                        <SelectItem key={cat.id} value={cat.id}>{cat.name}</SelectItem>
                                                    ))}
                                                </SelectContent>
                                            </Select>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />

                                <FormField
                                    control={form.control}
                                    name="condition"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Condition</FormLabel>
                                            <Select onValueChange={field.onChange} value={field.value}>
                                                <FormControl>
                                                    <SelectTrigger className="h-12 bg-muted/30 border-none rounded-xl">
                                                        <SelectValue />
                                                    </SelectTrigger>
                                                </FormControl>
                                                <SelectContent className="rounded-xl">
                                                    <SelectItem value="new">New</SelectItem>
                                                    <SelectItem value="used">Used</SelectItem>
                                                    <SelectItem value="refurbished">Refurbished</SelectItem>
                                                </SelectContent>
                                            </Select>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                            </CardContent>
                        </Card>

                        <div className="sticky top-24 space-y-4">
                            <Button
                                type="submit"
                                className="w-full h-14 rounded-2xl text-lg font-bold gap-2"
                                disabled={updateProductMutation.isPending}
                            >
                                {updateProductMutation.isPending ? (
                                    <Loader2 className="size-5 animate-spin" />
                                ) : (
                                    <Save className="size-5" />
                                )}
                                Save Changes
                            </Button>
                        </div>
                    </div>
                </form>
            </Form>
        </div>
    );
}
