# 🧾 BillSplit

BillSplit is a smart Flutter application designed to simplify restaurant bill splitting among friends. The app uses **on-device OCR technology** to scan restaurant bills, automatically extract items and prices, calculate fair individual shares including proportional taxes, and generate convenient **UPI payment requests**.

Built with a focus on **Clean Architecture, scalable Flutter development, and privacy**, BillSplit combines intelligent bill parsing, Firebase cloud services, and seamless UPI payment workflows to deliver a fast and reliable bill-splitting experience.

## 🚀 Key Features

### 1. **Smart Bill Scanning**

* **Camera & Gallery Support**: Capture restaurant bills directly using the camera or select existing images from the gallery.
* **Image Cropping**: Crop receipts before processing to improve OCR accuracy.
* **On-Device OCR**: Uses Google ML Kit Text Recognition to extract bill information without uploading receipt images to a server.
* **Intelligent Bill Parsing**: Converts OCR output into structured bill items, prices, taxes, subtotal, and total.
* **Manual Entry Fallback**: Skip OCR entirely (or add missed rows) by entering bill items by hand when scanning isn't possible or doesn't detect everything.

### 2. **Intelligent OCR Error Correction**

* **Arithmetic Validation**: Validates extracted values using the bill's own calculations.
* **OCR Error Handling**: Corrects common recognition errors such as currency symbols being interpreted as digits.
* **Receipt Row Reconstruction**: Reconstructs receipt rows using text positioning and bounding-box information.
* **Multiple Receipt Formats**: Handles different bill layouts and common receipt formatting variations.

### 3. **Fair Bill Splitting**

* **Item-Based Assignment**: Assign individual bill items to the friends who shared them.
* **Shared Items**: Automatically divides an item's cost equally between selected participants.
* **Proportional Tax Distribution**: Distributes taxes according to each person's item subtotal.
* **Paise-Safe Calculation**: Handles monetary rounding carefully for accurate settlements.

### 4. **UPI Payment System**

* **UPI Deep Links**: Generate payment links that can be opened using supported UPI applications.
* **UPI QR Codes**: Generate scannable QR codes containing the exact settlement amount.
* **Shareable Payment Requests**: Send settlement details through the device's native share functionality.
* **Reusable Payment Actions**: Re-send payment requests directly from saved bill history.

### 5. **Friends & Bill Management**

* **Friends Management**: Add, edit, search, and delete friends with optional UPI ID and phone information.
* **Bill History**: Store completed bills and access previous settlements.
* **Real-Time Synchronization**: Friends and bill history are synchronized using Cloud Firestore.
* **Offline-Aware Saving**: Firestore can queue writes locally and synchronize them when connectivity returns.

### 6. **Authentication & Security**

* **Email Authentication**: Sign up and sign in using email and password.
* **Google Sign-In**: Authenticate quickly using a Google account.
* **Password Recovery**: Built-in password reset functionality.
* **User-Specific Data**: Firestore data is organized and secured per authenticated user.

### 7. **Guided Onboarding**

* **First-Run Feature Tour**: Contextual showcase walkthroughs on the Home, Scan, Edit Items, Assign, and Results screens introduce key actions to new users.
* **Seen-Once Persistence**: Each walkthrough is shown only once per device using local `shared_preferences` storage.

---

## 🛠️ Technology Stack

### **Core Framework**

* **Flutter & Dart**: Cross-platform mobile application development.
* **Provider**: Application-level state management using `ChangeNotifier` and `StreamProvider`.
* **ValueNotifier**: Lightweight management of temporary and screen-specific UI state.

### **Firebase Services**

* **Firebase Authentication**: Email/password authentication and Google Sign-In.
* **Cloud Firestore**: Cloud database for friends and bill history.
* **Firestore Offline Persistence**: Supports locally queued writes and automatic synchronization.

### **OCR & Image Processing**

* **Google ML Kit Text Recognition**: On-device OCR processing for restaurant receipts.
* **Image Picker**: Camera and gallery image selection.
* **Image Cropper**: Receipt cropping before OCR processing.

### **Payment Integration**

* **UPI Deep Links**: Standard `upi://pay` URI-based payment requests.
* **QR Flutter**: Generates scannable UPI payment QR codes.
* **URL Launcher**: Opens UPI payment links in supported applications.
* **Share Plus**: Shares payment requests using the native system share sheet.

### **Additional Packages**

* **Equatable**: Value-based equality for domain models.
* **UUID**: Generates unique identifiers for application entities.
* **Intl**: Date and formatting utilities.
* **ShowcaseView**: Drives the first-run, contextual feature-tour overlays.
* **Shared Preferences**: Persists which onboarding walkthroughs a device has already seen.

---

## 🏗️ App Architecture

BillSplit follows a **feature-first Clean Architecture** approach designed to keep business logic independent, testable, and scalable.

### **Data Layer**

Handles communication with external services and data sources.

* Firebase Authentication
* Cloud Firestore repositories
* Google ML Kit OCR service

### **Domain Layer**

Contains framework-independent business logic.

* Bill parsing and OCR correction
* Settlement calculations
* Tax distribution
* Payment message generation

### **Presentation Layer**

Handles application UI and state management.

* Flutter screens and reusable widgets
* Provider-based application state
* ValueNotifier-based local UI state

This separation ensures that core business logic remains independent from Flutter UI and external services.

---

