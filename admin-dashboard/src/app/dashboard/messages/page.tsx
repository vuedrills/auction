'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getAdminConversations, getAdminChatMessages } from '@/features/admin/adminService';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Loader2, MessageSquare, User, Gavel, Send, Search, Store } from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { TownFilter } from '@/components/filters/TownFilter';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';

export default function MessagesPage() {
    const [selectedChatId, setSelectedChatId] = useState<string | null>(null);
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedTown, setSelectedTown] = useState<string | null>(null);
    const [selectedSuburb, setSelectedSuburb] = useState<string | null>(null);
    const [chatType, setChatType] = useState<'all' | 'auction' | 'shop'>('all');

    const { data: convData, isLoading: loadingConvs } = useQuery({
        queryKey: ['admin-conversations'],
        queryFn: getAdminConversations,
    });

    const { data: msgData, isLoading: loadingMsgs } = useQuery({
        queryKey: ['admin-messages', selectedChatId],
        queryFn: () => getAdminChatMessages(selectedChatId!),
        enabled: !!selectedChatId,
    });

    const conversations = convData?.chats || [];
    const filteredConvs = conversations.filter((c: any) => {
        const matchesSearch =
            c.participant_1_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            c.participant_2_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            c.auction_title?.toLowerCase().includes(searchTerm.toLowerCase());

        // Filter by type (auction vs shop - if we had this field)
        // For now we just use chatType filter if available
        const matchesType = chatType === 'all' ? true :
            (chatType === 'auction' ? !!c.auction_id : !c.auction_id);

        return matchesSearch && matchesType;
    });

    const selectedConv = conversations.find((c: any) => c.id === selectedChatId);
    const conversationCount = filteredConvs.length;

    return (
        <div className="flex flex-col h-[calc(100vh-120px)] space-y-4">
            <div className="flex items-center justify-between gap-4 flex-wrap">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight flex items-center gap-2">
                        Messages Monitor
                        <Badge variant="secondary">{conversationCount}</Badge>
                    </h1>
                    <p className="text-muted-foreground">Monitor platform conversations and support users.</p>
                </div>
                <TownFilter
                    selectedTown={selectedTown}
                    selectedSuburb={selectedSuburb}
                    onTownChange={setSelectedTown}
                    onSuburbChange={setSelectedSuburb}
                />
            </div>

            <div className="flex flex-1 gap-4 min-h-0">
                {/* Sidebar: Conversations List */}
                <Card className="w-96 flex flex-col flex-shrink-0 overflow-hidden">
                    <CardHeader className="p-4 border-b flex-shrink-0 space-y-3">
                        <Tabs value={chatType} onValueChange={(v) => setChatType(v as any)} className="w-full">
                            <TabsList className="grid w-full grid-cols-3">
                                <TabsTrigger value="all">All</TabsTrigger>
                                <TabsTrigger value="auction" className="flex items-center gap-1"><Gavel className="h-3 w-3" />Auction</TabsTrigger>
                                <TabsTrigger value="shop" className="flex items-center gap-1"><Store className="h-3 w-3" />Shop</TabsTrigger>
                            </TabsList>
                        </Tabs>
                        <div className="relative">
                            <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                placeholder="Search chats..."
                                className="pl-8"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                    </CardHeader>
                    <div className="flex-1 overflow-y-auto p-2 space-y-1">
                        {loadingConvs ? (
                            <div className="flex justify-center p-4"><Loader2 className="animate-spin h-5 w-5" /></div>
                        ) : filteredConvs.length === 0 ? (
                            <div className="text-center p-8 text-sm text-muted-foreground">No conversations found</div>
                        ) : (
                            filteredConvs.map((conv: any) => (
                                <div
                                    key={conv.id}
                                    onClick={() => setSelectedChatId(conv.id)}
                                    className={cn(
                                        "flex gap-3 p-3 rounded-lg cursor-pointer transition-colors border",
                                        selectedChatId === conv.id
                                            ? "bg-primary/10 border-primary/20"
                                            : "hover:bg-muted/50 border-transparent"
                                    )}
                                >
                                    {/* Avatars */}
                                    <div className="flex -space-x-2 flex-shrink-0">
                                        <Avatar className="h-8 w-8 border-2 border-background">
                                            <AvatarFallback className="text-[10px] bg-primary/20">
                                                {conv.participant_1_name?.[0]?.toUpperCase() || '?'}
                                            </AvatarFallback>
                                        </Avatar>
                                        <Avatar className="h-8 w-8 border-2 border-background">
                                            <AvatarFallback className="text-[10px] bg-orange-500/20">
                                                {conv.participant_2_name?.[0]?.toUpperCase() || '?'}
                                            </AvatarFallback>
                                        </Avatar>
                                    </div>
                                    {/* Content */}
                                    <div className="flex-1 min-w-0">
                                        <div className="flex justify-between items-start mb-1">
                                            <span className="font-semibold text-sm truncate">
                                                {conv.participant_1_name || 'User 1'} ↔ {conv.participant_2_name || 'User 2'}
                                            </span>
                                            <span className="text-[10px] text-muted-foreground flex-shrink-0 ml-2">
                                                {conv.updated_at ? format(new Date(conv.updated_at), 'MMM d') : '-'}
                                            </span>
                                        </div>
                                        <div className="flex items-center gap-1 text-[11px] text-muted-foreground truncate mb-1">
                                            <Gavel className="h-3 w-3 flex-shrink-0" />
                                            <span className="truncate">{conv.auction_title || 'Unknown Auction'}</span>
                                        </div>
                                        <p className="text-xs text-muted-foreground truncate italic">
                                            "{conv.last_message || 'No messages yet'}"
                                        </p>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </Card>

                {/* Main: Chat View */}
                <Card className="flex-1 flex flex-col overflow-hidden">
                    {!selectedChatId ? (
                        <div className="flex-1 flex flex-col items-center justify-center text-muted-foreground">
                            <MessageSquare className="h-12 w-12 mb-4 opacity-20" />
                            <p>Select a conversation to view messages</p>
                        </div>
                    ) : (
                        <>
                            <CardHeader className="p-4 border-b flex flex-row items-center justify-between flex-shrink-0">
                                <div className="flex items-center gap-3">
                                    <div className="flex -space-x-2">
                                        <Avatar className="h-10 w-10 border-2 border-background">
                                            <AvatarFallback className="bg-primary/20">
                                                {selectedConv?.participant_1_name?.[0]?.toUpperCase() || '?'}
                                            </AvatarFallback>
                                        </Avatar>
                                        <Avatar className="h-10 w-10 border-2 border-background">
                                            <AvatarFallback className="bg-orange-500/20">
                                                {selectedConv?.participant_2_name?.[0]?.toUpperCase() || '?'}
                                            </AvatarFallback>
                                        </Avatar>
                                    </div>
                                    <div>
                                        <CardTitle className="text-lg">
                                            {selectedConv?.participant_1_name} ↔ {selectedConv?.participant_2_name}
                                        </CardTitle>
                                        <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                            <Gavel className="h-3 w-3" />
                                            <span>Auction: {selectedConv?.auction_title}</span>
                                        </div>
                                    </div>
                                </div>
                                <Badge variant="outline" className="text-[10px] font-mono">{selectedChatId?.slice(0, 8)}...</Badge>
                            </CardHeader>

                            <div className="flex-1 overflow-y-auto p-4">
                                {loadingMsgs ? (
                                    <div className="flex justify-center p-12"><Loader2 className="animate-spin h-8 w-8" /></div>
                                ) : msgData?.messages?.length === 0 ? (
                                    <div className="text-center text-muted-foreground py-12">No messages in this conversation</div>
                                ) : (
                                    <div className="space-y-4">
                                        {msgData?.messages?.map((msg: any) => (
                                            <div
                                                key={msg.id}
                                                className={cn(
                                                    "flex flex-col max-w-[80%] p-3 rounded-lg border shadow-sm",
                                                    msg.username === selectedConv?.participant_1_name ? "mr-auto bg-muted/30" : "ml-auto bg-primary/5 border-primary/10"
                                                )}
                                            >
                                                <div className="flex justify-between items-center gap-4 mb-1">
                                                    <span className="font-bold text-[10px] uppercase text-primary/60">{msg.username}</span>
                                                    <span className="text-[10px] text-muted-foreground">{format(new Date(msg.created_at), 'HH:mm')}</span>
                                                </div>
                                                <p className="text-sm">{msg.body}</p>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>

                            <div className="p-4 border-t bg-muted/20 flex-shrink-0">
                                <div className="flex gap-2">
                                    <Input placeholder="Admins can only monitor chats for now..." disabled className="flex-1 bg-background shadow-inner" />
                                    <Button disabled size="icon"><Send className="h-4 w-4" /></Button>
                                </div>
                                <p className="text-[10px] text-center mt-2 text-muted-foreground">
                                    Admins can read all messages to ensure platform safety and resolve disputes.
                                </p>
                            </div>
                        </>
                    )}
                </Card>
            </div>
        </div>
    );
}
