
export interface Town {
    id: string;
    name: string;
    state: string;
    country: string;
    timezone: string;
    created_at: string;
    active_auctions?: number;
    total_suburbs?: number;
}

export interface TownListResponse {
    towns: Town[];
}
