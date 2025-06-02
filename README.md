# Lejaao

An e-commerce application built with Flutter and Firebase

*Shopping itni simple, bas Lejaao.*

## Copyright Notice

The name "Lejaao" is a registered trademark and copyrighted. This name cannot be used by any individual or organization without explicit written permission from the copyright holder. All rights reserved.

## Overview

Lejaao is a fully-featured e-commerce mobile application that provides users with a seamless shopping experience. It includes user authentication, product browsing, search functionality, cart management, order processing, and an admin panel for managing products and orders.

## Features

### User Features
- **Authentication**: Sign up, login, and password recovery
- **Product Browsing**: View products with category filtering
- **Search**: Find products by name or description
- **Product Details**: View comprehensive product information
- **Shopping Cart**: Add, remove, and update quantities of products
- **Checkout Process**: Complete purchases with delivery details
- **Order History**: View past orders and their statuses
- **Profile Management**: Update personal information and delivery address

### Admin Features
- **Product Management**: Add, edit, and delete products
- **Order Management**: View all orders and update order statuses
- **User Management**: View all users and their details
- **Statistics**: View sales and user statistics (coming soon)

## Architecture

The application follows a Provider pattern for state management and uses Firebase for backend services:

- **UI Layer**: Flutter widgets organized into screens and components
- **State Management**: Provider package for reactive state updates
- **Service Layer**: Firebase services for authentication, storage, and database
- **Model Layer**: Data models representing domain entities

## Technologies Used

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Authentication: Firebase Auth
  - Database: Cloud Firestore
  - Storage: Firebase Storage (for product images)
- **State Management**: Provider
- **Packages**:
  - firebase_core
  - firebase_auth
  - cloud_firestore
  - provider
  - intl (for date formatting)
  - shared_preferences (for local storage)

## Getting Started

### Prerequisites
- Flutter SDK (version 3.8.0 or higher)
- Dart SDK (version 3.0.0 or higher)
- Firebase project setup

### Installation

1. Clone the repository:
```bash
git clone https://github.com/its-anya/lejaao.git
cd lejaao
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add an Android/iOS app to your Firebase project
   - Download and add the google-services.json (for Android) or GoogleService-Info.plist (for iOS) to your project
   - Enable Authentication (Email/Password) and Firestore Database

4. Run the application:
```bash
flutter run
```

## Firebase Structure

### Collections
- **users**: User information (profile data)
- **products**: Product information (name, description, price, etc.)
- **orders**: Order information (user, products, total, status)
- **admins**: Admin user information

### Security Rules
The application implements proper security rules to ensure that:
- Users can only access their own data
- Only admins can modify products
- Users can place orders and view their own orders
- Only admins can access and modify all orders

## Admin Setup

To set up an admin account:
1. Create a regular user account
2. Add the user's UID to the 'admins' collection in Firestore with the following structure:
```
{
  "isAdmin": true
}
```

## Troubleshooting

If you encounter any issues:
1. Make sure all dependencies are properly installed
2. Verify that Firebase is properly configured
3. Check Firebase Console for any authentication or database errors
4. Ensure your device has internet connectivity

## License

This project is proprietary and is NOT open source. All rights reserved.

The Lejaao project, including its source code, design, functionality, and name are fully protected by copyright law. No part of this project may be reproduced, distributed, or transmitted in any form or by any means, including photocopying, recording, or other electronic or mechanical methods, without the prior written permission of the copyright holder.

For permission requests, please contact the copyright owner.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for the robust backend services
