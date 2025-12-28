import { toast as sonnerToast } from 'sonner';

interface ToastOptions {
    title?: string;
    description?: string;
    variant?: 'default' | 'destructive';
    duration?: number;
}

export function useToast() {
    const toast = ({ title, description, variant, duration = 5000 }: ToastOptions) => {
        if (variant === 'destructive') {
            sonnerToast.error(title, {
                description,
                duration,
            });
        } else {
            sonnerToast.success(title, {
                description,
                duration,
            });
        }
    };

    const dismiss = sonnerToast.dismiss;

    return { toast, dismiss };
}

// Also export a simple toast function for direct use
export const toast = (options: ToastOptions) => {
    const { title, description, variant, duration = 5000 } = options;
    if (variant === 'destructive') {
        sonnerToast.error(title, { description, duration });
    } else {
        sonnerToast.success(title, { description, duration });
    }
};
