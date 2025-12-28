'use client';

import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getAdminSettings, updateAdminSetting } from '@/features/settings/settingsService';
import { AdminUserTable } from '@/features/admin/components/AdminUserTable';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Switch } from '@/components/ui/switch';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Save, Loader2, RefreshCcw } from 'lucide-react';

export default function SettingsPage() {
    const queryClient = useQueryClient();
    const { data: settings, isLoading, isError } = useQuery({
        queryKey: ['admin-settings'],
        queryFn: getAdminSettings,
    });

    const [faqContent, setFaqContent] = useState('');
    const [privacyContent, setPrivacyContent] = useState('');
    const [aboutContent, setAboutContent] = useState('');
    const [termsContent, setTermsContent] = useState('');

    useEffect(() => {
        if (settings) {
            setFaqContent(settings.faq_content || '');
            setPrivacyContent(settings.privacy_policy || '');
            setAboutContent(settings.about_content || '');
            setTermsContent(settings.terms_of_service || '');
        }
    }, [settings]);

    const updateMutation = useMutation({
        mutationFn: ({ key, value }: { key: string; value: string }) => updateAdminSetting(key, value),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['admin-settings'] });
        },
    });

    const handleSave = async () => {
        try {
            await Promise.all([
                updateMutation.mutateAsync({ key: 'faq_content', value: faqContent }),
                updateMutation.mutateAsync({ key: 'privacy_policy', value: privacyContent }),
                updateMutation.mutateAsync({ key: 'about_content', value: aboutContent }),
                updateMutation.mutateAsync({ key: 'terms_of_service', value: termsContent }),
            ]);
            alert('Settings saved successfully!');
        } catch (error) {
            alert('Failed to save some settings.');
        }
    };

    if (isLoading) return <div className="flex justify-center p-12"><Loader2 className="animate-spin h-8 w-8" /></div>;

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold tracking-tight">Configuration</h1>
                    <p className="text-sm text-muted-foreground">Manage platform settings and content.</p>
                </div>
                <div className="flex gap-2">
                    <Button variant="outline" onClick={() => queryClient.invalidateQueries({ queryKey: ['admin-settings'] })}>
                        <RefreshCcw className="mr-2 h-4 w-4" />
                        Reload
                    </Button>
                    <Button onClick={handleSave} disabled={updateMutation.isPending}>
                        {updateMutation.isPending ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
                        Save Changes
                    </Button>
                </div>
            </div>

            <Tabs defaultValue="content" className="w-full">
                <TabsList>
                    <TabsTrigger value="content">Content</TabsTrigger>
                    <TabsTrigger value="legal">Legal</TabsTrigger>
                    <TabsTrigger value="admins" className="text-primary font-bold">System Users (Admins)</TabsTrigger>
                    <TabsTrigger value="general">General</TabsTrigger>
                    <TabsTrigger value="features">Feature Toggles</TabsTrigger>
                </TabsList>

                <TabsContent value="admins">
                    <AdminUserTable />
                </TabsContent>

                <TabsContent value="content">
                    <div className="space-y-6">
                        <Card>
                            <CardHeader>
                                <CardTitle>FAQ Content</CardTitle>
                                <CardDescription>Edit frequently asked questions (Markdown supported)</CardDescription>
                            </CardHeader>
                            <CardContent>
                                <Textarea
                                    value={faqContent}
                                    onChange={e => setFaqContent(e.target.value)}
                                    rows={12}
                                    className="font-mono text-sm"
                                    placeholder="Enter FAQ content in Markdown..."
                                />
                            </CardContent>
                        </Card>

                        <Card>
                            <CardHeader>
                                <CardTitle>About Page</CardTitle>
                                <CardDescription>Content displayed on the About page (Markdown supported)</CardDescription>
                            </CardHeader>
                            <CardContent>
                                <Textarea
                                    value={aboutContent}
                                    onChange={e => setAboutContent(e.target.value)}
                                    rows={12}
                                    className="font-mono text-sm"
                                    placeholder="Enter About page content in Markdown..."
                                />
                            </CardContent>
                        </Card>
                    </div>
                </TabsContent>

                <TabsContent value="legal">
                    <div className="space-y-6">
                        <Card>
                            <CardHeader>
                                <CardTitle>Privacy Policy</CardTitle>
                                <CardDescription>Privacy policy content (Markdown supported)</CardDescription>
                            </CardHeader>
                            <CardContent>
                                <Textarea
                                    value={privacyContent}
                                    onChange={e => setPrivacyContent(e.target.value)}
                                    rows={12}
                                    className="font-mono text-sm"
                                    placeholder="Enter Privacy Policy in Markdown..."
                                />
                            </CardContent>
                        </Card>

                        <Card>
                            <CardHeader>
                                <CardTitle>Terms of Service</CardTitle>
                                <CardDescription>Terms and conditions (Markdown supported)</CardDescription>
                            </CardHeader>
                            <CardContent>
                                <Textarea
                                    value={termsContent}
                                    onChange={e => setTermsContent(e.target.value)}
                                    rows={12}
                                    className="font-mono text-sm"
                                    placeholder="Enter Terms of Service in Markdown..."
                                />
                            </CardContent>
                        </Card>
                    </div>
                </TabsContent>

                <TabsContent value="general">
                    <Card>
                        <CardHeader>
                            <CardTitle>General Settings</CardTitle>
                            <CardDescription>Configure global application parameters.</CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div className="space-y-2 opacity-50">
                                    <Label>Default Auction Duration (Hours)</Label>
                                    <Input type="number" defaultValue={24} disabled />
                                </div>
                                <div className="space-y-2 opacity-50">
                                    <Label>Anti-Snipe Duration (Minutes)</Label>
                                    <Input type="number" defaultValue={5} disabled />
                                </div>
                                <div className="space-y-2 opacity-50">
                                    <Label>Max Images Per Listing</Label>
                                    <Input type="number" defaultValue={10} disabled />
                                </div>
                                <div className="space-y-2 opacity-50">
                                    <Label>Category Slot Limit</Label>
                                    <Input type="number" defaultValue={10} disabled />
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="features">
                    <Card>
                        <CardHeader>
                            <CardTitle>Feature Toggles</CardTitle>
                            <CardDescription>Enable or disable modules.</CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div className="flex items-center justify-between border p-4 rounded-lg opacity-50">
                                <div className="space-y-0.5">
                                    <Label className="text-base">Stores System</Label>
                                    <p className="text-sm text-muted-foreground">Allow users to create and manage stores</p>
                                </div>
                                <Switch checked disabled />
                            </div>
                            <div className="flex items-center justify-between border p-4 rounded-lg opacity-50">
                                <div className="space-y-0.5">
                                    <Label className="text-base">National Feed</Label>
                                    <p className="text-sm text-muted-foreground">Show auctions from all towns in main feed</p>
                                </div>
                                <Switch checked disabled />
                            </div>
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    );
}
