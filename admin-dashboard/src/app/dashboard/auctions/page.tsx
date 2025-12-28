import { AuctionTable } from '@/features/auctions/components/AuctionTable';

export default function AuctionsPage() {
    return (
        <div className="flex flex-col gap-4">
            <div className="flex items-center justify-between">
                <h1 className="text-2xl font-bold tracking-tight">Auction Management</h1>
            </div>
            <AuctionTable />
        </div>
    );
}
