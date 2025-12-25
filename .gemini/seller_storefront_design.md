# 🏪 Seller Storefront Design Document
## AirMass - Empowering Zimbabwe's SME Economy

---

## 🎯 Vision
Transform every seller into a **"digital business"** with their own storefront, making it easy for customers to discover, trust, and buy from SME owners across Zimbabwe.

---

## 📊 Market Context (Zimbabwe)
- **90% of workforce** in informal sector
- Most SMEs lack online presence
- **Trust is everything** - buyers need confidence before purchase
- **WhatsApp is king** - primary business communication
- **Mobile-first** - smartphone penetration high, but data expensive
- **Community-driven** - word-of-mouth critical

---

## 🏗️ Core Architecture

### Storefront = Enhanced Seller Profile
- Every verified seller gets a **Storefront** (public shop page)
- Appears at: `/store/{username}` or `/store/{store_slug}`
- Combines: About + Products + Reviews + Badges + Contact

---

## 📦 Feature Breakdown

### 1. Storefront Profile
| Field | Description | Required |
|-------|-------------|----------|
| Store Name | Business/brand name | ✅ |
| Store Logo | Square image for branding | Optional |
| Cover Image | Banner (header) image | Optional |
| Tagline | Short description (max 100 chars) | ✅ |
| About | Full description, story, services | Optional |
| Category | Primary business type | ✅ |
| Location | Town + suburb (from existing) | ✅ |
| Operating Hours | Mon-Sun schedule | Optional |
| Contact WhatsApp | WhatsApp number | ✅ (primary contact) |
| Contact Phone | Regular phone | Optional |
| Delivery Options | Pickup / Local Delivery / Nationwide | ✅ |
| Delivery Radius | km for local delivery | Optional |

### 2. Product Catalog (NEW - Fixed Price Items)
**Key insight**: Not everything is an auction! SMEs need fixed-price products too.

| Type | Description |
|------|-------------|
| **Auction** | Existing - timed bidding |
| **Fixed Price** | Buy Now at set price |
| **Negotiable** | Price is starting point, offers welcome |
| **Service** | Hourly/project-based service listings |

### 3. Store Categories (New Table)
```
- Electronics & Gadgets
- Fashion & Clothing
- Beauty & Personal Care
- Food & Groceries
- Home & Garden
- Automotive
- Farming & Agriculture
- Services & Skills
- Crafts & Handmade
- Other
```

### 4. Trust Indicators for Storefronts
| Indicator | Criteria | Visual |
|-----------|----------|--------|
| 🔵 Verified Seller | ID Verified | Blue checkmark |
| 🟢 Trusted Store | 10+ sales, 4.0+ rating | Green badge |
| 🟡 Top Rated | 4.8+ rating, 50+ reviews | Gold star |
| 📍 Local Seller | In your town | Location tag |
| ⚡ Quick Responder | <1hr avg response | Lightning bolt |
| 📦 Ships Nationwide | Delivery available | Truck icon |

### 5. Analytics Dashboard (Seller View)
- Store views this week/month
- Product views
- Enquiries received
- Conversion rate
- Top-performing products
- Customer locations (towns)

---

## 📱 UI/UX Design

### Storefront Page Layout
```
┌─────────────────────────────────┐
│        COVER IMAGE              │
│  ┌───────┐                      │
│  │ LOGO  │  Store Name          │
│  │  📷   │  ⭐ 4.8 (125 reviews)│
│  └───────┘  📍 Harare, Avondale │
├─────────────────────────────────┤
│  "Quality electronics since 2018"│
├─────────────────────────────────┤
│ [WhatsApp📱] [Call📞] [Follow❤️]│
├─────────────────────────────────┤
│ 🏷️ TABS: Products | About | Reviews
├─────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐         │
│ │ 📦  │ │ 📦  │ │ 📦  │         │
│ │ R50 │ │R120 │ │R300 │  Grid   │
│ └─────┘ └─────┘ └─────┘         │
└─────────────────────────────────┘
```

### Storefront Discovery
1. **Explore Stores Tab** in home (new bottom nav item)
2. **Browse by Category**
3. **Search stores by name/product**
4. **Nearby Stores** (same town)
5. **Featured Stores** (promoted)

### Customer Journey
1. Browse auctions → see seller has store → visit store
2. Explore stores → browse categories → find store
3. Search product → see store results → visit store
4. Friend shares store link → direct visit

---

## 🗄️ Database Schema

### New Tables

```sql
-- Store profiles (extends users)
CREATE TABLE stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    store_name VARCHAR(100) NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    tagline VARCHAR(100),
    about TEXT,
    logo_url TEXT,
    cover_url TEXT,
    category VARCHAR(50),
    whatsapp VARCHAR(20),
    phone VARCHAR(20),
    delivery_options TEXT[], -- ['pickup', 'local', 'nationwide']
    delivery_radius_km INT,
    operating_hours JSONB,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    total_products INT DEFAULT 0,
    total_sales INT DEFAULT 0,
    follower_count INT DEFAULT 0,
    avg_response_time_minutes INT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Store categories for browsing
CREATE TABLE store_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    icon VARCHAR(50),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

-- Products (fixed price items - separate from auctions)
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(12,2) NOT NULL,
    compare_at_price DECIMAL(12,2), -- original price (for discounts)
    pricing_type VARCHAR(20) DEFAULT 'fixed', -- fixed, negotiable, auction
    category_id UUID REFERENCES categories(id),
    condition VARCHAR(20),
    images TEXT[],
    stock_quantity INT DEFAULT 1,
    is_available BOOLEAN DEFAULT true,
    views INT DEFAULT 0,
    enquiries INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Store followers
CREATE TABLE store_followers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    followed_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(store_id, user_id)
);

-- Store enquiries (when customer contacts seller)
CREATE TABLE store_enquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id),
    product_id UUID REFERENCES products(id),
    customer_id UUID NOT NULL REFERENCES users(id),
    message TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, responded, converted, closed
    created_at TIMESTAMP DEFAULT NOW()
);

-- Store analytics (aggregated daily)
CREATE TABLE store_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id),
    date DATE NOT NULL,
    views INT DEFAULT 0,
    unique_visitors INT DEFAULT 0,
    product_views INT DEFAULT 0,
    enquiries INT DEFAULT 0,
    whatsapp_clicks INT DEFAULT 0,
    call_clicks INT DEFAULT 0,
    follows_gained INT DEFAULT 0,
    UNIQUE(store_id, date)
);
```

