# FarmLink - App for Local Producers 🌾

**FarmLink** is a Flutter mobile application developed for a startup initiative at Instituto Politécnico de Setúbal (IPS). Its primary goal is to empower local farmers and producers by providing them with a complete digital storefront to manage their inventory, billing, and orders with real-time geolocation features.

## About the Project
This application focuses on the **Producer's Module**. It offers a centralized dashboard that manages the entire sales lifecycle: from adding stock and publishing advertisements on the "virtual market", to processing orders, calculating delivery routes, and generating PDF invoices. The entire system is built on a robust architecture connected to the **Firebase** ecosystem.

## Key Features

### Inventory Management & Virtual Market
* **CRUD Operations:** Add, edit, and delete products and advertisements.
* **Image Uploads:** Seamless integration with *Firebase Storage* to attach product photos directly from the device's gallery.
* **Advertisement Geolocation:** Utilizes `flutter_map` and `geolocator` to accurately pin the point of sale/pickup on the map when creating a new ad.
* **Smart Validation:** The system prevents the deletion of products that are currently linked to active advertisements.

### Order Processing & Routing
* **Real-Time Monitoring:** Track the lifecycle of orders (Pending, Accepted, Delivered, and Abandoned) using Firestore *Streams*.
* **Routes & Distances:** Calculates routes between the producer and the customer using the OpenStreetMap API and *OSRM*, drawing the exact path on the map and calculating the distance in kilometers.
* **Local Notifications:** Real-time push alerts whenever a new order enters the system, utilizing `flutter_local_notifications`.

### Financial Management & Invoicing
* **Revenue Dashboard:** Monitor transaction history and total accumulated revenue.
* **Automated PDF Invoices:** Generates professional-looking invoices using the `pdf` and `printing` packages, with the ability to save the file locally to the device's storage.

### Hardware & Smart Interface
* **Native Sensor Integration:** The app uses the device's ambient light sensor (via the `light` package) to detect environmental brightness and dynamically adapt the welcome message on the home screen.
* **Clean Architecture:** Implementation of the *Repository* pattern (e.g., `FinancialRepository`, `OrderRepository`) to strictly separate business logic from the UI.

## Tech Stack

**Frontend / Mobile:**
* [Flutter](https://flutter.dev/) & Dart (SDK ^3.7.2)
* `flutter_map` & `latlong2` (Native maps and navigation)
* `geolocator` (Location services)
* `pdf` & `printing` (Document rendering engine)
* `light` (Hardware sensor access)

**Backend as a Service (BaaS):**
* **Firebase Auth:** Secure user authentication.
* **Cloud Firestore:** Real-time NoSQL database.
* **Firebase Storage:** Cloud storage for visual assets.

## How to Run the Project

1. Clone this repository to your local machine:
   ```bash
   git clone [https://github.com/your-username/hello-farmer.git](https://github.com/your-username/hello-farmer.git)
2. Clone this repository to your local machine:
   ```bash
   cd hello-farmer
3. Install dependencies:
   ```bash
   flutter pub get
4. Configure Firebase:
   * Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/).
   * Add an Android and/or iOS app to the project and follow the instructions to download the `google-services.json` (for Android) or `GoogleService-Info.plist` (for iOS) files.
   * Place these files in the appropriate directories of your Flutter project (`android/app` for Android and `ios/Runner` for iOS).
   * Enable Firestore, Firebase Storage, and Firebase Authentication in the Firebase Console.

5. Run the app on an emulator or physical device:
   ```bash
    flutter run
## Authors
* Gonçalo Barracha - 202200187
* Rodrigo Cardoso - 202200197