# 📱 Google Play Store Publishing & Technical Requirements Guide

This comprehensive guide outlines all administrative, technical, and policy prerequisites required to publish and maintain an Android app on the Google Play Store.

---

## 1. 🏢 Developer Account Requirements

* **Google Play Developer Account Registration:**
  * Must register at the [Google Play Console](https://play.google.com/console).
  * Pay a **one-time registration fee of $25 USD**.
* **Identity Verification:**
  * **Individual Accounts:** Government-issued photo ID (passport, driver's license) and address verification.
  * **Organization/Business Accounts:** Valid **D-U-N-S Number** (Dun & Bradstreet), official organization documentation, and authorized representative verification.

---

## 2. ⚙️ Technical & File Requirements

* **Standard App Format (Android App Bundle - `.aab`):**
  * Google Play requires new apps to be uploaded as **Android App Bundles (`.aab`)**, not traditional `.apk` files.
  * Google's dynamic delivery system uses the `.aab` to generate optimized APKs tailored to each user's device configuration (screen density, CPU architecture, language).
* **Digital Cryptographic Signature:**
  * The release bundle must be digitally signed with a cryptographic private key.
  * Command to generate a release keystore:
    ```bash
    keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-app-key
    ```
* **Play App Signing:**
  * Enrollment in **Google Play App Signing** is required.
  * Google manages and securely protects your app's signing key on its infrastructure and uses it to sign APKs delivered to users.
* **Target API Level:**
  * Must target the recent Android API level mandated by Google Play policies (typically Android 14 / API 34+ or higher).
* **Incrementing Version Code (`versionCode`):**
  * Every new release uploaded to the Play Console must have a **strictly higher integer `versionCode`** than the previous build (e.g., `1`, `2`, `3`).
  * In Capacitor/Android, this is configured in `android/app/build.gradle`:
    ```groovy
    defaultConfig {
        versionCode 2
        versionName "1.0.1"
    }
    ```
* **Download Size Limits:**
  * The maximum compressed download size for individual APKs generated from bundles is **200 MB**.
  * Apps requiring larger asset footprints must implement Play Feature Delivery or Play Asset Delivery.

---

## 3. 🎨 Store Listing & Policy Prerequisites

* **Store Listing Assets:**
  * **App Name:** Up to 30 characters.
  * **Short Description:** Up to 80 characters.
  * **Full Description:** Up to 4,000 characters.
  * **High-Resolution App Icon:** Exactly `512 x 512 px`, 32-bit PNG, up to 1 MB.
  * **Feature Graphic:** Exactly `1024 x 500 px`, JPG or 24-bit PNG, no transparency.
  * **Screenshots:** Minimum of 2 phone screenshots (JPEG or 24-bit PNG, minimum 320px, maximum 3840px, 16:9 or 9:16 aspect ratio recommended).
* **Privacy Policy URL:**
  * A valid, publicly accessible HTTPS privacy policy URL is mandatory for all apps, especially if accessing device features, storage, or external APIs.
* **Content Rating & Policy Declarations:**
  * Complete the IARC Content Rating questionnaire in Play Console.
  * Submit mandatory declarations:
    * Target age and audience (COPPA compliance if targeting children under 13).
    * Ads declaration (indicate if app serves ads).
    * Data Safety section (disclose what user data is collected, stored, or shared).
    * Government apps / financial / health declarations (if applicable).

---

## 4. 🧪 Mandatory Closed Testing Requirement (Accounts Created After Nov 2023)

> [!IMPORTANT]
> If your Google Play Developer Account was created after **November 13, 2023**, Google requires you to run a **Closed Test** before applying for Production access:
> * **Minimum Testers:** At least **20 testers** must opt-in to your closed test.
> * **Duration:** Testers must be continuously opted-in for at least **14 consecutive days**.
> * Only after satisfying this period and gathering tester feedback can you apply for full production release access in Google Play Console.
