import { create } from 'zustand';

interface UIState {
    // Sidebar
    sidebarOpen: boolean;
    setSidebarOpen: (open: boolean) => void;
    toggleSidebar: () => void;

    // Mobile menu
    mobileMenuOpen: boolean;
    setMobileMenuOpen: (open: boolean) => void;

    // Modals
    townFilterOpen: boolean;
    setTownFilterOpen: (open: boolean) => void;

    bidModalOpen: boolean;
    bidModalAuctionId: string | null;
    openBidModal: (auctionId: string) => void;
    closeBidModal: () => void;

    // View mode
    viewMode: 'grid' | 'list';
    setViewMode: (mode: 'grid' | 'list') => void;
}

export const useUIStore = create<UIState>((set) => ({
    // Sidebar
    sidebarOpen: true,
    setSidebarOpen: (open) => set({ sidebarOpen: open }),
    toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),

    // Mobile menu
    mobileMenuOpen: false,
    setMobileMenuOpen: (open) => set({ mobileMenuOpen: open }),

    // Modals
    townFilterOpen: false,
    setTownFilterOpen: (open) => set({ townFilterOpen: open }),

    bidModalOpen: false,
    bidModalAuctionId: null,
    openBidModal: (auctionId) => set({ bidModalOpen: true, bidModalAuctionId: auctionId }),
    closeBidModal: () => set({ bidModalOpen: false, bidModalAuctionId: null }),

    // View mode
    viewMode: 'grid',
    setViewMode: (mode) => set({ viewMode: mode }),
}));
