import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/national_auctions_screen.dart';
import '../screens/auction/auction_detail_screen.dart';
import '../screens/auction/create_auction_screen.dart';
import '../screens/auction/auction_states_screen.dart';
import '../screens/auction/filtered_auctions_screen.dart';
import '../screens/category/category_browser_screen.dart';
import '../screens/category/category_feed_screens.dart';
import '../screens/suburb/suburb_screens.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/profile_management_screens.dart';
import '../screens/notification/notification_inbox_screen.dart';
import '../screens/notification/notification_detail_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/chat/chat_screens.dart';
import '../screens/search/search_results_screen.dart';
import '../screens/search/national_search_screen.dart';
import '../screens/user/user_screens.dart';
import '../screens/legal/legal_screens.dart';
import '../screens/states/error_states_screen.dart';
import '../screens/rating/rate_user_screen.dart';
import '../screens/rating/user_reviews_screen.dart';
import '../screens/profile/verification_screen.dart';
import '../screens/store/create_store_screen.dart';
import '../screens/store/storefront_screen.dart';
import '../screens/store/store_products_screen.dart';
import '../screens/store/product_detail_screen.dart';
import '../screens/store/store_explore_screen.dart';

/// Global navigator key
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// App router configuration
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Splash
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    
    // Onboarding
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    
    // Auth
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(
      path: '/verify-email/:email',
      builder: (_, state) => EmailVerificationScreen(email: state.pathParameters['email'] ?? ''),
    ),
    
    // Home
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/national', builder: (_, __) => const NationalAuctionsScreen()),
    
    // Auctions
    GoRoute(
      path: '/auction/:id',
      builder: (_, state) => AuctionDetailScreen(auctionId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(path: '/create-auction', builder: (_, __) => const CreateAuctionScreen()),
    GoRoute(
      path: '/auctions/filtered',
      builder: (_, state) => FilteredAuctionsScreen(
        title: state.uri.queryParameters['title'] ?? 'Auctions',
        filterType: state.uri.queryParameters['filter'] ?? 'fresh',
        townId: state.uri.queryParameters['townId'],
        categoryId: state.uri.queryParameters['categoryId'],
        suburbId: state.uri.queryParameters['suburbId'],
      ),
    ),
    GoRoute(
      path: '/auction/:id/ended',
      builder: (_, state) => AuctionEndedScreen(auctionId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/auction/:id/seller',
      builder: (_, state) => AuctionSellerViewScreen(auctionId: state.pathParameters['id'] ?? ''),
    ),
    
    // Categories
    GoRoute(path: '/categories', builder: (_, __) => const CategoryBrowserScreen()),
    GoRoute(
      path: '/category/:id',
      builder: (_, state) => CategoryFeedTownScreen(
        categoryId: state.pathParameters['id'] ?? '',
        categoryName: state.uri.queryParameters['name'] ?? 'Category',
        townId: state.uri.queryParameters['townId'] ?? '',
        townName: state.uri.queryParameters['town'] ?? 'Harare',
      ),
    ),
    GoRoute(
      path: '/category/:id/national',
      builder: (_, state) => CategoryFeedNationalScreen(
        categoryId: state.pathParameters['id'] ?? '',
        categoryName: state.uri.queryParameters['name'] ?? 'Category',
      ),
    ),
    
    // Suburbs
    GoRoute(
      path: '/suburbs/:townId',
      builder: (_, state) => SuburbSelectorScreen(
        townId: state.pathParameters['townId'] ?? '',
        townName: state.uri.queryParameters['name'] ?? 'Town',
      ),
    ),
    GoRoute(
      path: '/suburb/:id/auctions',
      builder: (_, state) => SuburbAuctionFeedScreen(
        suburbId: state.pathParameters['id'] ?? '',
        suburbName: state.uri.queryParameters['name'] ?? 'Suburb',
        townName: state.uri.queryParameters['town'] ?? 'Town',
      ),
    ),
    
    // Profile
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: '/profile/auctions', builder: (_, __) => const MyAuctionsScreen()),
    GoRoute(path: '/profile/bids', builder: (_, __) => const BidHistoryScreen()),
    GoRoute(path: '/profile/won', builder: (_, __) => const WonItemsScreen()),
    GoRoute(path: '/profile/watchlist', builder: (_, __) => const WatchlistScreen()),
    GoRoute(path: '/profile/verification', builder: (_, __) => const VerificationScreen()),
    
    // User profiles (other users)
    GoRoute(
      path: '/user/:id',
      builder: (_, state) => UserProfileScreen(userId: state.pathParameters['id'] ?? ''),
    ),

    // Store Routes
    GoRoute(path: '/store/create', builder: (_, __) => const CreateStoreScreen()),
    GoRoute(path: '/stores', builder: (_, __) => const StoreExploreScreen()),
    GoRoute(
      path: '/store/:slug',
      builder: (_, state) => StorefrontScreen(slug: state.pathParameters['slug'] ?? ''),
    ),
    GoRoute(path: '/store/manage/products', builder: (_, __) => const StoreProductsScreen()),
    GoRoute(
      path: '/product/:id',
      builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/rate/:userId',
      builder: (_, state) => RateUserScreen(
        userId: state.pathParameters['userId'] ?? '',
        auctionId: state.uri.queryParameters['auctionId'],
      ),
    ),
    GoRoute(
      path: '/user/:id/reviews',
      builder: (_, state) => UserReviewsScreen(userId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(path: '/waiting-list', builder: (_, __) => const WaitingListScreen()),
    
    // Notifications
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationInboxScreen()),
    GoRoute(
      path: '/notification/:id',
      builder: (_, state) => NotificationDetailScreen(notificationId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(path: '/notifications/preferences', builder: (_, __) => const NotificationPreferencesScreen()),
    
    // Settings
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    
    // Chat
    GoRoute(path: '/chats', builder: (_, __) => const ChatListScreen()),
    GoRoute(
      path: '/chats/:id',
      builder: (_, state) => ChatDetailScreen(chatId: state.pathParameters['id'] ?? ''),
    ),
    
    // Search
    GoRoute(
      path: '/search',
      builder: (_, state) => SearchResultsScreen(query: state.uri.queryParameters['q'] ?? ''),
    ),
    GoRoute(
      path: '/search/national',
      builder: (_, __) => const NationalSearchScreen(),
    ),
    
    // Legal
    GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
    GoRoute(path: '/privacy', builder: (_, __) => const PrivacyPolicyScreen()),
    GoRoute(path: '/terms', builder: (_, __) => const TermsOfServiceScreen()),
    GoRoute(path: '/help', builder: (_, __) => const HelpSupportScreen()),
    
    // Error states
    GoRoute(path: '/session-expired', builder: (_, __) => const SessionExpiredScreen()),
    GoRoute(path: '/offline', builder: (_, __) => const NetworkOfflineScreen()),
    GoRoute(
      path: '/category-full/:id',
      builder: (_, state) => CategoryFullScreen(
        categoryName: state.uri.queryParameters['name'] ?? 'Category',
        waitingPosition: int.tryParse(state.uri.queryParameters['position'] ?? '0') ?? 0,
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Page not found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(state.uri.toString(), style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
