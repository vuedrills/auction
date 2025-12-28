import { StoreTable } from '@/features/stores/components/StoreTable';

export default function StoresPage() {
    return (
        <div className="flex flex-col gap-4">
            <div className="flex items-center justify-between">
                <h1 className="text-2xl font-bold tracking-tight">Store Management</h1>
            </div>
            <StoreTable />
        </div>
    );
}
