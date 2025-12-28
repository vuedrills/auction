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
    Grid3X3,
    Store
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

import { useQuery } from '@tanstack/react-query';
import { categoriesService } from '@/services/categories';

export function Sidebar() {
    const pathname = usePathname();
    const { selectedTown, selectedSuburb } = useTownStore();
    const { setTownFilterOpen } = useUIStore();

    const { data: categories, isLoading } = useQuery({
        queryKey: ['categories'],
        queryFn: categoriesService.getCategories,
    });

    const isAuthPage = ['/login', '/register', '/forgot-password', '/reset-password'].some(path => pathname.startsWith(path));

    if (isAuthPage) return null;

    return (
        <aside className="fixed left-0 top-16 bottom-0 w-64 border-r bg-card/50 backdrop-blur-xl z-30 hidden lg:block overflow-y-auto">
            <div className="p-6 space-y-8">
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

                        {isLoading ? (
                            [...Array(6)].map((_, i) => (
                                <div key={i} className="h-9 w-full bg-muted animate-pulse rounded-md" />
                            ))
                        ) : categories?.map((category: any) => {
                            const slug = category.slug || category.name.toLowerCase().replace(/\s+/g, '-');
                            const Icon = categoryIcons[slug] || Grid3X3;
                            const isActive = pathname === `/category/${slug}`;

                            return (
                                <Link key={category.id} href={`/category/${slug}`}>
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
                                        {category.active_auctions > 0 && (
                                            <Badge variant="secondary" className="text-xs">
                                                {category.active_auctions}
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
                        Discover
                    </h3>
                    <nav className="space-y-1">
                        <Link href="/shops">
                            <Button
                                variant={pathname.startsWith('/shops') ? 'secondary' : 'ghost'}
                                className={cn(
                                    "w-full justify-start gap-2",
                                    pathname.startsWith('/shops') && "bg-primary/10 text-primary"
                                )}
                            >
                                <Store className="size-4" />
                                Browse Shops
                            </Button>
                        </Link>
                        <Link href="/national">
                            <Button
                                variant={pathname === '/national' ? 'secondary' : 'ghost'}
                                className={cn(
                                    "w-full justify-start gap-2",
                                    pathname === '/national' && "bg-primary/10 text-primary"
                                )}
                            >
                                <ChevronRight className="size-4" />
                                National Auctions
                            </Button>
                        </Link>
                        <Link href="/ending-soon">
                            <Button
                                variant={pathname === '/ending-soon' ? 'secondary' : 'ghost'}
                                className={cn(
                                    "w-full justify-start gap-2",
                                    pathname === '/ending-soon' && "bg-primary/10 text-primary"
                                )}
                            >
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
