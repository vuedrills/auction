'use client';

import {
    Sidebar,
    SidebarContent,
    SidebarFooter,
    SidebarGroup,
    SidebarGroupContent,
    SidebarGroupLabel,
    SidebarHeader,
    SidebarMenu,
    SidebarMenuItem,
    SidebarMenuButton,
    SidebarRail,
} from "@/components/ui/sidebar"
import { LayoutDashboard, Users, Gavel, Store, BarChart3, Settings, LogOut, MapPin, MessageSquare, Receipt, Bell, Folder } from 'lucide-react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useStore } from '@/store/useStore';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';

export function AppSidebar() {
    const pathname = usePathname();
    const { logout, user } = useStore();
    const router = useRouter();

    const handleLogout = () => {
        logout();
        router.push('/login');
    };

    const navItems = [
        { label: 'Dashboard', icon: LayoutDashboard, href: '/dashboard' },
        { label: 'Users', icon: Users, href: '/dashboard/users' },
        { label: 'Auctions', icon: Gavel, href: '/dashboard/auctions' },
        { label: 'Bids', icon: Receipt, href: '/dashboard/bids' },
        { label: 'Messages', icon: MessageSquare, href: '/dashboard/messages' },
        { label: 'Notifications', icon: Bell, href: '/dashboard/notifications' },
        { label: 'Categories', icon: Folder, href: '/dashboard/categories' },
        { label: 'Stores', icon: Store, href: '/dashboard/stores' },
        { label: 'Towns', icon: MapPin, href: '/dashboard/towns' },
        { label: 'Analytics', icon: BarChart3, href: '/dashboard/analytics' },
        { label: 'Settings', icon: Settings, href: '/dashboard/settings' },
    ];

    return (
        <Sidebar>
            <SidebarHeader>
                <div className="flex items-center px-4 py-2 border-b border-sidebar-border/50">
                    <h1 className="text-xl font-bold text-sidebar-primary">Trabab Admin</h1>
                </div>
            </SidebarHeader>
            <SidebarContent>
                <SidebarGroup>
                    <SidebarGroupLabel>Menu</SidebarGroupLabel>
                    <SidebarGroupContent>
                        <SidebarMenu>
                            {navItems.map((item) => (
                                <SidebarMenuItem key={item.href}>
                                    <SidebarMenuButton
                                        asChild
                                        isActive={pathname === item.href || pathname.startsWith(item.href + '/')}
                                        tooltip={item.label}
                                    >
                                        <Link href={item.href}>
                                            <item.icon className="h-4 w-4" />
                                            <span>{item.label}</span>
                                        </Link>
                                    </SidebarMenuButton>
                                </SidebarMenuItem>
                            ))}
                        </SidebarMenu>
                    </SidebarGroupContent>
                </SidebarGroup>
            </SidebarContent>
            <SidebarFooter className="p-4 border-t border-sidebar-border/50">
                <div className="flex flex-col gap-2">
                    <div className="flex items-center gap-2 px-2 py-1">
                        <div className="bg-sidebar-accent rounded-full w-8 h-8 flex items-center justify-center text-xs font-bold">
                            {user?.username?.[0]?.toUpperCase() || 'A'}
                        </div>
                        <div className="flex flex-col overflow-hidden">
                            <span className="text-sm font-medium truncate">{user?.username || 'Admin'}</span>
                            <span className="text-xs text-muted-foreground truncate">{user?.email}</span>
                        </div>
                    </div>
                    <Button variant="outline" size="sm" className="w-full justify-start text-destructive hover:text-destructive hover:bg-destructive/10" onClick={handleLogout}>
                        <LogOut className="mr-2 h-4 w-4" />
                        Sign Out
                    </Button>
                </div>
            </SidebarFooter>
            <SidebarRail />
        </Sidebar>
    );
}
