# Instruction

Files that been done until now:
lib/
├── models/
│   ├── chat_model.dart
│   ├── order_model.dart
│   ├── product_model.dart
│   ├── rating_model.dart
│   └── user_model.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── chat_provider.dart
│   ├── favorite_provider.dart
│   ├── product_provider.dart
│   └── user_provider.dart
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   │
│   ├── chat/
│   │   └── screen/
│   │       ├── chat_list_screen.dart
│   │       └── chat_screen.dart
│   │
│   ├── home/
│   │   ├── components/
│   │   │   ├── chats_tab.dart
│   │   │   ├── favorites_tab.dart
│   │   │   ├── home_tab.dart
│   │   │   ├── profile_tab.dart
│   │   │   └── sell_tab.dart
│   │   └── home_screen.dart
│   │
│   └── product/
│       └── widgets/
│           ├── add_product_screen.dart
│           └── product_detail_screen.dart
│
├── firebase_options.dart
└── main.dart


### *Core Features :*

- User authentication (sign up, login, logout)  ✅
- Product listing and posting ✅
- Basic product browsing/search ✅
- User profiles ✅
- Firebase backend integration ✅

### *Advanced Features  :*

- Real-time chat between buyers/sellers ✅
- Image upload for prod ucts ✅
- Categories and filtering  ✅
- Favorites/wishlist functionality ✅
- Buyer should able counter the offer (it would be different from chat) 
  - if seller agree he can generate a qr to pay that amount to buyer.
  - or else seller can give counter offer again and buyer can accept and they can procide further.
- **Shipping Options for Seller**
  - Choose between courier or speed post
  - Could be a dropdown or input field when listing
- **Order Tracking Info from Seller - Tracking number, Shipping method info**
- **Rating System -** After a transaction, users should be able to Rate the other party
- mockup payment page. 

## *Your Role as Your Development Partner:*

✅ *Code Generation:* You'll write complete, working Flutter code for each feature
✅ *Firebase Setup:* Guide me through Firebase project setup and configuration

✅ *Dependency Management:* Use modern, compatible packages to avoid version conflicts
✅ *Step-by-Step Guidance:* Break down complex features into manageable chunks
✅ *Troubleshooting:* Help debug any issues that arise
✅ *Best Practices:* Implement clean architecture and proper state management

## *My Role:*

- Run the code you provide
- Set up Firebase project (you'll guide me)
- Test features and provide feedback
- Handle any Android Studio/IDE setup issues



## *Prerequisites:*

- Flutter (Channel stable, 3.32.2, on Microsoft Windows [Version 10.0.26100.4349], locale en-IN)
- Flutter 3.32.2 • channel stable
Framework • revision 8defaa71a7 (7 days ago) • 2025-06-04 11:02:51 -0700
Engine • revision 1091508939 (12 days ago) • 2025-05-30 12:17:36 -0700
Tools • Dart 3.8.1 • DevTools 2.45.1
- Windows Version (Windows 11 or higher, 24H2, 2009)
- Android toolchain - develop for Android devices (Android SDK version 35.0.1)
- Android Studio (version 2024.2) /  VS Code (version 1.100.3)
- Android emulator or physical device
- Firebase account (free)


