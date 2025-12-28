'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation } from '@tanstack/react-query';
import { toast } from 'sonner';
import { Eye, EyeOff, Loader2 } from 'lucide-react';

import { authService, loginSchema, type LoginInput } from '@/services/auth';
import { useAuthStore } from '@/stores/authStore';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';

export default function LoginPage() {
    const router = useRouter();
    const loginStore = useAuthStore((state) => state.login);
    const [showPassword, setShowPassword] = useState(false);

    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<LoginInput>({
        resolver: zodResolver(loginSchema),
        defaultValues: {
            email: '',
            password: '',
        },
    });

    const loginMutation = useMutation({
        mutationFn: authService.login,
        onSuccess: (data) => {
            loginStore(data.user, data.token, data.refresh_token);
            toast.success('Welcome back!');
            router.push('/');
        },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        onError: (error: any) => {
            const message = error.response?.data?.message || 'Invalid credentials. Please try again.';
            toast.error(message);
        },
    });

    const onSubmit = (data: LoginInput) => {
        loginMutation.mutate(data);
    };

    return (
        <Card className="border-none shadow-xl">
            <CardHeader className="space-y-1 text-center">
                <CardTitle className="text-2xl font-bold tracking-tight text-primary">
                    Welcome back
                </CardTitle>
                <CardDescription>
                    Enter your credentials to access your account
                </CardDescription>
            </CardHeader>
            <CardContent>
                <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                    <div className="space-y-2">
                        <Label htmlFor="email">Username or Email</Label>
                        <Input
                            id="email"
                            placeholder="Enter your username or email"
                            disabled={loginMutation.isPending}
                            className={errors.email ? 'border-red-500' : ''}
                            {...register('email')}
                        />
                        {errors.email && (
                            <p className="text-sm text-red-500">{errors.email.message}</p>
                        )}
                    </div>
                    <div className="space-y-2">
                        <div className="flex items-center justify-between">
                            <Label htmlFor="password">Password</Label>
                            <Link
                                href="/forgot-password"
                                className="text-sm font-medium text-primary hover:underline"
                            >
                                Forgot password?
                            </Link>
                        </div>
                        <div className="relative">
                            <Input
                                id="password"
                                type={showPassword ? 'text' : 'password'}
                                placeholder="Enter your password"
                                disabled={loginMutation.isPending}
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
                    <Button
                        type="submit"
                        className="w-full"
                        disabled={loginMutation.isPending}
                    >
                        {loginMutation.isPending && (
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        )}
                        Sign In
                    </Button>
                </form>
            </CardContent>
            <CardFooter className="flex flex-col space-y-2 text-center text-sm">
                <div className="text-gray-500">
                    Don&apos;t have an account?{' '}
                    <Link
                        href="/register"
                        className="font-semibold text-primary hover:underline"
                    >
                        Sign up
                    </Link>
                </div>
            </CardFooter>
        </Card>
    );
}
