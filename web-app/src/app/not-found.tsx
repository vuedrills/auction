import Link from 'next/link';
import { Home, Search, ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function NotFound() {
    return (
        <div className="min-h-[60vh] flex items-center justify-center p-4">
            <div className="text-center max-w-md mx-auto">
                <div className="text-8xl font-black text-primary/20 mb-4">404</div>

                <h1 className="text-2xl font-bold mb-2">Page not found</h1>
                <p className="text-muted-foreground mb-8">
                    The page you're looking for doesn't exist or has been moved.
                </p>

                <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
                    <Link href="/">
                        <Button variant="default">
                            <Home className="size-4 mr-2" />
                            Go Home
                        </Button>
                    </Link>
                    <Link href="/shops">
                        <Button variant="outline">
                            <Search className="size-4 mr-2" />
                            Browse Shops
                        </Button>
                    </Link>
                </div>
            </div>
        </div>
    );
}