---

## 🔌 API Endpoints

### Store Management
```
POST   /api/stores                  - Create store
GET    /api/stores/:slug            - Get store by slug
PUT    /api/stores/me               - Update my store
GET    /api/stores/me               - Get my store
GET    /api/stores/me/analytics     - Get analytics dashboard
DELETE /api/stores/me               - Deactivate store
```

### Store Discovery
```
GET    /api/stores                  - List stores (with filters)
GET    /api/stores/categories       - Get store categories
GET    /api/stores/featured         - Featured stores
GET    /api/stores/nearby           - Stores in user's town
GET    /api/stores/search?q=term    - Search stores
```

### Products
```
POST   /api/stores/me/products      - Add product
GET    /api/stores/:slug/products   - Store's products
PUT    /api/products/:id            - Update product
DELETE /api/products/:id            - Delete product
```

### Engagement
```
POST   /api/stores/:id/follow       - Follow store
DELETE /api/stores/:id/follow       - Unfollow store
GET    /api/stores/:id/followers    - Store's followers
GET    /api/users/me/following      - Stores I follow
POST   /api/stores/:id/enquiry      - Send enquiry
POST   /api/stores/:id/track        - Track view/click
```

---

## 📱 Mobile Screens (New)

| Screen | Description |
|--------|-------------|
| **ExploreStoresScreen** | Browse stores by category, nearby, featured |
| **StorefrontScreen** | Public store view with tabs |
| **CreateStoreScreen** | Onboarding wizard to set up store |
| **EditStoreScreen** | Update store details |
| **StoreProductsScreen** | Manage my products |
| **AddProductScreen** | Add new product |
| **StoreAnalyticsScreen** | View store performance |
| **FollowingStoresScreen** | Stores I follow |
| **ProductDetailScreen** | View single product |

---

## 🚀 User Retention Strategies

### For Sellers (SME Owners)
1. **Onboarding Reward** - First 3 products free promotion
2. **Milestone Badges** - "10 Products", "First Sale", "100 Followers"
3. **Weekly Performance Email** - Store stats summary
4. **Feature Boost** - High-rated stores get homepage exposure
5. **Quick Actions** - Easy product repost, duplicate

### For Buyers
1. **Follow Stores** - Get notified of new products
2. **Save Products** - Wishlist functionality
3. **Store Recommendations** - Based on purchase history
4. **Store Reviews** - Contribute to community trust
5. **Exclusive Deals** - Followers-only promotions

---

## 🎨 UX Best Practices

### Mobile-Optimized
- Large tap targets (48px minimum)
- Bottom sheet for actions (not modals)
- Pull-to-refresh everywhere
- Skeleton loading states
- Offline-friendly (cached data)

### Low-Data Mode
- Lazy load images
- Thumbnail-first, full image on tap
- Text-first layouts
- Compress all uploads

### Trust Building
- Verification badges prominent
- Review snippets on store card
- "Active X hours ago" indicator
- Response time badge

---

## 📋 Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Database tables
- [ ] Store CRUD APIs
- [ ] Create Store wizard
- [ ] Basic storefront view

### Phase 2: Products (Week 2)
- [ ] Product catalog APIs
- [ ] Add/Edit products
- [ ] Product detail screen
- [ ] Fixed-price "Buy Now" flow

### Phase 3: Discovery (Week 3)
- [ ] Explore stores screen
- [ ] Category browsing
- [ ] Search functionality
- [ ] Nearby stores

### Phase 4: Engagement (Week 4)
- [ ] Follow/Unfollow
- [ ] Enquiry system
- [ ] Analytics dashboard
- [ ] Notifications for followers

---

## 🎯 Success Metrics

| Metric | Target (3 months) |
|--------|-------------------|
| Stores created | 500+ |
| Products listed | 5,000+ |
| Store followers per store | 50+ avg |
| Monthly store visits | 10,000+ |
| Enquiry-to-sale rate | 20%+ |
| Seller retention (3mo) | 70%+ |

---

## 💡 Zimbabwe-Specific Features

1. **WhatsApp Primary** - One-tap WhatsApp chat
2. **EcoCash/InnBucks Ready** - Payment method badges
3. **Offline Product Creation** - Draft and sync later
4. **Low-Data Mode** - Compressed images, text-first
5. **Shona/Ndebele** - Future localization ready
6. **Town Markets** - Highlight local stores first

---

## 🔐 Security & Trust

- Verified sellers only can create stores
- Product moderation queue
- Report store/product functionality
- Fraud detection (duplicate images, spam)
- Store suspension for violations

---

*This design is production-ready and optimized for Zimbabwe's SME economy. Ready to implement?*
