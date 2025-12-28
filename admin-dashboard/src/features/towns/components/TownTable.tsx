'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getTowns, getTownWithSuburbs, createTown, deleteTown, createSuburb, deleteSuburb } from '@/features/towns/townService';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Loader2, Plus, Trash2, ChevronDown, ChevronRight, MapPin } from 'lucide-react';
import { format } from 'date-fns';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogFooter,
} from '@/components/ui/dialog';
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';

export function TownTable() {
    const queryClient = useQueryClient();
    const [expandedTown, setExpandedTown] = useState<string | null>(null);
    const [isAddTownOpen, setIsAddTownOpen] = useState(false);
    const [isAddSuburbOpen, setIsAddSuburbOpen] = useState(false);
    const [deleteConfirm, setDeleteConfirm] = useState<{ type: 'town' | 'suburb'; id: string; townId?: string; name: string } | null>(null);

    const [townForm, setTownForm] = useState({ name: '', state: '', country: 'Zimbabwe' });
    const [suburbForm, setSuburbForm] = useState({ name: '', zip_code: '' });

    const { data, isLoading, isError } = useQuery({
        queryKey: ['towns'],
        queryFn: getTowns,
    });

    const { data: expandedData } = useQuery({
        queryKey: ['town-suburbs', expandedTown],
        queryFn: () => getTownWithSuburbs(expandedTown!),
        enabled: !!expandedTown,
    });

    const createTownMutation = useMutation({
        mutationFn: createTown,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['towns'] });
            setIsAddTownOpen(false);
            setTownForm({ name: '', state: '', country: 'Zimbabwe' });
        },
        onError: (err: any) => alert('Error: ' + (err.response?.data?.error || err.message)),
    });

    const deleteTownMutation = useMutation({
        mutationFn: deleteTown,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['towns'] });
            setDeleteConfirm(null);
        },
        onError: (err: any) => alert('Error: ' + (err.response?.data?.error || err.message)),
    });

    const createSuburbMutation = useMutation({
        mutationFn: ({ townId, data }: { townId: string; data: any }) => createSuburb(townId, data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['towns'] });
            queryClient.invalidateQueries({ queryKey: ['town-suburbs', expandedTown] });
            setIsAddSuburbOpen(false);
            setSuburbForm({ name: '', zip_code: '' });
        },
        onError: (err: any) => alert('Error: ' + (err.response?.data?.error || err.message)),
    });

    const deleteSuburbMutation = useMutation({
        mutationFn: ({ townId, suburbId }: { townId: string; suburbId: string }) => deleteSuburb(townId, suburbId),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['towns'] });
            queryClient.invalidateQueries({ queryKey: ['town-suburbs', expandedTown] });
            setDeleteConfirm(null);
        },
        onError: (err: any) => alert('Error: ' + (err.response?.data?.error || err.message)),
    });

    const handleAddTown = (e: React.FormEvent) => {
        e.preventDefault();
        createTownMutation.mutate(townForm);
    };

    const handleAddSuburb = (e: React.FormEvent) => {
        e.preventDefault();
        if (expandedTown) {
            createSuburbMutation.mutate({ townId: expandedTown, data: suburbForm });
        }
    };

    const handleDelete = () => {
        if (!deleteConfirm) return;
        if (deleteConfirm.type === 'town') {
            deleteTownMutation.mutate(deleteConfirm.id);
        } else {
            deleteSuburbMutation.mutate({ townId: deleteConfirm.townId!, suburbId: deleteConfirm.id });
        }
    };

    if (isLoading) return <div className="flex justify-center p-8"><Loader2 className="animate-spin text-primary" /></div>;
    if (isError) return <div className="p-8 text-destructive border border-destructive/20 rounded-md bg-destructive/10">Error loading towns.</div>;

    return (
        <>
            <div className="flex justify-end mb-4">
                <Button onClick={() => setIsAddTownOpen(true)}>
                    <Plus className="mr-2 h-4 w-4" />
                    Add Town
                </Button>
            </div>

            <div className="rounded-md border bg-card shadow-sm">
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead className="w-[40px]"></TableHead>
                            <TableHead>Town Name</TableHead>
                            <TableHead>State</TableHead>
                            <TableHead>Country</TableHead>
                            <TableHead>Suburbs</TableHead>
                            <TableHead>Active Auctions</TableHead>
                            <TableHead>Created At</TableHead>
                            <TableHead className="text-right">Actions</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {data?.towns?.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={8} className="text-center h-24 text-muted-foreground">
                                    No towns found.
                                </TableCell>
                            </TableRow>
                        ) : (
                            data?.towns?.map((town) => (
                                <>
                                    <TableRow key={town.id} className="cursor-pointer hover:bg-muted/50" onClick={() => setExpandedTown(expandedTown === town.id ? null : town.id)}>
                                        <TableCell>
                                            {expandedTown === town.id ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
                                        </TableCell>
                                        <TableCell className="font-medium">{town.name}</TableCell>
                                        <TableCell>{town.state || '-'}</TableCell>
                                        <TableCell>{town.country || '-'}</TableCell>
                                        <TableCell><Badge variant="secondary">{town.total_suburbs ?? 0}</Badge></TableCell>
                                        <TableCell><Badge variant="outline">{town.active_auctions ?? 0}</Badge></TableCell>
                                        <TableCell className="text-sm text-muted-foreground">
                                            {town.created_at ? format(new Date(town.created_at), 'MMM d, yyyy') : '-'}
                                        </TableCell>
                                        <TableCell className="text-right" onClick={(e) => e.stopPropagation()}>
                                            <Button variant="ghost" size="icon" className="text-destructive" onClick={() => setDeleteConfirm({ type: 'town', id: town.id, name: town.name })}>
                                                <Trash2 className="h-4 w-4" />
                                            </Button>
                                        </TableCell>
                                    </TableRow>
                                    {expandedTown === town.id && (
                                        <TableRow>
                                            <TableCell colSpan={8} className="bg-muted/30 p-4">
                                                <div className="flex justify-between items-center mb-3">
                                                    <h4 className="font-medium flex items-center gap-2">
                                                        <MapPin className="h-4 w-4" />
                                                        Suburbs in {town.name}
                                                    </h4>
                                                    <Button size="sm" variant="outline" onClick={() => setIsAddSuburbOpen(true)}>
                                                        <Plus className="mr-2 h-3 w-3" />
                                                        Add Suburb
                                                    </Button>
                                                </div>
                                                {expandedData?.suburbs?.length === 0 ? (
                                                    <p className="text-muted-foreground text-sm">No suburbs in this town.</p>
                                                ) : (
                                                    <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2">
                                                        {expandedData?.suburbs?.map((suburb: any) => (
                                                            <div key={suburb.id} className="flex items-center justify-between bg-background p-2 rounded border">
                                                                <div>
                                                                    <span className="font-medium text-sm">{suburb.name}</span>
                                                                    {suburb.zip_code && <span className="text-xs text-muted-foreground ml-2">({suburb.zip_code})</span>}
                                                                </div>
                                                                <Button variant="ghost" size="icon" className="h-6 w-6 text-destructive" onClick={() => setDeleteConfirm({ type: 'suburb', id: suburb.id, townId: town.id, name: suburb.name })}>
                                                                    <Trash2 className="h-3 w-3" />
                                                                </Button>
                                                            </div>
                                                        ))}
                                                    </div>
                                                )}
                                            </TableCell>
                                        </TableRow>
                                    )}
                                </>
                            ))
                        )}
                    </TableBody>
                </Table>
            </div>

            {/* Add Town Dialog */}
            <Dialog open={isAddTownOpen} onOpenChange={setIsAddTownOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Add New Town</DialogTitle>
                        <DialogDescription>Create a new town for the platform.</DialogDescription>
                    </DialogHeader>
                    <form onSubmit={handleAddTown} className="space-y-4">
                        <div className="space-y-2">
                            <label className="text-sm font-medium">Town Name *</label>
                            <Input required value={townForm.name} onChange={e => setTownForm({ ...townForm, name: e.target.value })} placeholder="e.g. Harare" />
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <label className="text-sm font-medium">State/Province</label>
                                <Select
                                    value={townForm.state}
                                    onValueChange={value => setTownForm({ ...townForm, state: value })}
                                >
                                    <SelectTrigger>
                                        <SelectValue placeholder="Select State" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        {Array.from(new Set(data?.towns?.map((t: any) => t.state).filter(Boolean) || [])).map((state: any) => (
                                            <SelectItem key={state} value={state}>{state}</SelectItem>
                                        ))}
                                        <SelectItem value="new">+ Add New...</SelectItem>
                                    </SelectContent>
                                </Select>
                                {townForm.state === 'new' && (
                                    <Input
                                        className="mt-2"
                                        placeholder="Enter new state name"
                                        onChange={e => setTownForm({ ...townForm, state: e.target.value })}
                                    />
                                )}
                            </div>
                            <div className="space-y-2">
                                <label className="text-sm font-medium">Country</label>
                                <Input value={townForm.country} onChange={e => setTownForm({ ...townForm, country: e.target.value })} />
                            </div>
                        </div>
                        <DialogFooter>
                            <Button type="submit" disabled={createTownMutation.isPending}>
                                {createTownMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                Create Town
                            </Button>
                        </DialogFooter>
                    </form>
                </DialogContent>
            </Dialog>

            {/* Add Suburb Dialog */}
            <Dialog open={isAddSuburbOpen} onOpenChange={setIsAddSuburbOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Add New Suburb</DialogTitle>
                        <DialogDescription>Add a suburb to {data?.towns?.find(t => t.id === expandedTown)?.name}</DialogDescription>
                    </DialogHeader>
                    <form onSubmit={handleAddSuburb} className="space-y-4">
                        <div className="space-y-2">
                            <label className="text-sm font-medium">Suburb Name *</label>
                            <Input required value={suburbForm.name} onChange={e => setSuburbForm({ ...suburbForm, name: e.target.value })} placeholder="e.g. Avondale" />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm font-medium">Zip/Postal Code</label>
                            <Input value={suburbForm.zip_code} onChange={e => setSuburbForm({ ...suburbForm, zip_code: e.target.value })} placeholder="Optional" />
                        </div>
                        <DialogFooter>
                            <Button type="submit" disabled={createSuburbMutation.isPending}>
                                {createSuburbMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                Add Suburb
                            </Button>
                        </DialogFooter>
                    </form>
                </DialogContent>
            </Dialog>

            {/* Delete Confirmation */}
            <AlertDialog open={!!deleteConfirm} onOpenChange={() => setDeleteConfirm(null)}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>Delete {deleteConfirm?.type === 'town' ? 'Town' : 'Suburb'}</AlertDialogTitle>
                        <AlertDialogDescription>
                            Are you sure you want to delete "{deleteConfirm?.name}"?
                            {deleteConfirm?.type === 'town' && ' This will also delete all suburbs within this town.'}
                            This action cannot be undone.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>Cancel</AlertDialogCancel>
                        <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                            {(deleteTownMutation.isPending || deleteSuburbMutation.isPending) && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Delete
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </>
    );
}
