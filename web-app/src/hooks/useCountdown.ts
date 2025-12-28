'use client';

import { useState, useEffect, useMemo } from 'react';

interface CountdownResult {
    timeLeft: string;
    isExpired: boolean;
    isEndingSoon: boolean;
    days: number;
    hours: number;
    minutes: number;
    seconds: number;
}

export function useCountdown(endTime: string): CountdownResult {
    const endDate = useMemo(() => new Date(endTime), [endTime]);

    const calculateTimeLeft = (): CountdownResult => {
        const now = new Date();
        const difference = endDate.getTime() - now.getTime();

        if (difference <= 0) {
            return {
                timeLeft: 'Ended',
                isExpired: true,
                isEndingSoon: false,
                days: 0,
                hours: 0,
                minutes: 0,
                seconds: 0,
            };
        }

        const days = Math.floor(difference / (1000 * 60 * 60 * 24));
        const hours = Math.floor((difference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((difference % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((difference % (1000 * 60)) / 1000);

        // Ending soon if less than 1 hour
        const isEndingSoon = difference < 60 * 60 * 1000;

        let timeLeft: string;
        if (days > 0) {
            timeLeft = `${days}d ${hours}h`;
        } else if (hours > 0) {
            timeLeft = `${hours}h ${minutes}m`;
        } else if (minutes > 0) {
            timeLeft = `${minutes}m ${seconds}s`;
        } else {
            timeLeft = `${seconds}s`;
        }

        return {
            timeLeft,
            isExpired: false,
            isEndingSoon,
            days,
            hours,
            minutes,
            seconds,
        };
    };

    const [countdown, setCountdown] = useState<CountdownResult>(calculateTimeLeft);

    useEffect(() => {
        const timer = setInterval(() => {
            setCountdown(calculateTimeLeft());
        }, 1000);

        return () => clearInterval(timer);
    }, [endDate]);

    return countdown;
}
