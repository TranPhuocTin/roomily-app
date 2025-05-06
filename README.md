# Roomily

Roomily is a Flutter-based mobile application that provides a comprehensive solution for room management and related services.

## Features

- **User Authentication**
  - Secure login and registration system
  - Social media login integration (Google, Facebook)
  - Multi-language support (Vietnamese, English, Japanese)
  - OTP verification

- **Room Management**
  - Advanced room search with filters
  - Detailed room listings with images and amenities
  - Favorites system for saving preferred rooms
  - Room recommendation engine
  - QR code integration for room verification

- **Landlord Features**
  - Dashboard for property overview
  - Room listing management (add, edit, delete properties)
  - Tenant management system
  - Rent request handling
  - Financial tracking and reporting
  - Contract management with PDF generation

- **Tenant Features**
  - Room booking and reservation
  - Contract viewing and management
  - Utility consumption reporting
  - Bill payment tracking
  - Move-out procedures

- **Billing & Payments**
  - Automated billing system
  - Utility tracking (electricity and water)
  - Payment processing
  - Payment history and receipts
  - Bill status monitoring (pending, paid, missing)

- **Contract Management**
  - Digital contract generation
  - Custom contract templates
  - Contract signing process
  - PDF download functionality
  - Responsibilities tracking

- **Location Services**
  - Integration with Google Maps
  - Geolocation for finding nearby properties
  - Map-based room search
  - Address validation

- **Communication**
  - Real-time messaging using STOMP protocol
  - Chat between landlords and tenants
  - Notification system
  - Reminders for payments and utility readings

- **Additional Services**
  - Moving/relocation services
  - Cost calculation tools
  - Budget planning features
  - Property analytics

- **Security & Privacy**
  - Secure storage for sensitive information
  - Permission management
  - Data encryption

- **UI/UX Features**
  - Responsive and intuitive interface
  - Light/dark mode support
  - Beautiful animations and transitions
  - Banner sliders and feature highlights
  - Cross-platform consistency

## Tech Stack

- **Framework**: Flutter
- **State Management**: BLoC Pattern
- **Navigation**: Go Router
- **Dependency Injection**: GetIt
- **Networking**: Dio
- **Local Storage**: Shared Preferences, Secure Storage
- **Maps**: Google Maps Flutter
- **Real-time Communication**: STOMP
- **Push Notifications**: Firebase Cloud Messaging
- **UI Components**: 
  - Flutter Animate
  - Glassmorphism
  - Shimmer
  - Curved Navigation Bar
  - Smooth Page Indicator

## Getting Started

### Prerequisites

- Flutter SDK (>=3.2.3)
- Dart SDK (>=3.2.3)
- Android Studio / VS Code
- Android SDK / iOS Development Tools

### Installation

1. Clone the repository:
```bash
git clone [repository-url]
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/           # Core functionality and utilities
├── data/           # Data layer (repositories, data sources)
├── presentation/   # UI layer (screens, widgets)
├── screens/        # Application screens
├── widgets/        # Reusable widgets
└── main.dart       # Application entry point
```

## Dependencies

The project uses several key packages:
- flutter_bloc: For state management
- dio: For network requests
- go_router: For navigation
- get_it: For dependency injection
- firebase_core & firebase_messaging: For push notifications
- google_maps_flutter: For map integration
- And many more (see pubspec.yaml for complete list)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For any queries or support, please contact the development team.
