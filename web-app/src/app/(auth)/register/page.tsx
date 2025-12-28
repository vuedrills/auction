'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation, useQuery } from '@tanstack/react-query';
import { toast } from 'sonner';
import { Eye, EyeOff, Loader2 } from 'lucide-react';

import { authService, registerSchema, type RegisterInput } from '@/services/auth';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';

export default function RegisterPage() {
    const router = useRouter();
    const [showPassword, setShowPassword] = useState(false);

    const {
        register,
        handleSubmit,
        watch,
        setValue,
        formState: { errors },
    } = useForm<RegisterInput>({
        resolver: zodResolver(registerSchema),
        defaultValues: {
            username: '',
            email: '',
            password: '',
            full_name: '',
            home_town_id: '',
            home_suburb_id: '',
        },
    });

    const selectedTownId = watch('home_town_id');

    // Queries
    const { data: towns, isLoading: isLoadingTowns } = useQuery({
        queryKey: ['towns'],
        queryFn: authService.getTowns,
    });

    const { data: suburbs, isLoading: isLoadingSuburbs } = useQuery({
        queryKey: ['suburbs', selectedTownId],
        queryFn: () => authService.getSuburbs(selectedTownId),
        enabled: !!selectedTownId,
    });

    // Reset suburb when town changes
    useEffect(() => {
        setValue('home_suburb_id', '');
    }, [selectedTownId, setValue]);

    const registerMutation = useMutation({
        mutationFn: authService.register,
        onSuccess: () => {
            // Some backends return token on register, some require login after.
            // The prompt says: POST /api/auth/register -> { user, token }
            // So we can auto-login using the simpler login store method if it matches, 
            // but the store expects (user, token, refreshToken).
            // Check if register response has refresh_token. 
            // If not, we might need to rely on the user to login or just set what we have.
            // The prompt says: { user, token }. Missing refresh_token?
            // If missing, I might just redirect to login or try to use what I have.
            // Let's assume for now I'll just redirect to login to be safe unless I see refresh_token.
            // Or I can just check the response type.
            // Actually, if I don't have a refresh token, the interceptor refresh logic might fail later.
            // I'll try to set what I can, or just redirect to login saying "Account created, please login".
            // That's often safer if the register endpoint doesn't return a full session.
            // However, the prompt says "After successful login, redirect to /".
            // It didn't explicitly say "Auto-login after register".
            // I'll toast success and push to login.
            toast.success('Account created successfully! Please sign in.');
            router.push('/login');
        },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        onError: (error: any) => {
            const message = error.response?.data?.message || 'Registration failed. Please try again.';
            toast.error(message);
        },
    });

    const onSubmit = (data: RegisterInput) => {
        registerMutation.mutate(data);
    };

    return (
        <Card className="border-none shadow-xl my-8">
            <CardHeader className="space-y-1 text-center">
                <CardTitle className="text-2xl font-bold tracking-tight text-primary">
                    Create an account
                </CardTitle>
                <CardDescription>
                    Enter your details to get started
                </CardDescription>
            </CardHeader>
            <CardContent>
                <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                    <div className="space-y-2">
                        <Label htmlFor="full_name">Full Name</Label>
                        <Input
                            id="full_name"
                            placeholder="John Doe"
                            disabled={registerMutation.isPending}
                            className={errors.full_name ? 'border-red-500' : ''}
                            {...register('full_name')}
                        />
                        {errors.full_name && (
                            <p className="text-sm text-red-500">{errors.full_name.message}</p>
                        )}
                    </div>

                    <div className="space-y-2">
                        <Label htmlFor="username">Username</Label>
                        <Input
                            id="username"
                            placeholder="johndoe"
                            disabled={registerMutation.isPending}
                            className={errors.username ? 'border-red-500' : ''}
                            {...register('username')}
                        />
                        {errors.username && (
                            <p className="text-sm text-red-500">{errors.username.message}</p>
                        )}
                    </div>

                    <div className="space-y-2">
                        <Label htmlFor="email">Email</Label>
                        <Input
                            id="email"
                            type="email"
                            placeholder="john@example.com"
                            disabled={registerMutation.isPending}
                            className={errors.email ? 'border-red-500' : ''}
                            {...register('email')}
                        />
                        {errors.email && (
                            <p className="text-sm text-red-500">{errors.email.message}</p>
                        )}
                    </div>

                    <div className="space-y-2">
                        <Label htmlFor="password">Password</Label>
                        <div className="relative">
                            <Input
                                id="password"
                                type={showPassword ? 'text' : 'password'}
                                placeholder="Create a password"
                                disabled={registerMutation.isPending}
                                className={errors.password ? 'border-red-500 pr-10' : 'pr-10'}
                                {...register('password')}
                            />
                            <button
                                type="button"
                                onClick={() => setShowPassword(!showPassword)}
                                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                            >
                                {showPassword ? (
                                    <EyeOff className="h-4 w-4" />
                                ) : (
                                    <Eye className="h-4 w-4" />
                                )}
                            </button>
                        </div>
                        {errors.password && (
                            <p className="text-sm text-red-500">{errors.password.message}</p>
                        )}
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <Label htmlFor="home_town_id">Town</Label>
                            <select
                                id="home_town_id"
                                disabled={registerMutation.isPending || isLoadingTowns}
                                className={`flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 ${errors.home_town_id ? 'border-red-500' : ''}`}
                                {...register('home_town_id')}
                            >
                                <option value="">Select Town</option>
                                {towns?.map((town) => (
                                    <option key={town.id} value={town.id}>
                                        {town.name}
                                    </option>
                                ))}
                            </select>
                            {errors.home_town_id && (
                                <p className="text-sm text-red-500">{errors.home_town_id.message}</p>
                            )}
                        </div>

                        <div className="space-y-2">
                            <Label htmlFor="home_suburb_id">Suburb</Label>
                            <select
                                id="home_suburb_id"
                                disabled={registerMutation.isPending || !selectedTownId || isLoadingSuburbs}
                                className={`flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 ${errors.home_suburb_id ? 'border-red-500' : ''}`}
                                {...register('home_suburb_id')}
                            >
                                <option value="">Select Suburb</option>
                                {suburbs?.map((suburb) => (
                                    <option key={suburb.id} value={suburb.id}>
                                        {suburb.name}
                                    </option>
                                ))}
                            </select>
                            {errors.home_suburb_id && (
                                <p className="text-sm text-red-500">{errors.home_suburb_id.message}</p>
                            )}
                        </div>
                    </div>

                    <Button
                        type="submit"
                        className="w-full"
                        disabled={registerMutation.isPending}
                    >
                        {registerMutation.isPending && (
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        )}
                        Sign Up
                    </Button>
                </form>
            </CardContent>
            <CardFooter className="flex flex-col space-y-2 text-center text-sm">
                <div className="text-gray-500">
                    Already have an account?{' '}
                    <Link
                        href="/login"
                        className="font-semibold text-primary hover:underline"
                    >
                        Sign in
                    </Link>
                </div>
            </CardFooter>
        </Card>
    );
}
