# Build the APK using only your Android phone

This project includes a GitHub Actions workflow at `.github/workflows/android-apk.yml`.

1. Create a new GitHub repository, for example `rr-mobiles-offline-v10`.
2. Upload the contents of this ZIP to the repository root (not the ZIP file itself). Make sure hidden `.github` folder and workflow are included. GitHub mobile web may hide dot-folders; if so, use GitHub's desktop-site view in Chrome.
3. Open the repository's **Actions** tab.
4. Select **Build RR Mobiles Offline APK** and tap **Run workflow** (or push to `main`, which triggers it automatically).
5. Wait for the workflow to finish successfully.
6. Open the completed workflow run, scroll to **Artifacts**, and download `RR-Mobiles-Offline-V10-debug-apk`.
7. Extract the artifact ZIP on your phone and install `app-debug.apk`. Android may ask permission to install unknown apps for the browser or file manager you used.

This workflow produces a debug APK for testing, not a Play Store release. Do not use it for real shop transactions until offline billing, stock, credit, app restart persistence, and data-loss scenarios have been tested. Keep the original V10 website unchanged.
