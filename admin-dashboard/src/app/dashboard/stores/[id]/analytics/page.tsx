import { StoreAnalyticsDashboard } from '@/features/analytics/components/StoreAnalyticsDashboard';

export default async function Page(props: { params: Promise<{ id: string }> }) {
    const params = await props.params;
    return (
        <div className="flex flex-col gap-4">
            <h1 className="text-2xl font-bold">Store Analytics</h1>
            <StoreAnalyticsDashboard storeId={params.id} />
        </div>
    );
}
