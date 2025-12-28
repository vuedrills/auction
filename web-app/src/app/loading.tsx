export default function Loading() {
    return (
        <div className="min-h-[60vh] flex items-center justify-center">
            <div className="text-center">
                <div className="size-12 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-4" />
                <p className="text-muted-foreground animate-pulse">Loading...</p>
            </div>
        </div>
    );
}
