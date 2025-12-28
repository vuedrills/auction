import type { Metadata, Viewport } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/providers";
import { Navbar } from "@/components/layout/Navbar";
import { Sidebar } from "@/components/layout/Sidebar";

const plusJakarta = Plus_Jakarta_Sans({
  variable: "--font-plus-jakarta",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
});

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#0a0a0a' },
  ],
};

export const metadata: Metadata = {
  title: {
    default: "Trabab - Local Marketplace",
    template: "%s | Trabab",
  },
  description: "Buy and sell in your local community through auctions and shops. Find great deals on electronics, vehicles, fashion, and more in Zimbabwe.",
  keywords: ["marketplace", "auctions", "local", "buy", "sell", "Zimbabwe", "Harare", "Bulawayo", "online shopping"],
  authors: [{ name: "Trabab" }],
  creator: "Trabab",
  publisher: "Trabab",
  metadataBase: new URL(process.env.NEXT_PUBLIC_APP_URL || 'https://trabab.com'),
  openGraph: {
    type: 'website',
    locale: 'en_US',
    siteName: 'Trabab',
    title: 'Trabab - Local Marketplace',
    description: 'Buy and sell in your local community through auctions and shops.',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Trabab - Local Marketplace',
    description: 'Buy and sell in your local community through auctions and shops.',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
};

import { TownFilterModal } from "@/components/modals/TownFilterModal";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${plusJakarta.variable} font-sans antialiased`}
      >
        <Providers>
          <div className="min-h-screen flex flex-col">
            <Navbar />
            <div className="flex flex-1">
              <Sidebar />
              <main className="flex-1 lg:pl-64 min-h-[calc(100vh-4rem)]">
                <div className="p-4 lg:p-8 max-w-7xl mx-auto">
                  {children}
                </div>
              </main>
            </div>
          </div>
          <TownFilterModal />
        </Providers>
      </body>
    </html>
  );
}

