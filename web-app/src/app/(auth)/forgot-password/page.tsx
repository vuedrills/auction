'use client';

import Link from 'next/link';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation } from '@tanstack/react-query';
import { toast } from 'sonner';
import { Loader2, ArrowLeft } from 'lucide-react';

import { authService, forgotPasswordSchema, type ForgotPasswordInput } from '@/services/auth';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';

export default function ForgotPasswordPage() {
    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<ForgotPasswordInput>({
        resolver: zodResolver(forgotPasswordSchema),
        defaultValues: {
            email: '',
        },
    });

    const forgotPasswordMutation = useMutation({
        mutationFn: authService.forgotPassword,
        onSuccess: () => {
            toast.success('Reset link sent to your email.');
        },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        onError: (error: any) => {
            const message = error.response?.data?.message || 'Failed to send reset link. Please try again.';
            toast.error(message);
        },
    });

    const onSubmit = (data: ForgotPasswordInput) => {
        forgotPasswordMutation.mutate(data);
    };

    return (
        <Card className="border-none shadow-xl">
            <CardHeader className="space-y-1 text-center">
                <CardTitle className="text-2xl font-bold tracking-tight text-primary">
                    Forgot Password
                </CardTitle>
                <CardDescription>
                    Enter your email to reset your password
                </CardDescription>
            </CardHeader>
            <CardContent>
                <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                    <div className="space-y-2">
                        <Label htmlFor="email">Email</Label>
                        <Input
                            id="email"
                            type="email"
                            placeholder="john@example.com"
                            disabled={forgotPasswordMutation.isPending}
                            className={errors.email ? 'border-red-500' : ''}
                            {...register('email')}
                        />
                        {errors.email && (
                            <p className="text-sm text-red-500">{errors.email.message}</p>
                        )}
                    </div>
                    <Button
                        type="submit"
                        className="w-full"
                        disabled={forgotPasswordMutation.isPending}
                    >
                        {forgotPasswordMutation.isPending && (
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        )}
                        Send Reset Link
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
