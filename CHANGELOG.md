# Changelog

All notable changes to **Idea Bank** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-01-28

### 🎉 Initial Release

The first public release of Idea Bank - Your Ideas, Yours Alone.

### ✨ Features

#### 📝 Note Management
- Create, edit, and delete notes (Ideas)
- Rich text support with title and body
- Color-coded notes for visual organization
- Soft delete with 7-day trash bin
- Restore notes from trash
- Full-text search across all notes

#### 📁 Folder Organization
- Create color-coded folders (Vaults)
- Move notes between folders
- Folder-based filtering
- Quick folder access from home screen

#### 🎨 Drawing & Handwriting
- Freehand drawing canvas
- Smooth stroke rendering with Perfect Freehand
- Drawing preview thumbnails
- Encrypted drawing storage

#### 📎 File Attachments
- Attach files to notes (images, PDFs, documents, audio, video)
- Support for files up to 10MB
- Encrypted attachment storage
- Open attachments with external apps

#### 🎤 Speech-to-Text
- Voice input for notes
- Real-time transcription
- Permission handling for microphone access

#### 🤖 AI Chat Integration
- Chat with Google Gemini 2.5 Flash
- Context-aware conversations about specific notes
- Multiple chat sessions
- Encrypted chat history

#### 🔐 Security
- AES-256-CBC encryption for all content
- PBKDF2-HMAC-SHA256 key derivation (100,000 iterations)
- Secure passphrase authentication
- Passphrase change with full re-encryption
- Flutter Secure Storage for key management
- Zero-knowledge architecture

#### ☁️ Cloud Synchronization
- Optional Appwrite backend integration
- Bidirectional sync with conflict resolution
- Automatic sync every 5 minutes
- Manual sync on demand
- Encrypted cloud storage
- Self-hosted cloud option for maximum privacy

#### 🎨 User Interface
- Premium dark theme with teal accents
- Material Design 3 components
- Responsive grid layout
- Navigation drawer with settings access

### 🔧 Technical
- Flutter 3.32+ / Dart 3.8+
- Riverpod for state management
- SQLite for local storage
- Feature-first architecture
- Cross-platform support (Android, iOS, Desktop)

---

