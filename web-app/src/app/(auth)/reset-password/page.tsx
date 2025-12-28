'use client';

import { useState, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation } from '@tanstack/react-query';
import { toast } from 'sonner';
import { Eye, EyeOff, Loader2, ArrowLeft } from 'lucide-react';

import { authService, resetPasswordSchema, type ResetPasswordInput } from '@/services/auth';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';

function ResetPasswordForm() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const token = searchParams.get('token');

    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);

    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<ResetPasswordInput>({
        resolver: zodResolver(resetPasswordSchema),
        defaultValues: {
            token: token || '',
            new_password: '',
            confirmPassword: '',
        },
    });

    const resetPasswordMutation = useMutation({
        mutationFn: (data: ResetPasswordInput) => {
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            const { confirmPassword, ...rest } = data;
            return authService.resetPassword(rest);
        },
        onSuccess: () => {
            toast.success('Password reset successfully! Please log in.');
            router.push('/login');
        },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        onError: (error: any) => {
            const message = error.response?.data?.message || 'Failed to reset password. Token may be invalid or expired.';
            toast.error(message);
        },
    });

    const onSubmit = (data: ResetPasswordInput) => {
        if (!token) {
            toast.error('Missing reset token.');
            return;
        }
        resetPasswordMutation.mutate(data);
    };

    if (!token) {
        return (
            <Card className="border-none shadow-xl">
                <CardHeader className="text-center">
                    <CardTitle className="text-xl font-bold text-red-500">Invalid Link</CardTitle>
                    <CardDescription>
                        This password reset link is invalid or missing the token.
                    </CardDescription>
                </CardHeader>
                <CardFooter className="flex justify-center">
                    <Link
                        href="/login"
                        className="flex items-center text-sm font-medium text-gray-500 hover:text-gray-700"
                    >
                        <ArrowLeft className="mr-2 h-4 w-4" />
                        Back to Sign In
                    </Link>
                </CardFooter>
            </Card>
        );
    }

    return (
        <Card className="border-none shadow-xl">
            <CardHeader className="space-y-1 text-center">
                <CardTitle className="text-2xl font-bold tracking-tight text-primary">
                    Reset Password
                </CardTitle>
                <CardDescription>
                    Enter your new password below
                </CardDescription>
            </CardHeader>
            <CardContent>
                <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                    <input type="hidden" {...register('token')} />

                    <div className="space-y-2">
                        <Label htmlFor="new_password">New Password</Label>
                        <div className="relative">
                            <Input
                                id="new_password"
                                type={showPassword ? 'text' : 'password'}
                                placeholder="Enter new password"
                                disabled={resetPasswordMutation.isPending}
                                className={errors.new_password ? 'border-red-500 pr-10' : 'pr-10'}
                                {...register('new_password')}
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
                        {errors.new_password && (
                            <p className="text-sm text-red-500">{errors.new_password.message}</p>
                        )}
                    </div>

                    <div className="space-y-2">
                        <Label htmlFor="confirmPassword">Confirm Password</Label>
                        <div className="relative">
                            <Input
                                id="confirmPassword"
                                type={showConfirmPassword ? 'text' : 'password'}
                                placeholder="Confirm new password"
                                disabled={resetPasswordMutation.isPending}
                                className={errors.confirmPassword ? 'border-red-500 pr-10' : 'pr-10'}
                                {...register('confirmPassword')}
                            />
                            <button
                                type="button"
                                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                            >
                                {showConfirmPassword ? (
                                    <EyeOff className="h-4 w-4" />
                                ) : (
                                    <Eye className="h-4 w-4" />
                                )}
                            </button>
                        </div>
                        {errors.confirmPassword && (
                            <p className="text-sm text-red-500">{errors.confirmPassword.message}</p>
                        )}
                    </div>

                    <Button
                        type="submit"
                        className="w-full"
                        disabled={resetPasswordMutation.isPending}
                    >
                        {resetPasswordMutation.isPending && (
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        )}
                        Reset Password
                    </Button>
                </form>
            </CardContent>
            <CardFooter className="flex justify-center">
                <Link
                    href="/login"
                    className="flex items-center text-sm font-medium text-gray-500 hover:text-gray-700"
                >
                    <ArrowLeft className="mr-2 h-4 w-4" />
                    Back to Sign In
                </Link>
            </CardFooter>
        </Card>
    );
}

export default function ResetPasswordPage() {
    return (
        <Suspense fallback={<div className="flex justify-center"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>}>
            <ResetPasswordForm />
        </Suspense>
    );
}
