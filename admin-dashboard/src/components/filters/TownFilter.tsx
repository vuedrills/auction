'use client';

import { useQuery } from '@tanstack/react-query';
import { getTowns, getTownWithSuburbs } from '@/features/towns/townService';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import { MapPin } from 'lucide-react';

interface TownFilterProps {
    selectedTown: string | null;
    selectedSuburb: string | null;
    onTownChange: (townId: string | null) => void;
    onSuburbChange: (suburbId: string | null) => void;
    showSuburb?: boolean;
    className?: string;
}

export function TownFilter({
    selectedTown,
    selectedSuburb,
    onTownChange,
    onSuburbChange,
    showSuburb = true,
    className = '',
}: TownFilterProps) {
    const { data: townsData } = useQuery({
        queryKey: ['towns'],
        queryFn: getTowns,
    });

    const { data: suburbsData } = useQuery({
        queryKey: ['town-suburbs', selectedTown],
        queryFn: () => getTownWithSuburbs(selectedTown!),
        enabled: !!selectedTown && showSuburb,
    });

    const towns = townsData?.towns || [];
    const suburbs = suburbsData?.suburbs || [];

    return (
        <div className={`flex items-center gap-2 ${className}`}>
            <MapPin className="h-4 w-4 text-muted-foreground" />
            <Select
                value={selectedTown || 'all'}
                onValueChange={(value) => {
                    const newTown = value === 'all' ? null : value;
                    onTownChange(newTown);
                    onSuburbChange(null); // Reset suburb when town changes
                }}
            >
                <SelectTrigger className="w-[180px]">
                    <SelectValue placeholder="All Towns" />
                </SelectTrigger>
                <SelectContent>
                    <SelectItem value="all">All Towns</SelectItem>
                    {towns.map((town) => (
                        <SelectItem key={town.id} value={town.id}>
                            {town.name} ({town.active_auctions || 0})
                        </SelectItem>
                    ))}
                </SelectContent>
            </Select>

            {showSuburb && selectedTown && (
                <Select
                    value={selectedSuburb || 'all'}
                    onValueChange={(value) => onSuburbChange(value === 'all' ? null : value)}
                >
                    <SelectTrigger className="w-[180px]">
                        <SelectValue placeholder="All Suburbs" />
                    </SelectTrigger>
                    <SelectContent>
                        <SelectItem value="all">All Suburbs</SelectItem>
                        {suburbs.map((suburb: any) => (
                            <SelectItem key={suburb.id} value={suburb.id}>
                                {suburb.name}
                            </SelectItem>
                        ))}
                    </SelectContent>
                </Select>
            )}
        </div>
    );
}
