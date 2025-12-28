'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useMutation, useQuery } from '@tanstack/react-query';
import {
    ArrowLeft,
    ArrowRight,
    Upload,
    ImagePlus,
    X,
    Loader2,
    Check,
    Info,
    Clock,
    DollarSign,
    MapPin,
    Tag,
    Package
} from 'lucide-react';
import { toast } from 'sonner';
import Image from 'next/image';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import {
    Form,
    FormControl,
    FormDescription,
    FormField,
    FormItem,
    FormLabel,
    FormMessage,
} from '@/components/ui/form';

import { auctionsService } from '@/services/auctions';
import { categoriesService } from '@/services/categories';
import { authService } from '@/services/auth';
import { useAuthStore } from '@/stores/authStore';
import { cn } from '@/lib/utils';
import { ImageUpload } from '@/components/ui/image-upload';

const auctionSchema = z.object({
    title: z.string().min(5, 'Title must be at least 5 characters').max(100),
    description: z.string().min(20, 'Description must be at least 20 characters').max(2000),
    category_id: z.string().min(1, 'Please select a category'),
    condition: z.enum(['new', 'like_new', 'good', 'fair', 'poor']),
    starting_price: z.coerce.number().min(1, 'Starting price must be at least $1'),
    reserve_price: z.coerce.number().optional(),
    bid_increment: z.coerce.number().min(1, 'Bid increment must be at least $1'),
    duration_hours: z.coerce.number().min(1).max(168),
    town_id: z.string().min(1, 'Please select a town'),
    suburb_id: z.string().optional(),
    pickup_location: z.string().optional(),
    shipping_available: z.boolean().default(false),
    images: z.array(z.string()).min(1, 'Please add at least one image'),
});

type AuctionFormValues = z.infer<typeof auctionSchema>;

const conditionOptions = [
    { value: 'new', label: 'Brand New', description: 'Unused, in original packaging' },
    { value: 'like_new', label: 'Like New', description: 'Barely used, excellent condition' },
    { value: 'good', label: 'Good', description: 'Used but well maintained' },
    { value: 'fair', label: 'Fair', description: 'Shows signs of wear' },
    { value: 'poor', label: 'For Parts', description: 'May need repairs' },
];

const durationOptions = [
    { value: 24, label: '1 Day' },
    { value: 72, label: '3 Days' },
    { value: 120, label: '5 Days' },
    { value: 168, label: '7 Days' },
];

