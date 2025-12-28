'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
    Search,
    MapPin,
    X,
    Check,
    Loader2,
    ChevronLeft,
    ChevronRight
} from 'lucide-react';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogDescription
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { useTownStore } from '@/stores/townStore';
import { useUIStore } from '@/stores/uiStore';
import { authService } from '@/services/auth';
import { cn } from '@/lib/utils';

export function TownFilterModal() {
    const { townFilterOpen, setTownFilterOpen } = useUIStore();
    const {
        selectedTown,
        selectedSuburb,
        setSelectedTown,
        setSelectedSuburb,
        clearSelection
    } = useTownStore();

    const [searchTerm, setSearchTerm] = useState('');
    const [view, setView] = useState<'towns' | 'suburbs'>('towns');

    // Queries
    const { data: towns, isLoading: isLoadingTowns } = useQuery({
        queryKey: ['towns'],
        queryFn: authService.getTowns,
        enabled: townFilterOpen,
    });

    const { data: suburbs, isLoading: isLoadingSuburbs } = useQuery({
        queryKey: ['suburbs', selectedTown?.id],
        queryFn: () => authService.getSuburbs(selectedTown!.id),
        enabled: !!selectedTown && view === 'suburbs',
    });

    const filteredTowns = towns?.filter(t =>
        t.name.toLowerCase().includes(searchTerm.toLowerCase())
    ) || [];

    const handleTownSelect = (town: any) => {
        setSelectedTown(town);
        setView('suburbs');
        setSearchTerm('');
    };

    const handleSuburbSelect = (suburb: any) => {
        setSelectedSuburb(suburb);
        setTownFilterOpen(false);
        setView('towns');
    };

    const handleClose = () => {
        setTownFilterOpen(false);
        setTimeout(() => {
            setView('towns');
            setSearchTerm('');
        }, 300);
    };

    return (
        <Dialog open={townFilterOpen} onOpenChange={handleClose}>
            <DialogContent className="sm:max-w-[425px] p-0 overflow-hidden gap-0">
                <DialogHeader className="p-6 pb-2">
                    <DialogTitle className="text-xl font-bold flex items-center gap-2">
                        <MapPin className="size-5 text-primary" />
                        {view === 'towns' ? 'Select Town' : `Suburbs in ${selectedTown?.name}`}
                    </DialogTitle>
                    <DialogDescription>
                        {view === 'towns'
                            ? 'Choose a town to filter auctions near you'
                            : 'Optionally select a specific suburb'}
                    </DialogDescription>
                </DialogHeader>

                <div className="p-4 border-b">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
                        <Input
                            placeholder={view === 'towns' ? "Search towns..." : "Search suburbs..."}
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="pl-9 h-11 bg-muted/50 border-none rounded-xl"
                        />
                    </div>
                </div>

                <div className="overflow-y-auto h-[400px]">
                    <div className="p-2">
                        {view === 'towns' ? (
                            <>
                                <Button
                                    variant="ghost"
                                    className="w-full justify-between h-12 px-4 rounded-xl mb-1"
                                    onClick={() => {
                                        clearSelection();
                                        setTownFilterOpen(false);
                                    }}
                                >
                                    <span className="font-semibold">All of Zimbabwe (National)</span>
                                    {!selectedTown && <Check className="size-4 text-primary" />}
                                </Button>

                                {isLoadingTowns ? (
                                    <div className="flex items-center justify-center py-8">
                                        <Loader2 className="size-6 animate-spin text-primary opacity-50" />
                                    </div>
                                ) : filteredTowns.map((town) => (
                                    <Button
                                        key={town.id}
                                        variant="ghost"
                                        className={cn(
                                            "w-full justify-between h-12 px-4 rounded-xl hover:bg-primary/5 transition-colors",
                                            selectedTown?.id === town.id && "bg-primary/5 text-primary"
                                        )}
                                        onClick={() => handleTownSelect(town)}
                                    >
                                        <span className="font-medium">{town.name}</span>
                                        {selectedTown?.id === town.id ? (
                                            <Check className="size-4" />
                                        ) : (
                                            <ChevronRight className="size-4 opacity-30" />
                                        )}
                                    </Button>
                                ))}
                            </>
                        ) : (
                            <>
                                <Button
                                    variant="ghost"
                                    className="w-full justify-start h-12 px-4 rounded-xl mb-1 gap-2 text-muted-foreground"
                                    onClick={() => setView('towns')}
                                >
                                    <ChevronLeft className="size-4" />
                                    Back to Towns
                                </Button>

                                <Button
                                    variant="ghost"
                                    className="w-full justify-between h-12 px-4 rounded-xl mb-1"
                                    onClick={() => handleSuburbSelect(null)}
                                >
                                    <span className="font-semibold text-primary">All of {selectedTown?.name}</span>
                                    {!selectedSuburb && <Check className="size-4 text-primary" />}
                                </Button>

                                {isLoadingSuburbs ? (
                                    <div className="flex items-center justify-center py-8">
                                        <Loader2 className="size-6 animate-spin text-primary opacity-50" />
                                    </div>
                                ) : suburbs?.map((suburb: any) => (
                                    <Button
                                        key={suburb.id}
                                        variant="ghost"
                                        className={cn(
                                            "w-full justify-between h-12 px-4 rounded-xl hover:bg-primary/5 transition-colors",
                                            selectedSuburb?.id === suburb.id && "bg-primary/5 text-primary"
                                        )}
                                        onClick={() => handleSuburbSelect(suburb)}
                                    >
                                        <span className="font-medium">{suburb.name}</span>
                                        {selectedSuburb?.id === suburb.id && <Check className="size-4" />}
                                    </Button>
                                ))}
                            </>
                        )}
                    </div>
                </div>

                <div className="p-4 bg-muted/20 border-t flex justify-end gap-3">
                    <Button variant="ghost" onClick={handleClose}>Cancel</Button>
                    <Button
                        disabled={view === 'suburbs' && !selectedSuburb}
                        onClick={() => {
                            if (view === 'suburbs') handleSuburbSelect(selectedSuburb);
                            else setTownFilterOpen(false);
                        }}
                    >
                        Apply Filter
                    </Button>
                </div>
            </DialogContent>
        </Dialog>
    );
}
