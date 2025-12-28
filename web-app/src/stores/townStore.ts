import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface Town {
    id: string;
    name: string;
    state?: string;
    country?: string;
}

interface Suburb {
    id: string;
    name: string;
    town_id: string;
    zip_code?: string;
}

interface TownState {
    // Selected filters (for browsing)
    selectedTown: Town | null;
    selectedSuburb: Suburb | null;

    // User's home town (from profile)
    homeTown: Town | null;
    homeSuburb: Suburb | null;

    // Cached data
    towns: Town[];
    suburbs: Suburb[];

    // Actions
    setSelectedTown: (town: Town | null) => void;
    setSelectedSuburb: (suburb: Suburb | null) => void;
    setHomeTown: (town: Town | null, suburb: Suburb | null) => void;
    setTowns: (towns: Town[]) => void;
    setSuburbs: (suburbs: Suburb[]) => void;
    clearSelection: () => void;
}

export const useTownStore = create<TownState>()(
    persist(
        (set) => ({
            selectedTown: null,
            selectedSuburb: null,
            homeTown: null,
            homeSuburb: null,
            towns: [],
            suburbs: [],

            setSelectedTown: (town) => set({ selectedTown: town, selectedSuburb: null }),
            setSelectedSuburb: (suburb) => set({ selectedSuburb: suburb }),
            setHomeTown: (town, suburb) => set({ homeTown: town, homeSuburb: suburb }),
            setTowns: (towns) => set({ towns }),
            setSuburbs: (suburbs) => set({ suburbs }),
            clearSelection: () => set({ selectedTown: null, selectedSuburb: null }),
        }),
        {
            name: 'town-storage',
            partialize: (state) => ({
                selectedTown: state.selectedTown,
                selectedSuburb: state.selectedSuburb,
                homeTown: state.homeTown,
                homeSuburb: state.homeSuburb,
            }),
        }
    )
);
