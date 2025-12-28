'use client';

import { useParams } from 'next/navigation';
import { StoreAnalyticsDashboard } from '@/features/analytics/components/StoreAnalyticsDashboard';
import { Button } from '@/components/ui/button';
import { ArrowLeft } from 'lucide-react';
import { useRouter } from 'next/navigation';

export default function StoreDetailsPage() {
    const params = useParams();
    const router = useRouter();
    const id = params?.id as string;

    return (
        <div className="space-y-6">
            <div className="flex items-center gap-4">
                <Button variant="ghost" size="icon" onClick={() => router.back()}>
                    <ArrowLeft className="h-4 w-4" />
                </Button>
                <div>
                    <h1 className="text-2xl font-bold tracking-tight">Store Details</h1>
                    <p className="text-muted-foreground">Store ID: {id}</p>
                </div>
            </div>

            <StoreAnalyticsDashboard storeId={id} />
        </div>
    );
}
