'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useQuery, useMutation } from '@tanstack/react-query';
import {
    Store,
    Image as ImageIcon,
    MapPin,
    MessageCircle,
    Phone,
    Truck,
    Info,
    Check,
    Loader2,
    ArrowRight,
    ArrowLeft,
    Upload
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
import { authService } from '@/services/auth';
import { cn } from '@/lib/utils';

const storeSchema = z.object({
    store_name: z.string().min(2, 'Store name is too short').max(100),
    tagline: z.string().max(100, 'Tagline is too long').optional(),
    about: z.string().optional(),
    logo_url: z.string().optional(),
    cover_url: z.string().optional(),
    category_id: z.string().min(1, 'Category is required'),
    whatsapp: z.string().optional(),
    phone: z.string().optional(),
    delivery_options: z.array(z.string()).min(1, 'Select at least one delivery option'),
    town_id: z.string().min(1, 'Town is required'),
    suburb_id: z.string().optional(),
    address: z.string().optional(),
});

type StoreFormValues = z.infer<typeof storeSchema>;

export default function CreateStorePage() {
    const router = useRouter();
    const [step, setStep] = useState(1);

    const form = useForm<StoreFormValues>({
        resolver: zodResolver(storeSchema),
        defaultValues: {
            store_name: '',
            tagline: '',
            about: '',
            category_id: '',
            delivery_options: ['pickup'],
            town_id: '',
        },
    });

    // Queries
    const { data: storeCategories } = useQuery({
        queryKey: ['store-categories'],
        queryFn: shopsService.getShopCategories,
    });

    const { data: towns } = useQuery({
        queryKey: ['towns'],
        queryFn: authService.getTowns,
    });

    const { data: suburbs } = useQuery({
        queryKey: ['suburbs', form.watch('town_id')],
        queryFn: () => authService.getSuburbs(form.watch('town_id')),
        enabled: !!form.watch('town_id'),
    });

    // Mutation
    const createStoreMutation = useMutation({
        mutationFn: (data: StoreFormValues) => shopsService.createShop(data),
        onSuccess: () => {
            toast.success('Your store has been created!');
            router.push('/profile/stores');
        },
        onError: (error: any) => {
            toast.error(error.response?.data?.error || 'Failed to create store');
        },
    });

    const onSubmit = (data: StoreFormValues) => {
        createStoreMutation.mutate(data);
    };

    const nextStep = async () => {
        const fields: any = step === 1
            ? ['store_name', 'category_id', 'town_id']
            : step === 2
                ? ['whatsapp', 'phone']
                : [];

        const isValid = await form.trigger(fields);
        if (isValid) setStep(step + 1);
    };

    return (
        <div className="max-w-3xl mx-auto py-12">
            <div className="flex items-center gap-4 mb-8">
                <Button variant="ghost" size="icon" className="rounded-full" onClick={() => step > 1 ? setStep(step - 1) : router.back()}>
                    <ArrowLeft className="size-5" />
                </Button>
                <div>
                    <h1 className="text-3xl font-black">Open Your Store</h1>
                    <p className="text-muted-foreground">Step {step} of 3: {step === 1 ? 'Basic Info' : step === 2 ? 'Contact & Delivery' : 'Branding'}</p>
                </div>
            </div>

            {/* Progress Bar */}
            <div className="flex gap-2 mb-10">
                {[1, 2, 3].map((i) => (
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
                    {step === 1 && (
                        <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <Info className="size-5 text-primary" />
                                    General Information
                                </CardTitle>
                                <CardDescription>Start with the basics. You can always change these later.</CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                <FormField
                                    control={form.control}
                                    name="store_name"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Store Name</FormLabel>
                                            <FormControl>
                                                <Input placeholder="e.g. Harare Electronics Hub" {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
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
                                                <FormLabel>Business Category</FormLabel>
                                                <Select onValueChange={field.onChange} defaultValue={field.value}>
                                                    <FormControl>
                                                        <SelectTrigger className="h-12 bg-muted/30 border-none rounded-xl">
                                                            <SelectValue placeholder="Select category" />
                                                        </SelectTrigger>
                                                    </FormControl>
                                                    <SelectContent className="rounded-xl">
                                                        {storeCategories?.map((cat) => (
                                                            <SelectItem key={cat.id} value={cat.id}>{cat.display_name}</SelectItem>
                                                        ))}
                                                    </SelectContent>
                                                </Select>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />

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
                                </div>

                                <FormField
                                    control={form.control}
                                    name="tagline"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Tagline (Optional)</FormLabel>
                                            <FormControl>
                                                <Input placeholder="e.g. Quality and trust in every deal" {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
                                            </FormControl>
                                            <FormDescription>A short sentence that describes your business.</FormDescription>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />

                                <Button type="button" className="w-full h-14 rounded-2xl text-lg font-bold" onClick={nextStep}>
                                    Next: Contact Details
                                    <ArrowRight className="size-5 ml-2" />
                                </Button>
                            </CardContent>
                        </Card>
                    )}

                    {step === 2 && (
                        <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <MessageCircle className="size-5 text-primary" />
                                    Contact & Delivery
                                </CardTitle>
                                <CardDescription>How will people reach you and get their items?</CardDescription>
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
                                                    <div className="relative">
                                                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground font-bold">+263</span>
                                                        <Input placeholder="771234567" {...field} className="h-12 pl-16 bg-muted/30 border-none rounded-xl" />
                                                    </div>
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
                                                <FormLabel>Phone Number</FormLabel>
                                                <FormControl>
                                                    <Input placeholder="0242XXXXXX" {...field} className="h-12 bg-muted/30 border-none rounded-xl" />
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
                                            <FormLabel>Physical Address (Optional)</FormLabel>
                                            <FormControl>
                                                <Textarea placeholder="123 Samora Machel Avenue, Harare" {...field} className="bg-muted/30 border-none rounded-xl min-h-[100px]" />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />

                                <div className="space-y-3 pt-4 border-t">
                                    <FormLabel>Delivery Options</FormLabel>
                                    <div className="flex flex-wrap gap-4">
                                        {['pickup', 'local_delivery', 'national_shipping'].map((option) => (
                                            <Button
                                                key={option}
                                                type="button"
                                                variant={form.watch('delivery_options').includes(option) ? 'secondary' : 'outline'}
                                                className={cn(
                                                    "rounded-xl h-12 gap-2 px-4",
                                                    form.watch('delivery_options').includes(option) && "bg-primary/10 text-primary border-primary/20 hover:bg-primary/20"
                                                )}
                                                onClick={() => {
                                                    const current = form.getValues('delivery_options');
                                                    if (current.includes(option)) {
                                                        if (current.length > 1) {
                                                            form.setValue('delivery_options', current.filter(o => o !== option));
                                                        }
                                                    } else {
                                                        form.setValue('delivery_options', [...current, option]);
                                                    }
                                                }}
                                            >
                                                {form.watch('delivery_options').includes(option) && <Check className="size-4" />}
                                                {option.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                                            </Button>
                                        ))}
                                    </div>
                                    <FormMessage>{form.formState.errors.delivery_options?.message}</FormMessage>
                                </div>

                                <Button type="button" className="w-full h-14 rounded-2xl text-lg font-bold" onClick={nextStep}>
                                    Next: Branding
                                    <ArrowRight className="size-5 ml-2" />
                                </Button>
                            </CardContent>
                        </Card>
                    )}

                    {step === 3 && (
                        <Card className="rounded-3xl border-none shadow-xl shadow-black/5 bg-card">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <ImageIcon className="size-5 text-primary" />
                                    Branding & About
                                </CardTitle>
                                <CardDescription>Tell people more about your shop and add some profile pictures.</CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                <FormField
                                    control={form.control}
                                    name="about"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>About Your Store</FormLabel>
                                            <FormControl>
                                                <Textarea
                                                    placeholder="Tell customers what you sell, your values, and why they should trust you..."
                                                    {...field}
                                                    className="bg-muted/30 border-none rounded-xl min-h-[150px]"
                                                />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />

                                <div className="p-8 border-2 border-dashed border-muted rounded-3xl text-center space-y-4">
                                    <div className="size-16 bg-muted rounded-full flex items-center justify-center mx-auto text-muted-foreground">
                                        <Upload className="size-8" />
                                    </div>
                                    <div className="space-y-1">
                                        <h4 className="font-bold">Wait! Let's build your store first.</h4>
                                        <p className="text-sm text-muted-foreground">You can upload your logo and cover image from the store settings after creation.</p>
                                    </div>
                                </div>

                                <Button type="submit" className="w-full h-14 rounded-2xl text-lg font-bold" disabled={createStoreMutation.isPending}>
                                    {createStoreMutation.isPending ? (
                                        <>
                                            <Loader2 className="size-5 mr-2 animate-spin" />
                                            Launching Store...
                                        </>
                                    ) : (
                                        <>
                                            Launch Store
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