## 📁 Folder Structure

```text
lib/
├── main.dart
├── firebase_options.dart
│
├── app/
│   └── app.dart
│
├── core/
│   ├── constants/
│   ├── models/            # Bill, BillItem, Friend, Settlement, TaxLine
│   ├── theme/
│   └── utils/              # currency, validation, UPI link builder,
│                            # showcase keys & onboarding display service
│
├── shared/
│   ├── providers/          # BillFlowState (in-progress bill scan/split state)
│   └── widgets/            # AppButton, AppTextField, AppSnackbar, etc.
│
└── features/
    ├── splash/
    ├── auth/
    │   ├── data/
    │   └── presentation/
    │
    ├── home/
    │   └── presentation/
    │
    ├── friends/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    ├── scan/                # capture/crop/OCR + manual entry + item editing
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    ├── assign/              # assign scanned/manual items to friends
    │   ├── domain/
    │   └── presentation/
    │
    ├── results/             # settlement summary, restaurant/UPI details, save
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    ├── payment/             # UPI deep links, QR codes, share actions
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    └── history/
        ├── data/
        ├── domain/
        └── presentation/

test/
```

---

## 🔄 Application Flow

```text
Authentication
      ↓
Home & Friends
      ↓
Scan Restaurant Bill ──────────────┐
      ↓                            │ (no photo / nothing detected)
Crop Bill Image                    │
      ↓                            │
On-Device OCR                      │
      ↓                            │
Bill Parsing & Validation          │
      ↓                            ↓
Review & Edit Items  ←── Add Items Manually
      ↓
Assign Items to Friends
      ↓
Calculate Settlement Shares
      ↓
UPI Payment / QR / Share
      ↓
Save Bill to History
```

---

## 🗄️ Database Structure

The application uses **Cloud Firestore** as its primary cloud database.

```text
users/
└── {userId}/
    ├── friends/
    │   └── {friendId}
    │
    └── bills/
        └── {billId}
```

### **Friends Collection**

Stores:

* Friend name
* UPI ID
* Phone information

### **Bills Collection**

Stores:

* Restaurant information
* Bill items
* Tax details
* Total amount
* Individual settlement details
* Bill timestamp

All data is scoped to the authenticated user.

---

## ⚙️ Core Technical Implementation

### **OCR Processing**

Google ML Kit performs text recognition directly on the user's device. Receipt text is reconstructed using positional information before being passed to the bill parser.

### **Self-Correcting Bill Parser**

The custom Dart-based parser validates OCR results using mathematical relationships found within the receipt, including:

```text
Rate × Quantity = Amount

Items Total = Subtotal

Subtotal + Taxes = Grand Total
```

This approach helps identify and correct common OCR recognition errors without blindly modifying extracted values.

### **Settlement Calculation**

Each item's price is divided among the friends assigned to that item. Taxes are then distributed proportionally based on each person's item subtotal.

### **UPI Payment Workflow**

After calculating settlements, the application can generate:

* UPI payment deep links
* Scannable UPI QR codes
* Shareable payment request messages

---

## 🧪 Testing & Reliability

The project includes **39 unit and widget tests** covering important application logic, including:

* Bill parsing
* OCR correction scenarios
* Settlement calculations
* Domain models
* UPI link generation
* Flutter widgets

Real receipt scenarios are used as regression tests to prevent previously resolved parsing issues from reappearing.

---

## 🧩 Engineering Challenges & Solutions

* **Complex Receipt Layouts**: Reconstructed OCR text rows using bounding-box positions.
* **Incorrect OCR Values**: Applied arithmetic-based validation to identify and correct recognition errors.
* **Fair Tax Distribution**: Implemented proportional tax calculation with careful monetary rounding.
* **Android Process Death**: Added lost-image recovery to resume the bill scanning workflow.
* **Unreliable Connectivity**: Used Firestore's offline capabilities for queued data synchronization.
* **UPI Compatibility**: Provided QR codes alongside UPI deep links for broader payment compatibility.

---

## 🏃 Getting Started

### **Prerequisites**

* Flutter SDK with Dart `^3.10.0`
* Android Studio or VS Code
* Android device or emulator
* Firebase project

### **Installation**

1. **Clone the Repository**

```bash
git clone <repository-url>
cd bill_split
```

2. **Install Dependencies**

```bash
flutter pub get
```

3. **Configure Firebase**

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Enable the required authentication providers in the Firebase Console and configure Cloud Firestore.

4. **Run the Application**

```bash
flutter run
```

5. **Run Tests**

```bash
flutter test
```

---

## 📝 Development Standards

This project follows professional Flutter development practices:

* Feature-first Clean Architecture
* Separation of Data, Domain, and Presentation layers
* Reusable UI components
* Repository-based Firestore access
* Pure Dart business logic
* Scoped and efficient state management
* Secure user-specific Firestore data
* Automated unit and widget testing
* On-device OCR for improved data privacy

---

## 🎯 Project Highlights

BillSplit demonstrates practical experience with:

* Flutter & Dart application development
* Clean Architecture
* Provider state management
* Firebase Authentication & Firestore
* Google ML Kit and on-device OCR
* Custom receipt parsing algorithms
* Financial calculation and tax distribution
* UPI payment integration
* QR code generation
* Offline-aware application design
* Unit and widget testing
* Android lifecycle handling

---

Built with ❤️ using **Flutter & Dart**.
