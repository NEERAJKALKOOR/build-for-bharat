 Namma Kirani (Bharat Store) 🏪🇮🇳

**Offline-First Inventory, Billing & Analytics App for Indian Kirana Stores.**

Namma Kirani is a smart digital assistant designed to empower small shop owners ("Kirana stores") in India. It enables them to manage inventory, generate bills, and track business health **without needing an active internet connection** or complex computer setups.

---

## 🌟 Key Features

*   **📱 Offline-First Architecture**: Built on **Hive**, ensuring 100% functionality without the internet.
*   **🗣️ Local Language Support**: Full interface translation in **Kannada** (and extensible to others) for better accessibility.
*   **🛒 Smart Inventory**: Add products instantly by scanning barcodes using **OpenFoodFacts API** integration.
*   **⚡ Fast Billing**: Quick cart management and invoice generation designed for high-motion retail environments.
*   **💸 UPI Integration**: Generate static **UPI QR Codes** offline for zero-fee payments via PhonePe, GPay, or Paytm.
*   **📈 Analytics Dashboard**: Visual insights into "Today's Sales," "Top Selling Items," and "Dead Stock" alerts.
*   **☁️ Cloud Backup (Optional)**: Secure backup to **Supabase** for users who want data redundancy.
*   **🔐 Secure Login**: OTP-based authentication (via Email) and PIN protection.

---

## 🛠️ Tech Stack

*   **Framework**: Flutter (Dart)
*   **State Management**: Provider
*   **Database**: Hive (NoSQL, Local)
*   **Cloud Backend**: Supabase (Backup & Auth)
*   **External APIs**:
    *   OpenFoodFacts (Product Metadata)
    *   Gmail SMTP (OTP Services)
    *   Google ML Kit (Barcode Scanning)
*   **Key Libraries**: `mobile_scanner`, `qr_flutter`, `fl_chart`, `intl`.

---


## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (3.0+)
*   Dart SDK

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/namma-kirani.git
    cd namma-kirani
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the App:**
    ```bash
    flutter run
    ```
    *(Note: Connect an Android device/emulator for the best experience, especially for camera features).*

---


## 📂 Project Structure

*   `lib/models`: Hive Data Models (Product, Bill, UserSession).
*   `lib/providers`: Business Logic (Inventory, Billing, Auth).
*   `lib/screens`: UI Screens (Dashboard, Billing, Login).
*   `lib/services`: External Interactions (Supabase, API, SMTP).
*   `lib/l10n`: Localization Strings.

---

Made with ❤️ for **Build for Bharat**.
