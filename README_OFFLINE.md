# RR Mobiles Offline V11 – Android project

This is a separate offline edition based on the supplied V11 source. It starts with an empty local database and does not connect to Supabase or import old customers.

## Local data
- IndexedDB database: `rr-mobiles-offline-v11`
- Tables: customers, products, bills, repairs, purchases, expenses, credit_payments, loyalty_transactions
- Data is stored inside the app's WebView on this device. Uninstalling/clearing app storage can permanently erase it. Export/backup is not yet implemented.
- WhatsApp sharing requires internet and WhatsApp installed.

## Build Android APK
Requires Node.js 20+, Java 17, Android SDK, Android platform tools and Gradle (Capacitor installs the Android Gradle project).

```bash
npm install
npm run build
npx cap add android
npx cap sync android
cd android
./gradlew assembleDebug
```

Debug APK output: `android/app/build/outputs/apk/debug/app-debug.apk`

For a release APK, create and securely store a signing keystore, configure signing in `android/app/build.gradle`, then run `./gradlew assembleRelease`. Do not share keystore passwords.

## Important test requirements before shop use
1. Install on a test phone and verify data survives force-close/restart.
2. Test create/edit/delete for every table.
3. Test billing with stock deduction, credit payments, purchase stock-in and expense/report calculations.
4. Test PDF generation and WhatsApp links.
5. Export/backup and restore are not included yet. Do not rely on this prototype as the only copy of business records until those are implemented and tested.
