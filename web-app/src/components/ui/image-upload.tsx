'use client';

import { useState, useRef, useCallback } from 'react';
import Image from 'next/image';
import { useMutation } from '@tanstack/react-query';
import {
    ImagePlus,
    X,
    Loader2,
    Upload,
    AlertCircle,
    GripVertical
} from 'lucide-react';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import api from '@/services/api';

interface ImageUploadProps {
    value: string[];
    onChange: (urls: string[]) => void;
    maxImages?: number;
    folder?: string;
    disabled?: boolean;
    className?: string;
}

interface UploadResponse {
    url: string;
    filename: string;
    size: number;
}

export function ImageUpload({
    value = [],
    onChange,
    maxImages = 6,
    folder = 'auctions',
    disabled = false,
    className,
}: ImageUploadProps) {
    const [isDragging, setIsDragging] = useState(false);
    const [uploadingCount, setUploadingCount] = useState(0);
    const fileInputRef = useRef<HTMLInputElement>(null);

    // Upload mutation
    const uploadMutation = useMutation({
        mutationFn: async (file: File): Promise<UploadResponse> => {
            const formData = new FormData();
            formData.append('image', file);
            const response = await api.post(`/upload/image?folder=${folder}`, formData, {
                headers: {
                    'Content-Type': 'multipart/form-data',
                },
            });
            return response.data;
        },
    });

    // Handle file selection
    const handleFiles = useCallback(async (files: FileList | File[]) => {
        const fileArray = Array.from(files);
        const remainingSlots = maxImages - value.length;

        if (fileArray.length > remainingSlots) {
            toast.error(`You can only add ${remainingSlots} more image(s)`);
            return;
        }

        // Validate files
        const validFiles = fileArray.filter(file => {
            if (!file.type.startsWith('image/')) {
                toast.error(`${file.name} is not an image`);
                return false;
            }
            if (file.size > 10 * 1024 * 1024) {
                toast.error(`${file.name} is too large (max 10MB)`);
                return false;
            }
            return true;
        });

        if (validFiles.length === 0) return;

        setUploadingCount(validFiles.length);

        try {
            const uploadPromises = validFiles.map(file => uploadMutation.mutateAsync(file));
            const results = await Promise.all(uploadPromises);
            const newUrls = results.map(r => r.url);
            onChange([...value, ...newUrls]);
            toast.success(`${newUrls.length} image(s) uploaded successfully`);
        } catch (error: any) {
            toast.error(error.response?.data?.error || 'Failed to upload images');
        } finally {
            setUploadingCount(0);
        }
    }, [value, onChange, maxImages, folder, uploadMutation]);

    // Drag and drop handlers
    const handleDragEnter = (e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
        if (!disabled) setIsDragging(true);
    };

    const handleDragLeave = (e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(false);
    };

    const handleDragOver = (e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
    };

    const handleDrop = (e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(false);

        if (disabled) return;

        const files = e.dataTransfer.files;
        if (files && files.length > 0) {
            handleFiles(files);
        }
    };

    // File input change handler
    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const files = e.target.files;
        if (files && files.length > 0) {
            handleFiles(files);
        }
        // Reset input
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    // Remove image
    const handleRemove = (index: number) => {
        const newUrls = value.filter((_, i) => i !== index);
        onChange(newUrls);
    };

    // Reorder images (move to first position)
    const handleMakeFirst = (index: number) => {
        if (index === 0) return;
        const newUrls = [...value];
        const [item] = newUrls.splice(index, 1);
        newUrls.unshift(item);
        onChange(newUrls);
    };

    const isUploading = uploadingCount > 0;
    const canAddMore = value.length < maxImages && !isUploading && !disabled;

    return (
        <div className={cn('space-y-3', className)}>
            {/* Image Grid */}
            <div className="grid grid-cols-3 gap-4">
                {/* Existing Images */}
                {value.map((url, index) => (
                    <div
                        key={url}
                        className="relative aspect-square rounded-xl overflow-hidden bg-muted group"
                    >
                        <Image
                            src={url}
                            alt={`Image ${index + 1}`}
                            fill
                            className="object-cover"
                            sizes="(max-width: 768px) 33vw, 200px"
                        />

                        {/* Overlay */}
                        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/40 transition-colors" />

                        {/* Controls */}
                        <div className="absolute top-2 right-2 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                            {index !== 0 && (
                                <button
                                    type="button"
                                    onClick={() => handleMakeFirst(index)}
                                    className="size-7 bg-white text-foreground rounded-full flex items-center justify-center hover:bg-primary hover:text-white transition-colors"
                                    title="Make cover image"
                                >
                                    <GripVertical className="size-4" />
                                </button>
                            )}
                            <button
                                type="button"
                                onClick={() => handleRemove(index)}
                                className="size-7 bg-destructive text-white rounded-full flex items-center justify-center hover:bg-destructive/80 transition-colors"
                            >
                                <X className="size-4" />
                            </button>
                        </div>

                        {/* Cover Badge */}
                        {index === 0 && (
                            <Badge className="absolute bottom-2 left-2 text-xs bg-primary">
                                Cover
                            </Badge>
                        )}
                    </div>
                ))}

                {/* Uploading Placeholders */}
                {Array.from({ length: uploadingCount }).map((_, i) => (
                    <div
                        key={`uploading-${i}`}
                        className="aspect-square rounded-xl border-2 border-dashed border-primary/50 bg-primary/5 flex items-center justify-center"
                    >
                        <Loader2 className="size-8 text-primary animate-spin" />
                    </div>
                ))}

                {/* Add Button */}
                {canAddMore && (
                    <button
                        type="button"
                        onClick={() => fileInputRef.current?.click()}
                        onDragEnter={handleDragEnter}
                        onDragLeave={handleDragLeave}
                        onDragOver={handleDragOver}
                        onDrop={handleDrop}
                        className={cn(
                            "aspect-square rounded-xl border-2 border-dashed flex flex-col items-center justify-center gap-2 transition-colors",
                            isDragging
                                ? "border-primary bg-primary/10 text-primary"
                                : "border-muted-foreground/30 text-muted-foreground hover:border-primary hover:text-primary hover:bg-primary/5"
                        )}
                    >
                        <ImagePlus className="size-8" />
                        <span className="text-xs font-medium">
                            {isDragging ? 'Drop here' : 'Add Photo'}
                        </span>
                    </button>
                )}
            </div>

            {/* Hidden File Input */}
            <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp,image/gif"
                multiple
                onChange={handleFileChange}
                className="hidden"
            />

            {/* Helper Text */}
            <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span>
                    {value.length}/{maxImages} images • Max 10MB each
                </span>
                {value.length === 0 && (
                    <span className="flex items-center gap-1 text-orange-500">
                        <AlertCircle className="size-3" />
                        At least 1 image required
                    </span>
                )}
            </div>

            {/* Drop Zone Overlay (for larger drop area) */}
            {isDragging && (
                <div
                    className="fixed inset-0 z-50 bg-primary/10 backdrop-blur-sm flex items-center justify-center"
                    onDragEnter={handleDragEnter}
                    onDragLeave={handleDragLeave}
                    onDragOver={handleDragOver}
                    onDrop={handleDrop}
                >
                    <div className="bg-card rounded-2xl p-12 shadow-2xl border-2 border-dashed border-primary">
                        <div className="text-center">
                            <Upload className="size-16 text-primary mx-auto mb-4" />
                            <p className="text-xl font-semibold">Drop images here</p>
                            <p className="text-muted-foreground mt-1">
                                JPG, PNG, WebP or GIF (max 10MB)
                            </p>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
