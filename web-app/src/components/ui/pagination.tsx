'use client';

import { ChevronLeft, ChevronRight, MoreHorizontal } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface PaginationProps {
    currentPage: number;
    totalPages: number;
    onPageChange: (page: number) => void;
    className?: string;
    showInfo?: boolean;
    totalItems?: number;
    itemsPerPage?: number;
}

export function Pagination({
    currentPage,
    totalPages,
    onPageChange,
    className,
    showInfo = true,
    totalItems,
    itemsPerPage = 20,
}: PaginationProps) {
    if (totalPages <= 1) return null;

    // Calculate page numbers to show
    const getPageNumbers = () => {
        const pages: (number | 'ellipsis')[] = [];
        const showEllipsis = totalPages > 7;

        if (!showEllipsis) {
            // Show all pages if 7 or fewer
            for (let i = 1; i <= totalPages; i++) {
                pages.push(i);
            }
        } else {
            // Always show first page
            pages.push(1);

            if (currentPage > 3) {
                pages.push('ellipsis');
            }

            // Show pages around current
            const start = Math.max(2, currentPage - 1);
            const end = Math.min(totalPages - 1, currentPage + 1);

            for (let i = start; i <= end; i++) {
                pages.push(i);
            }

            if (currentPage < totalPages - 2) {
                pages.push('ellipsis');
            }

            // Always show last page
            if (totalPages > 1) {
                pages.push(totalPages);
            }
        }

        return pages;
    };

    const pages = getPageNumbers();
    const startItem = (currentPage - 1) * itemsPerPage + 1;
    const endItem = Math.min(currentPage * itemsPerPage, totalItems || 0);

    return (
        <div className={cn('flex flex-col sm:flex-row items-center justify-between gap-4', className)}>
            {/* Info */}
            {showInfo && totalItems !== undefined && (
                <p className="text-sm text-muted-foreground">
                    Showing <span className="font-medium text-foreground">{startItem}</span> to{' '}
                    <span className="font-medium text-foreground">{endItem}</span> of{' '}
                    <span className="font-medium text-foreground">{totalItems}</span> results
                </p>
            )}

            {/* Controls */}
            <div className="flex items-center gap-1">
                {/* Previous */}
                <Button
                    variant="outline"
                    size="icon"
                    className="size-9"
                    onClick={() => onPageChange(currentPage - 1)}
                    disabled={currentPage === 1}
                >
                    <ChevronLeft className="size-4" />
                    <span className="sr-only">Previous page</span>
                </Button>

                {/* Page Numbers */}
                <div className="flex items-center gap-1">
                    {pages.map((page, index) => {
                        if (page === 'ellipsis') {
                            return (
                                <div
                                    key={`ellipsis-${index}`}
                                    className="size-9 flex items-center justify-center text-muted-foreground"
                                >
                                    <MoreHorizontal className="size-4" />
                                </div>
                            );
                        }

                        return (
                            <Button
                                key={page}
                                variant={currentPage === page ? 'default' : 'outline'}
                                size="icon"
                                className={cn(
                                    'size-9',
                                    currentPage === page && 'pointer-events-none'
                                )}
                                onClick={() => onPageChange(page)}
                            >
                                {page}
                            </Button>
                        );
                    })}
                </div>

                {/* Next */}
                <Button
                    variant="outline"
                    size="icon"
                    className="size-9"
                    onClick={() => onPageChange(currentPage + 1)}
                    disabled={currentPage === totalPages}
                >
                    <ChevronRight className="size-4" />
                    <span className="sr-only">Next page</span>
                </Button>
            </div>
        </div>
    );
}

// Simple pagination for mobile/compact views
export function SimplePagination({
    currentPage,
    totalPages,
    onPageChange,
    className,
}: Omit<PaginationProps, 'showInfo' | 'totalItems' | 'itemsPerPage'>) {
    if (totalPages <= 1) return null;

    return (
        <div className={cn('flex items-center justify-center gap-4', className)}>
            <Button
                variant="outline"
                size="sm"
                onClick={() => onPageChange(currentPage - 1)}
                disabled={currentPage === 1}
            >
                <ChevronLeft className="size-4 mr-1" />
                Previous
            </Button>

            <span className="text-sm text-muted-foreground">
                Page {currentPage} of {totalPages}
            </span>

            <Button
                variant="outline"
                size="sm"
                onClick={() => onPageChange(currentPage + 1)}
                disabled={currentPage === totalPages}
            >
                Next
                <ChevronRight className="size-4 ml-1" />
            </Button>
        </div>
    );
}
