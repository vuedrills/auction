import { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
    const baseUrl = process.env.NEXT_PUBLIC_APP_URL || 'https://trabab.com';

    return {
        rules: [
            {
                userAgent: '*',
                allow: '/',
                disallow: [
                    '/api/',
                    '/profile/',
                    '/settings/',
                    '/messages/',
                    '/notifications/',
                ],
            },
        ],
        sitemap: `${baseUrl}/sitemap.xml`,
    };
}
