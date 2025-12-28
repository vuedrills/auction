'use client';

import { useState, useEffect, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    Search,
    MessageSquare,
    Send,
    Image as ImageIcon,
    MoreVertical,
    ArrowLeft,
    Loader2,
    Store as StoreIcon,
    Gavel,
    Check,
    CheckCheck,
    UserCircle,
    Package
} from 'lucide-react';
import Image from 'next/image';
import { format } from 'date-fns';
import { toast } from 'sonner';

import { chatService, AuctionChat, ShopChat, ChatMessage } from '@/services/chat';
import { useAuthStore } from '@/stores/authStore';
import { useCallback } from 'react';
import { useWebSocket } from '@/hooks/useWebSocket';
import { WSMessage } from '@/services/websocket';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { cn } from '@/lib/utils';

type Conversation = (AuctionChat & { type: 'auction' }) | (ShopChat & { type: 'shop' });

import { useSearchParams } from 'next/navigation';

export default function InboxPage() {
    const { user } = useAuthStore();
    const queryClient = useQueryClient();
    const searchParams = useSearchParams();

    // Auto-select chat from query params
    const initialChatId = searchParams.get('id');
    const initialChatType = searchParams.get('type') as 'auction' | 'shop';

    const [selectedChat, setSelectedChat] = useState<{ id: string; type: 'auction' | 'shop' } | null>(
        initialChatId && initialChatType ? { id: initialChatId, type: initialChatType } : null
    );
    const [message, setMessage] = useState('');
    const scrollRef = useRef<HTMLDivElement>(null);

    // Queries
    const { data: auctionChats, isLoading: isLoadingAuctions } = useQuery({
        queryKey: ['auction-chats'],
        queryFn: chatService.getAuctionChats,
    });

    const { data: shopChats, isLoading: isLoadingShops } = useQuery({
        queryKey: ['shop-chats'],
        queryFn: chatService.getShopChats,
    });

    const { data: messages, isLoading: isLoadingMessages } = useQuery({
        queryKey: ['messages', selectedChat?.id, selectedChat?.type],
        queryFn: () => {
            if (selectedChat?.type === 'auction') return chatService.getAuctionMessages(selectedChat.id);
            return chatService.getShopMessages(selectedChat!.id);
        },
        enabled: !!selectedChat,
    });

    // Mutation
    const sendMessageMutation = useMutation({
        mutationFn: (content: string) => {
            if (selectedChat?.type === 'auction') return chatService.sendAuctionMessage(selectedChat.id, content);
            return chatService.sendShopMessage(selectedChat!.id, content);
        },
        onSuccess: (newMsg) => {
            setMessage('');
            queryClient.setQueryData(['messages', selectedChat?.id, selectedChat?.type], (old: any) => {
                const list = old || [];
                if (list.some((m: any) => m.id === newMsg.id)) return list;
                return [newMsg, ...list];
            });
        },
    });

    // WebSocket Integration
    const handleWSMessage = useCallback((msg: WSMessage) => {
        if (msg.type === 'message:new' || msg.type === 'shop_message:new') {
            const incomingMsg = msg.data.message || msg.data;
            const chatId = incomingMsg.chat_id || incomingMsg.conversation_id;

            // Invalidate lists
            queryClient.invalidateQueries({ queryKey: ['auction-chats'] });
            queryClient.invalidateQueries({ queryKey: ['shop-chats'] });
            queryClient.invalidateQueries({ queryKey: ['unread-counts'] });

            // If this message belongs to current chat, add it
            if (selectedChatRef.current && selectedChatRef.current.id === chatId) {
                queryClient.setQueryData(['messages', selectedChatRef.current.id, selectedChatRef.current.type], (old: any) => {
                    const list = old || [];
                    if (list.some((m: any) => m.id === incomingMsg.id)) return list;
                    return [incomingMsg, ...list];
                });

                // Mark as read
                if (selectedChatRef.current.type === 'auction') chatService.markAuctionChatRead(chatId);
                else chatService.markShopChatRead(chatId);
            }
        }
    }, [queryClient]); // Removed selectedChat dependency to stable ref

    useWebSocket(handleWSMessage);

    // Keep ref updated for WS callback
    const selectedChatRef = useRef(selectedChat);
    useEffect(() => {
        selectedChatRef.current = selectedChat;
    }, [selectedChat]);

    // Combine and Sort Chats
    const conversations: Conversation[] = [
        ...(auctionChats?.map(c => ({ ...c, type: 'auction' })) || []),
        ...(shopChats?.map(c => ({ ...c, type: 'shop' })) || [])
    ].sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()) as Conversation[];

    const activeChat = conversations.find(c => c.id === selectedChat?.id);

    useEffect(() => {
        if (scrollRef.current) {
            scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
        }
    }, [messages]);

    useEffect(() => {
        if (selectedChat) {
            if (selectedChat.type === 'auction') chatService.markAuctionChatRead(selectedChat.id);
            else chatService.markShopChatRead(selectedChat.id);
        }
    }, [selectedChat]);

    const handleSend = (e: React.FormEvent) => {
        e.preventDefault();
        if (!message.trim() || sendMessageMutation.isPending) return;
        sendMessageMutation.mutate(message);
    };

    return (
        <div className="flex h-[calc(100vh-8rem)] bg-card rounded-3xl border overflow-hidden shadow-xl shadow-black/5">
            {/* Sidebar: Chat List */}
            <div className={cn(
                "w-full md:w-80 lg:w-96 border-r flex flex-col bg-muted/10 overflow-hidden",
                selectedChat && "hidden md:flex"
            )}>
                <div className="p-6 space-y-4 flex-shrink-0">
                    <h2 className="text-2xl font-black">Messages</h2>
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
                        <Input placeholder="Search conversations..." className="pl-10 h-11 bg-muted/50 border-none rounded-xl" />
                    </div>
                </div>

                <ScrollArea className="flex-1 min-h-0">
                    <div className="px-3 pb-6 space-y-1">
                        {isLoadingAuctions && isLoadingShops ? (
                            [...Array(5)].map((_, i) => (
                                <div key={i} className="h-20 bg-muted animate-pulse rounded-2xl mx-3" />
                            ))
                        ) : conversations.length > 0 ? (
                            conversations.map((chat) => (
                                <button
                                    key={chat.id}
                                    onClick={() => setSelectedChat({ id: chat.id, type: chat.type })}
                                    className={cn(
                                        "w-full p-4 rounded-2xl flex items-center gap-4 transition-all hover:bg-muted/50",
                                        selectedChat?.id === chat.id ? "bg-primary/5 text-primary scale-[0.98]" : "text-foreground"
                                    )}
                                >
                                    <Avatar className="size-12 rounded-xl">
                                        <AvatarImage src={chat.type === 'auction' ? chat.participant_avatar : chat.other_avatar} />
                                        <AvatarFallback className="bg-primary/10 text-primary">
                                            {chat.type === 'auction' ? chat.participant_name?.[0] : chat.other_name?.[0]}
                                        </AvatarFallback>
                                    </Avatar>

                                    <div className="flex-1 text-left min-w-0">
                                        <div className="flex items-center justify-between mb-0.5">
                                            <span className="font-bold truncate">
                                                {chat.type === 'auction' ? chat.participant_name : chat.other_name}
                                            </span>
                                            <span className="text-[10px] text-muted-foreground">
                                                {format(new Date(chat.updated_at), 'HH:mm')}
                                            </span>
                                        </div>
                                        <div className="flex items-center gap-1 text-xs text-muted-foreground">
                                            {chat.type === 'auction' ? <Gavel className="size-3" /> : <StoreIcon className="size-3" />}
                                            <span className="truncate">{chat.type === 'auction' ? chat.auction_title : chat.store_name}</span>
                                        </div>
                                        <p className={cn(
                                            "text-sm truncate mt-1",
                                            chat.unread_count > 0 ? "font-bold text-foreground" : "text-muted-foreground opacity-70"
                                        )}>
                                            {chat.last_message?.content || 'No messages yet'}
                                        </p>
                                    </div>

                                    {chat.unread_count > 0 && (
                                        <div className="size-5 rounded-full bg-primary text-[10px] font-bold text-white flex items-center justify-center">
                                            {chat.unread_count}
                                        </div>
                                    )}
                                </button>
                            ))
                        ) : (
                            <div className="py-20 text-center space-y-4 opacity-50">
                                <MessageSquare className="size-12 mx-auto" />
                                <p className="text-sm font-medium">No conversations yet</p>
                            </div>
                        )}
                    </div>
                </ScrollArea>
            </div>

            {/* Chat Area */}
            <div className={cn(
                "flex-1 flex flex-col bg-background",
                !selectedChat && "hidden md:flex items-center justify-center"
            )}>
                {selectedChat ? (
                    <>
                        {/* Header */}
                        <div className="p-4 md:p-6 border-b flex items-center justify-between">
                            <div className="flex items-center gap-4">
                                <Button variant="ghost" size="icon" className="md:hidden" onClick={() => setSelectedChat(null)}>
                                    <ArrowLeft className="size-5" />
                                </Button>
                                <Avatar className="size-10 rounded-lg">
                                    <AvatarImage src={activeChat?.type === 'auction' ? activeChat.participant_avatar : activeChat?.other_avatar} />
                                    <AvatarFallback>{activeChat?.type === 'auction' ? activeChat.participant_name?.[0] : activeChat?.other_name?.[0]}</AvatarFallback>
                                </Avatar>
                                <div>
                                    <h3 className="font-bold leading-none">
                                        {activeChat?.type === 'auction' ? activeChat.participant_name : activeChat?.other_name}
                                    </h3>
                                    <p className="text-xs text-muted-foreground mt-1 flex items-center gap-1">
                                        {activeChat?.type === 'auction' ? (
                                            <>
                                                <Gavel className="size-3" />
                                                Auction: {activeChat.auction_title}
                                            </>
                                        ) : (
                                            <>
                                                <StoreIcon className="size-3" />
                                                Store: {activeChat?.store_name}
                                                {activeChat?.product_title && ` • Product: ${activeChat.product_title}`}
                                            </>
                                        )}
                                    </p>
                                </div>
                            </div>
                            <Button variant="ghost" size="icon">
                                <MoreVertical className="size-5" />
                            </Button>
                        </div>

                        {/* Messages */}
                        <ScrollArea className="flex-1 p-6" viewportRef={scrollRef}>
                            <div className="space-y-6 flex flex-col-reverse">
                                {messages?.map((msg) => {
                                    const isMe = msg.sender_id === user?.id;
                                    return (
                                        <div key={msg.id} className={cn(
                                            "flex flex-col max-w-[80%]",
                                            isMe ? "ml-auto items-end" : "items-start"
                                        )}>
                                            <div className={cn(
                                                "p-4 rounded-2xl text-sm leading-relaxed",
                                                isMe ? "bg-primary text-white rounded-tr-none shadow-lg shadow-primary/20" : "bg-muted rounded-tl-none"
                                            )}>
                                                {msg.content}
                                            </div>
                                            <div className="flex items-center gap-1.5 mt-1.5 px-1">
                                                <span className="text-[10px] text-muted-foreground uppercase font-bold tracking-tighter">
                                                    {format(new Date(msg.created_at), 'HH:mm')}
                                                </span>
                                                {isMe && (
                                                    msg.is_read ? <CheckCheck className="size-3 text-primary" /> : <Check className="size-3 text-muted-foreground" />
                                                )}
                                            </div>
                                        </div>
                                    );
                                })}

                                {selectedChat.type === 'shop' && activeChat?.type === 'shop' && activeChat.product_title && (
                                    <div className="flex justify-center my-8">
                                        <div className="bg-muted/30 p-4 rounded-2xl flex items-center gap-3 max-w-sm border border-dashed">
                                            <div className="size-12 rounded-lg bg-background relative overflow-hidden flex-shrink-0">
                                                {activeChat.product_image ? (
                                                    <Image src={activeChat.product_image} alt="" fill className="object-cover" />
                                                ) : (
                                                    <Package className="size-6 text-muted-foreground absolute inset-0 m-auto" />
                                                )}
                                            </div>
                                            <div>
                                                <p className="text-xs text-muted-foreground font-bold uppercase">Topic: Product Inquiry</p>
                                                <p className="text-sm font-bold line-clamp-1">{activeChat.product_title}</p>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </ScrollArea>

                        {/* Input Area */}
                        <div className="p-6 border-t bg-background">
                            <form onSubmit={handleSend} className="flex items-center gap-4 bg-muted/30 p-2 rounded-2xl border">
                                <Button type="button" variant="ghost" size="icon" className="rounded-xl text-muted-foreground">
                                    <ImageIcon className="size-5" />
                                </Button>
                                <Input
                                    className="border-none bg-transparent focus-visible:ring-0 shadow-none h-10 px-0"
                                    placeholder="Type your message..."
                                    value={message}
                                    onChange={(e) => setMessage(e.target.value)}
                                />
                                <Button
                                    type="submit"
                                    size="icon"
                                    className="rounded-xl size-10 shrink-0"
                                    disabled={!message.trim() || sendMessageMutation.isPending}
                                >
                                    {sendMessageMutation.isPending ? <Loader2 className="size-4 animate-spin" /> : <Send className="size-4" />}
                                </Button>
                            </form>
                        </div>
                    </>
                ) : (
                    <div className="flex flex-col items-center justify-center p-12 text-center space-y-4">
                        <div className="size-20 bg-muted rounded-full flex items-center justify-center">
                            <MessageSquare className="size-10 text-muted-foreground/30" />
                        </div>
                        <h3 className="text-xl font-bold">Select a conversation</h3>
                        <p className="text-muted-foreground max-w-xs mx-auto">
                            Choose a chat from the left to start messaging. Your chats are categorized by auction or shop.
                        </p>
                    </div>
                )}
            </div>
        </div>
    );
}
