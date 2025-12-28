'use client';

import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from '@/components/ui/card';
import {
    LineChart,
    Line,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
    BarChart,
    Bar,
} from 'recharts';
import { format, subMonths, startOfMonth, eachMonthOfInterval } from 'date-fns';

const generateMockMonthlyData = () => {
    const today = new Date();
    const interval = eachMonthOfInterval({
        start: subMonths(today, 5),
        end: today,
    });

    return interval.map((date) => ({
        month: format(date, 'MMM'),
        users: Math.floor(Math.random() * 200) + 100,
        auctions: Math.floor(Math.random() * 50) + 30,
        sales: Math.floor(Math.random() * 5000) + 2000,
    }));
};

export function DashboardCharts() {
    const data = generateMockMonthlyData();

    return (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7 mt-8">
            <Card className="col-span-4">
                <CardHeader>
                    <CardTitle>Growth Overview</CardTitle>
                    <CardDescription>User and Auction trends for the last 6 months.</CardDescription>
                </CardHeader>
                <CardContent className="pl-2">
                    <div className="h-[350px] w-full">
                        <ResponsiveContainer width="100%" height="100%">
                            <LineChart data={data}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" />
                                <XAxis
                                    dataKey="month"
                                    tickLine={false}
                                    axisLine={false}
                                    tick={{ fill: '#6B7280', fontSize: 12 }}
                                />
                                <YAxis
                                    tickLine={false}
                                    axisLine={false}
                                    tick={{ fill: '#6B7280', fontSize: 12 }}
                                />
                                <Tooltip
                                    contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                                />
                                <Line type="monotone" dataKey="users" stroke="#EE456B" strokeWidth={2} dot={{ r: 4 }} activeDot={{ r: 6 }} name="New Users" />
                                <Line type="monotone" dataKey="auctions" stroke="#FF8322" strokeWidth={2} dot={{ r: 4 }} activeDot={{ r: 6 }} name="Auctions" />
                            </LineChart>
                        </ResponsiveContainer>
                    </div>
                </CardContent>
            </Card>

            <Card className="col-span-3">
                <CardHeader>
                    <CardTitle>Sales Revenue</CardTitle>
                    <CardDescription>Monthly revenue trends ($).</CardDescription>
                </CardHeader>
                <CardContent>
                    <div className="h-[350px] w-full">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={data}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" />
                                <XAxis
                                    dataKey="month"
                                    tickLine={false}
                                    axisLine={false}
                                    tick={{ fill: '#6B7280', fontSize: 12 }}
                                />
                                <YAxis
                                    tickLine={false}
                                    axisLine={false}
                                    tick={{ fill: '#6B7280', fontSize: 12 }}
                                />
                                <Tooltip
                                    cursor={{ fill: 'transparent' }}
                                    contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                                    formatter={(value) => [`$${value}`, 'Revenue']}
                                />
                                <Bar dataKey="sales" fill="#3B82F6" radius={[4, 4, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}
