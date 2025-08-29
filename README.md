# Expense Manager - SQLite Version

A Flutter expense management application that uses SQLite for local data storage instead of Firebase.

## Features

- **Dashboard**: Overview of finances with charts and analytics
- **Budget Management**: Create and track budget categories
- **Transaction Tracking**: Add income and expenses
- **Goals**: Set and track financial goals
- **AI Assistant**: Chat with AI to get financial insights
- **Analytics**: Visual representation of spending patterns

## Architecture

- **Local Database**: SQLite using `sqflite` package
- **State Management**: Provider pattern
- **UI**: Material Design 3 with custom theming
- **Charts**: `fl_chart` for data visualization
- **AI**: Google Generative AI for financial assistance

## Database Schema

The app uses SQLite with the following tables:
- `users`: User information
- `transactions`: Income and expense records
- `budget_categories`: Budget allocations and spending
- `goals`: Financial goals and progress
- `ai_chat_history`: AI conversation history

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run the app with `flutter run`

## Dependencies

- `sqflite`: SQLite database
- `provider`: State management
- `fl_chart`: Charts and graphs
- `google_generative_ai`: AI assistant
- `google_fonts`: Typography
- `uuid`: Unique ID generation

## Migration from Firebase

This version has been migrated from Firebase to SQLite:
- Removed Firebase Auth, Firestore, and Cloud Messaging
- Added local SQLite database with `sqflite`
- Updated all services to use local storage
- Maintained the same UI and user experience
- Added demo data population for testing

## Demo Data

The app automatically populates sample data on first run:
- Sample budget categories (Food, Transport, Shopping, etc.)
- Sample transactions (income and expenses)
- Sample financial goals
- This allows users to see the app in action immediately

## Local Storage

All data is stored locally on the device:
- No internet connection required
- Data persists between app sessions
- Fast and responsive performance
- Privacy-focused (no cloud data sharing)
