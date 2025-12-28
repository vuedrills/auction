import React from 'react';

export default function AuthLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    // Coral pink background accent or similar if needed, 
    // but the prompt asked for "Just centered card with form".
    // I'll add a subtle background color or pattern to make it look nice.
    return (
        <div className="w-full h-full min-h-[50vh] flex items-center justify-center">
            <div className="w-full max-w-md">
                {children}
            </div>
        </div>
    );
}
