'use client';

import { useState, useCallback } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
    Gavel,
    Store,
    Bell,
    MessageSquare,
    User,
    Search,
    Menu,
    X,
    ChevronDown,
    LogOut,
    Settings,
    Package
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { useAuthStore } from '@/stores/authStore';
import { useUIStore } from '@/stores/uiStore';
import { cn } from '@/lib/utils';
import { NotificationCenter } from '@/components/notifications/NotificationCenter';
import { chatService } from '@/services/chat';
import { useQuery } from '@tanstack/react-query';

export function Navbar() {
    const pathname = usePathname();
    const router = useRouter();
    const { user, isAuthenticated, logout } = useAuthStore();
    const { mobileMenuOpen, setMobileMenuOpen } = useUIStore();
    const [searchQuery, setSearchQuery] = useState('');

    const { data: unreadCounts } = useQuery({
        queryKey: ['unread-counts'],
        queryFn: chatService.getUnreadCounts,
        enabled: isAuthenticated,
        refetchInterval: 30000, // Refresh every 30s
    });

    const unreadMessages = unreadCounts?.total || 0;

    const navItems = [
        { href: '/', label: 'Auctions', icon: Gavel },
        { href: '/shops', label: 'Shops', icon: Store },
    ];

    const handleSearch = useCallback((e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Enter' && searchQuery.trim()) {
            // Navigate to search results based on current context
            if (pathname.startsWith('/shops')) {
                router.push(`/shops?q=${encodeURIComponent(searchQuery.trim())}`);
            } else {
                router.push(`/?search=${encodeURIComponent(searchQuery.trim())}`);
            }
        }
    }, [searchQuery, pathname, router]);

    const isAuthPage = ['/login', '/register', '/forgot-password', '/reset-password'].some(path => pathname.startsWith(path));

    if (isAuthPage) return null;

    return (
        <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
            <div className="container flex h-16 items-center gap-4">
                {/* Logo */}
                <Link href="/" className="flex items-center gap-2 font-bold text-xl">
                    <div className="size-9 rounded-xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center">
                        <Gavel className="size-5 text-white" />
                    </div>
                    <span className="hidden sm:inline-block">Trabab</span>
                </Link>

                {/* Desktop Navigation */}
                <div className="hidden md:flex flex-1 justify-center">
                    <nav className="flex items-center gap-1 bg-muted/50 p-1.5 rounded-full border shadow-inner">
                        {navItems.map((item) => {
                            const Icon = item.icon;
                            const isActive = pathname === item.href ||
                                (item.href !== '/' && pathname.startsWith(item.href));

                            return (
                                <Link key={item.href} href={item.href}>
                                    <Button
                                        variant={isActive ? "secondary" : "ghost"}
                                        size="sm"
                                        className={cn(
                                            "rounded-full px-6 gap-2 transition-all",
                                            isActive && "bg-white dark:bg-slate-800 text-primary shadow-sm hover:bg-white dark:hover:bg-slate-800"
                                        )}
                                    >
                                        <Icon className="size-4" />
                                        <span className="font-bold">{item.label}</span>
                                    </Button>
                                </Link>
                            );
                        })}
                    </nav>
                </div>

                {/* Search */}
                <div className="flex-1 max-w-md mx-4 hidden md:block">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
                        <Input
                            type="search"
                            placeholder="Search auctions, shops..."
                            className="pl-10 bg-muted/50"
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            onKeyDown={handleSearch}
                        />
                    </div>
                </div>

                {/* Right Actions */}
                <div className="flex items-center gap-2 ml-auto">
                    {isAuthenticated ? (
                        <>
                            {/* Notifications */}
                            <NotificationCenter />

                            {/* Messages */}
                            <Link href="/messages">
                                <Button variant="ghost" size="icon" className="relative h-10 w-10 mt-1">
                                    <MessageSquare className="size-5" />
                                    {unreadMessages > 0 && (
                                        <Badge className="absolute -top-1 -right-1 size-5 p-0 flex items-center justify-center text-[10px] font-bold ring-2 ring-background">
                                            {unreadMessages > 9 ? '9+' : unreadMessages}
                                        </Badge>
                                    )}
                                </Button>
                            </Link>

                            {/* Profile Dropdown */}
                            <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                    <Button variant="ghost" className="gap-2 px-2">
                                        <Avatar className="size-8">
                                            <AvatarImage src={user?.profile_image_url} />
                                            <AvatarFallback className="bg-primary/10 text-primary font-bold">
                                                {user?.username?.[0]?.toUpperCase() || 'U'}
                                            </AvatarFallback>
                                        </Avatar>
                                        <span className="hidden lg:inline-block max-w-[100px] truncate">
                                            {user?.username}
                                        </span>
                                        <ChevronDown className="size-4 text-muted-foreground" />
                                    </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent align="end" className="w-56">
                                    <div className="px-2 py-1.5">
                                        <p className="text-sm font-medium">{user?.username}</p>
                                        <p className="text-xs text-muted-foreground">{user?.email}</p>
                                    </div>
                                    <DropdownMenuSeparator />
                                    <DropdownMenuItem asChild>
                                        <Link href="/profile" className="flex items-center gap-2">
                                            <User className="size-4" />
                                            My Profile
                                        </Link>
                                    </DropdownMenuItem>
                                    <DropdownMenuItem asChild>
                                        <Link href="/profile/auctions" className="flex items-center gap-2">
                                            <Gavel className="size-4" />
                                            My Auctions
                                        </Link>
                                    </DropdownMenuItem>
                                    <DropdownMenuItem asChild>
                                        <Link href="/profile/stores" className="flex items-center gap-2">
                                            <Package className="size-4" />
                                            My Stores
                                        </Link>
                                    </DropdownMenuItem>
                                    <DropdownMenuItem asChild>
                                        <Link href="/settings" className="flex items-center gap-2">
                                            <Settings className="size-4" />
                                            Settings
                                        </Link>
                                    </DropdownMenuItem>
                                    <DropdownMenuSeparator />
                                    <DropdownMenuItem
                                        onClick={() => logout()}
                                        className="text-destructive focus:text-destructive"
                                    >
                                        <LogOut className="size-4 mr-2" />
                                        Log Out
                                    </DropdownMenuItem>
                                </DropdownMenuContent>
                            </DropdownMenu>
                        </>
                    ) : (
                        <>
                            <Link href="/login">
                                <Button variant="ghost" size="sm">Log In</Button>
                            </Link>
                            <Link href="/register">
                                <Button size="sm">Sign Up</Button>
                            </Link>
                        </>
                    )}

                    {/* Mobile Menu Toggle */}
                    <Button
                        variant="ghost"
                        size="icon"
                        className="md:hidden"
                        onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                    >
                        {mobileMenuOpen ? <X className="size-5" /> : <Menu className="size-5" />}
                    </Button>
                </div>
            </div>

            {/* Mobile Menu */}
            {mobileMenuOpen && (
                <div className="md:hidden border-t bg-background p-4 space-y-4">
                    {/* Mobile Search */}
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
                        <Input
                            type="search"
                            placeholder="Search auctions, shops..."
                            className="pl-10"
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            onKeyDown={handleSearch}
                        />
                    </div>

                    {/* Mobile Nav */}
                    <nav className="flex flex-col gap-1">
                        {navItems.map((item) => {
                            const Icon = item.icon;
                            const isActive = pathname === item.href;

                            return (
                                <Link key={item.href} href={item.href} onClick={() => setMobileMenuOpen(false)}>
                                    <Button
                                        variant={isActive ? "secondary" : "ghost"}
                                        className="w-full justify-start gap-3"
                                    >
                                        <Icon className="size-5" />
                                        {item.label}
                                    </Button>
                                </Link>
                            );
                        })}
                    </nav>
                </div>
            )}
        </header>
    );
}
