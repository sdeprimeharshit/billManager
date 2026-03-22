# bill_manager

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 🚀 How to Run & Release (Windows)

Since this project is developed on macOS, we use **GitHub Actions** to build the Windows installer (`.msix`).

### 1. Generating the Installer
1.  **Configure `msix`**: Ensure the `msix_config` block in `pubspec.yaml` is updated (App Name, Publisher Name, etc.).
2.  **Push to GitHub**: Commit and push your changes to the `main` branch.
3.  **GitHub Actions**:
    - Go to the **Actions** tab of this repository on GitHub.
    - Select the **"Build Windows MSIX"** workflow.
    - Once the build is finished, download the `windows-installer` artifact from the bottom of the run page.

### 2. Installing on Windows
Because the app is not signed with a paid Microsoft certificate, Windows will show a warning:
1.  Double-click the `.msix` file.
2.  When the "Windows protected your PC" blue screen appears, click **"More Info"**.
3.  Click **"Run anyway"**.
4.  The app will install and appear in your Start Menu.

---

### 🛠 Manual Local Build (Requires Windows Machine)
If you have access to a Windows PC with Flutter installed:
1.  Run `flutter build windows`
2.  Run `dart run msix:create`
3.  The installer will be located in `build\windows\runner\Release\`.

## 📝 TODO:
- [ ] **PDF UI**: Add GST column in the items section.
- [ ] **PDF Generator**: General UI modifications and polish.
- [ ] **E-way Bill**: Add JSON creator action button.
- [ ] **UI Branding**: Add Logo option in profile and populate in the bill PDF.
- [ ] **Releases**: Set up automated GitHub Actions for Windows/Android builds.
- [ ] **Backup**: Local ZIP backup or Google Drive integration (replace existing).
- [ ] **Import**: Logic to restore database from backup files.
