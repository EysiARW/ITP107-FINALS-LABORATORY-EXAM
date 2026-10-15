# ITP107 Finals Laboratory Exam

A Flutter application for reading posts from a REST API and managing offline favorites using Hive local storage.

## 🌐 Live Web Demo
The live application can be accessed directly in the browser here:  
👉 **[https://eysiarw.github.io/ITP107-FINALS-LABORATORY-EXAM/](https://eysiarw.github.io/ITP107-FINALS-LABORATORY-EXAM/)**

---

## 📱 Features
- **Fetch & Display Posts**: Fetches posts from an online REST API (`jsonplaceholder.typicode.com/posts`) using `package:http`.
- **Offline Favorites Management**: Save and remove favorite posts with persistent local storage powered by `hive_flutter`.
- **Post Details**: Dedicated screen showing detailed view of each post with user IDs and full post bodies.
- **Modern Material 3 UI**: Clean and responsive design supporting web, desktop, and mobile form factors.

---

## 🚀 Running Locally

1. **Clone the repository:**
   ```bash
   git clone https://github.com/EysiARW/ITP107-FINALS-LABORATORY-EXAM.git
   cd ITP107-FINALS-LABORATORY-EXAM
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   - On Chrome (Web):
     ```bash
     flutter run -d chrome
     ```
   - On Android/iOS emulator or connected device:
     ```bash
     flutter run
     ```
