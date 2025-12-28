'use client';

import { useEffect } from 'react';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';
import { Button } from '@/components/ui/button';
import Link from 'next/link';

export default function Error({
    error,
    reset,
}: {
    error: Error & { digest?: string };
    reset: () => void;
}) {
    useEffect(() => {
        // Log error to an error reporting service in production
        console.error('Application error:', error);
    }, [error]);

    return (
        <div className="min-h-[60vh] flex items-center justify-center p-4">
            <div className="text-center max-w-md mx-auto">
                <div className="inline-flex items-center justify-center size-20 rounded-full bg-destructive/10 mb-6">
                    <AlertTriangle className="size-10 text-destructive" />
                </div>

                <h1 className="text-2xl font-bold mb-2">Something went wrong</h1>
                <p className="text-muted-foreground mb-8">
                    We encountered an unexpected error. Please try again or return to the home page.
                </p>

                <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
                    <Button onClick={reset} variant="default">
                        <RefreshCw className="size-4 mr-2" />
                        Try Again
                    </Button>
                    <Link href="/">
                        <Button variant="outline">
                            <Home className="size-4 mr-2" />
                            Go Home
                        </Button>
                    </Link>
                </div>

                {error.digest && (
                    <p className="mt-8 text-xs text-muted-foreground">
                        Error ID: {error.digest}
                    </p>
                )}
            </div>
        </div>
    );
}