export default function CreateAuctionPage() {
    const router = useRouter();
    const { user } = useAuthStore();
    const [step, setStep] = useState(1);

    const form = useForm({
        resolver: zodResolver(auctionSchema) as any,
        defaultValues: {
            title: '',
            description: '',
            category_id: '',
            condition: 'good' as const,
            starting_price: 10,
            reserve_price: '' as unknown as number | undefined,
            bid_increment: 1,
            duration_hours: 72,
            town_id: user?.home_town_id || '',
            suburb_id: '' as string | undefined,
            pickup_location: '' as string | undefined,
            shipping_available: false,
            images: [] as string[],
        },
    });

    // Queries
    const { data: categories } = useQuery({
        queryKey: ['categories'],
        queryFn: categoriesService.getCategories,
    });

    const { data: towns } = useQuery({
        queryKey: ['towns'],
        queryFn: authService.getTowns,
    });

    const townId = form.watch('town_id');
    const { data: suburbs } = useQuery({
        queryKey: ['suburbs', townId],
        queryFn: () => authService.getSuburbs(townId),
        enabled: !!townId,
    });

    // Mutation
    const createAuctionMutation = useMutation({
        mutationFn: (data: AuctionFormValues) => auctionsService.createAuction({
            ...data,
            // Calculate end time from duration
            end_time: new Date(Date.now() + data.duration_hours * 60 * 60 * 1000).toISOString(),
        }),
        onSuccess: (auction) => {
            toast.success('Auction created successfully!');
            router.push(`/auctions/${auction.id}`);
        },
        onError: (error: any) => {
            toast.error(error.response?.data?.error || 'Failed to create auction');
        },
    });

    const onSubmit = (data: AuctionFormValues) => {
        createAuctionMutation.mutate(data);
    };

    const nextStep = async () => {
        const fieldsToValidate: any = step === 1
            ? ['title', 'description', 'category_id', 'condition']
            : step === 2
                ? ['starting_price', 'bid_increment', 'duration_hours']
                : ['town_id', 'images'];

        const isValid = await form.trigger(fieldsToValidate);
        if (isValid) setStep(step + 1);
    };

    const prevStep = () => {
        if (step > 1) setStep(step - 1);
        else router.back();
    };

    // Handle image changes from ImageUpload component
    const handleImagesChange = (urls: string[]) => {
        form.setValue('images', urls, { shouldValidate: true });
    };

    return (
        <div className="max-w-3xl mx-auto py-8 px-4">
            {/* Header */}
            <div className="flex items-center gap-4 mb-8">
                <Button variant="ghost" size="icon" className="rounded-full" onClick={prevStep}>
                    <ArrowLeft className="size-5" />
                </Button>
                <div>
                    <h1 className="text-3xl font-black">Create Auction</h1>
                    <p className="text-muted-foreground">
                        Step {step} of 4: {step === 1 ? 'Item Details' : step === 2 ? 'Pricing' : step === 3 ? 'Location & Images' : 'Review'}
                    </p>
                </div>
            </div>

            {/* Progress Bar */}
            <div className="flex gap-2 mb-10">
                {[1, 2, 3, 4].map((i) => (
                    <div
                        key={i}
                        className={cn(
                            "h-1.5 flex-1 rounded-full transition-all duration-500",
                            i <= step ? "bg-primary" : "bg-muted"
                        )}
                    />
                ))}
            </div>

            <Form {...form}>
                <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
                    {/* Step 1: Item Details */}
                    {step === 1 && (
                        <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <Package className="size-5 text-primary" />
                                    Item Details
                                </CardTitle>
                                <CardDescription>Tell us about the item you're selling</CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                <FormField
                                    control={form.control}
                                    name="title"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Title</FormLabel>
                                            <FormControl>
                                                <Input placeholder="e.g. iPhone 14 Pro Max 256GB" {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
                                            </FormControl>
                                            <FormDescription>Be specific and descriptive</FormDescription>
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
                                                    placeholder="Describe the item in detail. Include any defects, accessories, or special features..."
                                                    {...field}
                                                    className="min-h-[150px] bg-muted/30 border-none rounded-xl"
                                                />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />

                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <FormField
                                        control={form.control}
                                        name="category_id"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel>Category</FormLabel>
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
                                                <FormLabel>Condition</FormLabel>
                                                <Select onValueChange={field.onChange} defaultValue={field.value}>
                                                    <FormControl>
                                                        <SelectTrigger className="h-12 bg-muted/30 border-none rounded-xl">
                                                            <SelectValue placeholder="Select condition" />
                                                        </SelectTrigger>
                                                    </FormControl>
                                                    <SelectContent className="rounded-xl">
                                                        {conditionOptions.map((opt) => (
                                                            <SelectItem key={opt.value} value={opt.value}>
                                                                <div>
                                                                    <span className="font-medium">{opt.label}</span>
                                                                </div>
                                                            </SelectItem>
                                                        ))}
                                                    </SelectContent>
                                                </Select>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />
                                </div>

                                <Button type="button" className="w-full h-14 rounded-2xl text-lg font-bold" onClick={nextStep}>
                                    Next: Pricing
                                    <ArrowRight className="size-5 ml-2" />
                                </Button>
                            </CardContent>
                        </Card>
                    )}

                    {/* Step 2: Pricing */}
                    {step === 2 && (
                        <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <DollarSign className="size-5 text-primary" />
                                    Pricing & Duration
                                </CardTitle>
                                <CardDescription>Set your starting price and auction duration</CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <FormField
                                        control={form.control}
                                        name="starting_price"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel>Starting Price ($)</FormLabel>
                                                <FormControl>
                                                    <div className="relative">
                                                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground font-bold">$</span>
                                                        <Input
                                                            type="number"
                                                            placeholder="10.00"
                                                            {...field}
                                                            className="h-12 pl-10 bg-muted/30 border-none rounded-xl"
                                                        />
                                                    </div>
                                                </FormControl>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />

                                    <FormField
                                        control={form.control}
                                        name="bid_increment"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel>Bid Increment ($)</FormLabel>
                                                <FormControl>
                                                    <div className="relative">
                                                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground font-bold">$</span>
                                                        <Input
                                                            type="number"
                                                            placeholder="1.00"
                                                            {...field}
                                                            className="h-12 pl-10 bg-muted/30 border-none rounded-xl"
                                                        />
                                                    </div>
                                                </FormControl>
                                                <FormDescription>Minimum bid increase</FormDescription>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />
                                </div>

                                <FormField
                                    control={form.control}
                                    name="reserve_price"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Reserve Price (Optional)</FormLabel>
                                            <FormControl>
                                                <div className="relative">
                                                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground font-bold">$</span>
                                                    <Input
                                                        type="number"
                                                        placeholder="0.00"
                                                        {...field}
                                                        value={field.value ?? ''}
                                                        className="h-12 pl-10 bg-muted/30 border-none rounded-xl"
                                                    />
                                                </div>
                                            </FormControl>
                                            <FormDescription>Item won't sell below this price (hidden from bidders)</FormDescription>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />

                                <FormField
                                    control={form.control}
                                    name="duration_hours"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Auction Duration</FormLabel>
                                            <div className="flex flex-wrap gap-3">
                                                {durationOptions.map((opt) => (
                                                    <Button
                                                        key={opt.value}
                                                        type="button"
                                                        variant={field.value === opt.value ? 'default' : 'outline'}
                                                        className={cn(
                                                            "rounded-xl h-12 px-6",
                                                            field.value === opt.value && "bg-primary text-primary-foreground"
                                                        )}
                                                        onClick={() => form.setValue('duration_hours', opt.value)}
                                                    >
                                                        <Clock className="size-4 mr-2" />
                                                        {opt.label}
                                                    </Button>
                                                ))}
                                            </div>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />

                                <Button type="button" className="w-full h-14 rounded-2xl text-lg font-bold" onClick={nextStep}>
                                    Next: Location & Photos
                                    <ArrowRight className="size-5 ml-2" />
                                </Button>
                            </CardContent>
                        </Card>
                    )}

                    {/* Step 3: Location & Images */}
                    {step === 3 && (
                        <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <MapPin className="size-5 text-primary" />
                                    Location & Photos
                                </CardTitle>
                                <CardDescription>Where is the item located? Add photos to attract buyers.</CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <FormField
                                        control={form.control}
                                        name="town_id"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel>Town / City</FormLabel>
                                                <Select onValueChange={field.onChange} defaultValue={field.value}>
                                                    <FormControl>
                                                        <SelectTrigger className="h-12 bg-muted/30 border-none rounded-xl">
                                                            <SelectValue placeholder="Select town" />
                                                        </SelectTrigger>
                                                    </FormControl>
                                                    <SelectContent className="rounded-xl">
                                                        {towns?.map((town) => (
                                                            <SelectItem key={town.id} value={town.id}>{town.name}</SelectItem>
                                                        ))}
                                                    </SelectContent>
                                                </Select>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />

                                    <FormField
                                        control={form.control}
                                        name="suburb_id"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel>Suburb (Optional)</FormLabel>
                                                <Select onValueChange={field.onChange} defaultValue={field.value} disabled={!townId}>
                                                    <FormControl>
                                                        <SelectTrigger className="h-12 bg-muted/30 border-none rounded-xl">
                                                            <SelectValue placeholder="Select suburb" />
                                                        </SelectTrigger>
                                                    </FormControl>
                                                    <SelectContent className="rounded-xl">
                                                        {suburbs?.map((sub) => (
                                                            <SelectItem key={sub.id} value={sub.id}>{sub.name}</SelectItem>
                                                        ))}
                                                    </SelectContent>
                                                </Select>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />
                                </div>

                                <FormField
                                    control={form.control}
                                    name="pickup_location"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Pickup Location (Optional)</FormLabel>
                                            <FormControl>
                                                <Input
                                                    placeholder="e.g. CBD, near Sam Levy's Village"
                                                    {...field}
                                                    className="h-12 bg-muted/30 border-none rounded-xl"
                                                />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />

                                {/* Image Upload Section */}
                                <div className="space-y-3">
                                    <Label>Photos</Label>
                                    <ImageUpload
                                        value={form.watch('images') || []}
                                        onChange={handleImagesChange}
                                        maxImages={6}
                                        folder="auctions"
                                    />
                                    {form.formState.errors.images && (
                                        <p className="text-sm text-destructive">{form.formState.errors.images.message}</p>
                                    )}
                                </div>

                                <Button type="button" className="w-full h-14 rounded-2xl text-lg font-bold" onClick={nextStep}>
                                    Review Listing
                                    <ArrowRight className="size-5 ml-2" />
                                </Button>
                            </CardContent>
                        </Card>
                    )}

                    {/* Step 4: Review */}
                    {step === 4 && (
                        <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <Check className="size-5 text-primary" />
                                    Review Your Listing
                                </CardTitle>
                                <CardDescription>Make sure everything looks good before publishing</CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                {/* Preview Card */}
                                <div className="rounded-2xl border bg-muted/20 p-6 space-y-4">
                                    {(form.watch('images') || []).length > 0 && (
                                        <div className="relative aspect-video rounded-xl overflow-hidden">
                                            <Image src={form.watch('images')[0]} alt="" fill className="object-cover" />
                                        </div>
                                    )}

                                    <div>
                                        <h3 className="text-xl font-bold">{form.watch('title') || 'Untitled'}</h3>
                                        <p className="text-muted-foreground text-sm line-clamp-2 mt-1">
                                            {form.watch('description')}
                                        </p>
                                    </div>

                                    <div className="flex flex-wrap gap-2">
                                        <Badge variant="secondary">
                                            {categories?.find((c) => c.id === form.watch('category_id'))?.name || 'Category'}
                                        </Badge>
                                        <Badge variant="outline">
                                            {conditionOptions.find((c) => c.value === form.watch('condition'))?.label}
                                        </Badge>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4 pt-4 border-t">
                                        <div>
                                            <p className="text-xs text-muted-foreground">Starting Price</p>
                                            <p className="text-2xl font-bold text-primary">${Number(form.watch('starting_price') || 0).toFixed(2)}</p>
                                        </div>
                                        <div>
                                            <p className="text-xs text-muted-foreground">Duration</p>
                                            <p className="text-lg font-semibold">
                                                {durationOptions.find((d) => d.value === form.watch('duration_hours'))?.label}
                                            </p>
                                        </div>
                                    </div>
                                </div>

                                <div className="bg-primary/5 rounded-2xl p-4 flex items-start gap-3">
                                    <Info className="size-5 text-primary mt-0.5" />
                                    <div className="text-sm">
                                        <p className="font-medium">What happens next?</p>
                                        <p className="text-muted-foreground">
                                            Your auction will go live immediately and run for the duration you selected.
                                            You'll receive notifications when bids are placed.
                                        </p>
                                    </div>
                                </div>

                                <Button
                                    type="submit"
                                    className="w-full h-14 rounded-2xl text-lg font-bold"
                                    disabled={createAuctionMutation.isPending}
                                >
                                    {createAuctionMutation.isPending ? (
                                        <>
                                            <Loader2 className="size-5 mr-2 animate-spin" />
                                            Publishing...
                                        </>
                                    ) : (
                                        <>
                                            Publish Auction
                                            <Check className="size-5 ml-2" />
                                        </>
                                    )}
                                </Button>
                            </CardContent>
                        </Card>
                    )}
                </form>
            </Form>
        </div>
    );
}
