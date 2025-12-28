'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
    MapPin,
    ChevronDown,
    ChevronRight,
    Smartphone,
    Car,
    Home,
    Shirt,
    Gem,
    Briefcase,
    Dumbbell,
    Baby,
    TreePine,
    Grid3X3
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { useTownStore } from '@/stores/townStore';
import { useUIStore } from '@/stores/uiStore';
import { cn } from '@/lib/utils';

// Category icons mapping
const categoryIcons: Record<string, React.ElementType> = {
    electronics: Smartphone,
    vehicles: Car,
    property: Home,
    fashion: Shirt,
    jewelry: Gem,
    services: Briefcase,
    sports: Dumbbell,
    kids: Baby,
    outdoors: TreePine,
};

interface Category {
    id: string;
    name: string;
    slug: string;
    icon?: string;
    count?: number;
}

interface SidebarProps {
    categories?: Category[];
}

export function Sidebar({ categories = [] }: SidebarProps) {
    const pathname = usePathname();
    const { selectedTown, selectedSuburb } = useTownStore();
    const { setTownFilterOpen } = useUIStore();

    // Mock categories for now - will be fetched from API
    const defaultCategories: Category[] = categories.length > 0 ? categories : [
        { id: '1', name: 'Electronics', slug: 'electronics', count: 45 },
        { id: '2', name: 'Vehicles', slug: 'vehicles', count: 23 },
        { id: '3', name: 'Property', slug: 'property', count: 12 },
        { id: '4', name: 'Fashion', slug: 'fashion', count: 67 },
        { id: '5', name: 'Jewelry', slug: 'jewelry', count: 8 },
        { id: '6', name: 'Services', slug: 'services', count: 15 },
        { id: '7', name: 'Sports', slug: 'sports', count: 19 },
        { id: '8', name: 'Kids', slug: 'kids', count: 31 },
    ];

    return (
        <aside className="w-64 border-r bg-sidebar h-[calc(100vh-4rem)] sticky top-16 overflow-y-auto hidden lg:block">
            <div className="p-4 space-y-6">
                {/* Location Filter */}
                <div>
                    <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">
                        Location
                    </h3>
                    <Button
                        variant="outline"
                        className="w-full justify-between"
                        onClick={() => setTownFilterOpen(true)}
                    >
                        <div className="flex items-center gap-2">
                            <MapPin className="size-4 text-primary" />
                            <span className="truncate">
                                {selectedTown?.name || 'All Towns'}
                            </span>
                        </div>
                        <ChevronDown className="size-4 text-muted-foreground" />
                    </Button>
                    {selectedSuburb && (
                        <p className="text-xs text-muted-foreground mt-1 ml-6">
                            {selectedSuburb.name}
                        </p>
                    )}
                </div>

                <Separator />

                {/* Categories */}
                <div>
                    <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">
                        Categories
                    </h3>
                    <nav className="space-y-1">
                        <Link href="/">
                            <Button
                                variant={pathname === '/' ? 'secondary' : 'ghost'}
                                className={cn(
                                    "w-full justify-between",
                                    pathname === '/' && "bg-primary/10 text-primary hover:bg-primary/20"
                                )}
                            >
                                <div className="flex items-center gap-2">
                                    <Grid3X3 className="size-4" />
                                    All Categories
                                </div>
                            </Button>
                        </Link>

                        {defaultCategories.map((category) => {
                            const Icon = categoryIcons[category.slug.toLowerCase()] || Grid3X3;
                            const isActive = pathname === `/category/${category.slug}`;

                            return (
                                <Link key={category.id} href={`/category/${category.slug}`}>
                                    <Button
                                        variant={isActive ? 'secondary' : 'ghost'}
                                        className={cn(
                                            "w-full justify-between",
                                            isActive && "bg-primary/10 text-primary hover:bg-primary/20"
                                        )}
                                    >
                                        <div className="flex items-center gap-2">
                                            <Icon className="size-4" />
                                            {category.name}
                                        </div>
                                        {category.count && (
                                            <Badge variant="secondary" className="text-xs">
                                                {category.count}
                                            </Badge>
                                        )}
                                    </Button>
                                </Link>
                            );
                        })}
                    </nav>
                </div>

                <Separator />

                {/* Quick Links */}
                <div>
                    <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">
                        Quick Links
                    </h3>
                    <nav className="space-y-1">
                        <Link href="/national">
                            <Button variant="ghost" className="w-full justify-start gap-2">
                                <ChevronRight className="size-4" />
                                National Auctions
                            </Button>
                        </Link>
                        <Link href="/ending-soon">
                            <Button variant="ghost" className="w-full justify-start gap-2">
                                <ChevronRight className="size-4" />
                                Ending Soon
                            </Button>
                        </Link>
                    </nav>
                </div>
            </div>
        </aside>
    );
}
