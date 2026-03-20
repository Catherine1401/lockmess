# Lockmess 💬

**Lockmess** là ứng dụng nhắn tin thời gian thực dành cho iOS & Android, hỗ trợ chat 1-1, nhóm, kênh (channel) và quản lý bạn bè — được xây dựng bằng Flutter + Supabase.

[![Flutter Version](https://img.shields.io/badge/Flutter-3.29+-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.9+-blue.svg?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## ✨ Demo / Screenshots

> _Ảnh / GIF demo sẽ được cập nhật tại đây._

| Login | Chat | Profile |
|-------|------|---------|
| ![Login](screenshots/login.png) | ![Chat](screenshots/chat.png) | ![Profile](screenshots/profile.png) |

---

## 📱 Features

- [x] **Đăng nhập** bằng Google (Supabase Auth)
- [x] **Chat 1-1** — nhắn tin thời gian thực
- [x] **Group chat** — tạo nhóm (tối thiểu 3 thành viên), drawer thông tin nhóm
- [x] **Channel** — tạo kênh, tham gia kênh, gợi ý kênh theo sở thích
- [x] **Tìm kiếm conversation** — tìm nhanh cuộc trò chuyện
- [x] **Quản lý bạn bè** — tìm kiếm, gửi lời mời, xem profile bạn bè
- [x] **Trạng thái Online / Offline** — presence service thời gian thực
- [x] **Profile** — xem & chỉnh sửa thông tin cá nhân, sở thích (hobbies)
- [x] **Settings** — màn hình cài đặt
- [x] **State Management** — Riverpod
- [x] **Routing** — GoRouter (StatefulShellRoute bottom nav)
- [ ] Apple Sign-In
- [ ] Push notifications
- [ ] Offline support / caching

---

## 🚀 Getting Started

### Prerequisites

- Flutter `3.29+`
- Dart `3.9+`
- Android Studio / VS Code + Flutter extension
- Tài khoản [Supabase](https://supabase.com)
- Google OAuth credentials (Web Client ID & iOS Client ID)

### Installation

1. **Clone repo**
   ```bash
   git clone https://github.com/Catherine1401/lockmess.git
   cd lockmess
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Cấu hình environment**

   Tạo file `.env` hoặc truyền qua `--dart-define`:

   | Biến | Mô tả |
   |------|-------|
   | `SUPABASE_URL` | URL project Supabase |
   | `SUPABASE_KEY` | Anon/public key Supabase |
   | `WEB_CLIENT_ID` | Google OAuth Web Client ID |
   | `IOS_CLIENT_ID` | Google OAuth iOS Client ID |

4. **Run app**
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=your_supabase_url \
     --dart-define=SUPABASE_KEY=your_supabase_key \
     --dart-define=WEB_CLIENT_ID=your_web_client_id \
     --dart-define=IOS_CLIENT_ID=your_ios_client_id
   ```

---

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/        # AppColors
│   ├── network/          # Supabase client, authProvider
│   ├── services/         # PresenceService (online/offline)
│   ├── utils/            # GetUserInfo mixin
│   └── widgets/          # RootScreen (shell + bottom nav + appbar)
├── features/
│   ├── login/            # Google Sign-In
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── profile/          # Xem & chỉnh sửa profile
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── friends/          # Quản lý bạn bè, tìm kiếm, xem profile
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── chats/            # Chat 1-1, group chat, channel
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/         # Cài đặt
│       └── presentation/
└── main.dart
```

**Pattern:** Feature-based + Clean Architecture (domain / data / presentation)  
**State management:** Riverpod (`AsyncNotifierProvider`, `StreamProvider`, `NotifierProvider`)

---

## 🛠️ Tech Stack

| Thành phần | Thư viện |
|---|---|
| UI | `Flutter` + `shadcn_ui` |
| State | `flutter_riverpod` |
| Routing | `go_router` |
| Backend / Auth | `supabase_flutter` |
| Google Login | `google_sign_in` |
| Fonts | `google_fonts` (Roboto, Poppins) |
| SVG | `flutter_svg` |
| Ảnh từ mạng | `cached_network_image` |
| Gradient text | `simple_gradient_text` |
| Sliver | `sliver_tools` |

---

## 🗄️ Supabase Schema (các bảng chính)

| Bảng | Mô tả |
|------|-------|
| `profiles` | Thông tin người dùng |
| `hobbies` | Sở thích (quan hệ nhiều-nhiều với profiles) |
| `conversations` | Cuộc trò chuyện (1-1, group, channel) |
| `messages` | Tin nhắn |

---

## 🧪 Testing

```bash
flutter test
```

---

## 🤝 Contributing

1. Fork repo
2. Tạo branch: `git checkout -b feature/amazing-feature`
3. Commit: `git commit -m 'feat: add amazing feature'`
4. Push: `git push origin feature/amazing-feature`
5. Mở Pull Request vào `main`

---

## 📄 License

Distributed under the MIT License.

---

## 📧 Contact

**Catherine** — [@Catherine1401](https://github.com/Catherine1401)

Project Link: [https://github.com/Catherine1401/lockmess](https://github.com/Catherine1401/lockmess)
