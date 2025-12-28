'use client';

import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useQuery, useMutation } from '@tanstack/react-query';
import {
    Package,
    ArrowLeft,
    Plus,
    X,
    Info,
    DollarSign,
    Layers,
    Activity,
    Loader2,
    Check
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
import { categoriesService } from '@/services/categories';
import { cn } from '@/lib/utils';

const productSchema = z.object({
    title: z.string().min(2, 'Title is too short').max(200),
    description: z.string().optional(),
    price: z.preprocess((val) => Number(val), z.number().gt(0, 'Price must be greater than 0')),
    compare_at_price: z.preprocess((val) => val === '' ? undefined : Number(val), z.number().optional()),
    pricing_type: z.enum(['fixed', 'negotiable', 'service']),
    category_id: z.string().min(1, 'Category is required'),
    condition: z.enum(['new', 'used', 'refurbished']),
    images: z.array(z.string()).optional(),
    stock_quantity: z.preprocess((val) => Number(val), z.number().int().min(1, 'Stock must be at least 1')),
});

type ProductFormValues = z.infer<typeof productSchema>;

export default function CreateProductPage() {
    const router = useRouter();

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
        },
    });

    // Queries
    const { data: categories } = useQuery({
        queryKey: ['categories'],
        queryFn: categoriesService.getCategories,
    });

    // Mutation
    const createProductMutation = useMutation({
        mutationFn: (data: ProductFormValues) => shopsService.createProduct(data),
        onSuccess: () => {
            toast.success('Product added successfully!');
            router.push('/profile/stores');
        },
        onError: (error: any) => {
            toast.error(error.response?.data?.error || 'Failed to add product');
        },
    });

    const onSubmit = (data: ProductFormValues) => {
        createProductMutation.mutate(data);
    };

    return (
        <div className="max-w-4xl mx-auto py-12">
            <div className="flex items-center gap-4 mb-8">
                <Button variant="ghost" size="icon" className="rounded-full" onClick={() => router.back()}>
                    <ArrowLeft className="size-5" />
                </Button>
                <div>
                    <h1 className="text-3xl font-black">Add New Product</h1>
                    <p className="text-muted-foreground">Fill in the details below to list your item.</p>
                </div>
            </div>

            <Form {...form}>
                <form onSubmit={form.handleSubmit(onSubmit)} className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                    {/* Left Column: Form Details */}
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
                                                <Input placeholder="e.g. iPhone 15 Pro Max 256GB" {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
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
                                                    placeholder="Provide details about the product, features, and specifications..."
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
                                                <FormDescription>Shows a "Sale" badge if set.</FormDescription>
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
                                                <Select onValueChange={field.onChange} defaultValue={field.value}>
                                                    <FormControl>
                                                        <SelectTrigger className="h-12 bg-muted/30 border-none rounded-xl">
                                                            <SelectValue placeholder="Select type" />
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

                    {/* Right Column: Organization */}
                    <div className="space-y-6">
                        <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <Layers className="size-5 text-primary" />
                                    Categorization
                                </CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                <FormField
                                    control={form.control}
                                    name="category_id"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Product Category</FormLabel>
                                            <Select onValueChange={field.onChange} defaultValue={field.value}>
                                                <FormControl>
                                                    <SelectTrigger className="h-12 bg-muted/30 border-none rounded-xl">
                                                        <SelectValue placeholder="Select category" />
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
                                            <FormLabel>Item Condition</FormLabel>
                                            <Select onValueChange={field.onChange} defaultValue={field.value}>
                                                <FormControl>
                                                    <SelectTrigger className="h-12 bg-muted/30 border-none rounded-xl">
                                                        <SelectValue placeholder="Select condition" />
                                                    </SelectTrigger>
                                                </FormControl>
                                                <SelectContent className="rounded-xl">
                                                    <SelectItem value="new">New</SelectItem>
                                                    <SelectItem value="used">Used / Second Hand</SelectItem>
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
                                className="w-full h-14 rounded-2xl text-lg font-bold"
                                disabled={createProductMutation.isPending}
                            >
                                {createProductMutation.isPending ? (
                                    <>
                                        <Loader2 className="size-5 mr-2 animate-spin" />
                                        Adding Product...
                                    </>
                                ) : (
                                    <>
                                        List Product
                                        <Check className="size-5 ml-2" />
                                    </>
                                )}
                            </Button>
                            <Button
                                type="button"
                                variant="outline"
                                className="w-full h-12 rounded-xl"
                                onClick={() => router.back()}
                            >
                                Cancel
                            </Button>
                        </div>
                    </div>
                </form>
            </Form>
        </div>
    );
}
