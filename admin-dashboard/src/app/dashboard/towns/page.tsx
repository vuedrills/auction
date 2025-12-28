import { TownTable } from '@/features/towns/components/TownTable';

export default function TownsPage() {
    return (
        <div className="flex flex-col gap-4">
            <div className="flex items-center justify-between">
                <h1 className="text-2xl font-bold tracking-tight">Town Management</h1>
            </div>
            <TownTable />
        </div>
    );
}
