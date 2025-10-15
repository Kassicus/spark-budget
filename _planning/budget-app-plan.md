# Budget Management App (Spark Budget) - Project Overview & Development Plan

## Project Summary
A comprehensive personal finance management app built with Swift and SwiftUI for iOS, iPadOS, and watchOS. The app enables users to track multiple account types, manage transactions, monitor bills, and visualize spending patterns with iCloud sync support.

**Project Codename**: Spark Budget

## Core Requirements

### Account Management
- **Account Types**: Checking, Savings, Credit Card, Loan, Cash
- **Primary Account**: Designate one account as primary for daily spending calculations
- **Full CRUD Operations**: Create, Read, Update, Delete accounts
- **Account Properties**:
  - Name
  - Type
  - Current Balance
  - Account Number (optional, last 4 digits)
  - Color/Icon for visual identification
  - Is Primary flag

### Transaction Management
- **Transaction Types**: Income, Expense, Transfer
- **Full CRUD Operations**: Create, Read, Update, Delete transactions
- **Transaction Properties**:
  - Amount
  - Date/Time
  - Description
  - Category
  - Account association
  - Payee/Payer
  - Notes (optional)
  - Receipt photo (optional)
- **Transfer Support**: Move money between accounts with automatic double-entry

### Bill Management
- **Bill Properties**:
  - Title
  - Category
  - Amount
  - Due Date
  - Associated Account
  - Recurrence Pattern (one-time, weekly, monthly, yearly)
  - Is Paid status
- **Auto-Transaction**: Create transaction when bill is marked as paid
- **Notifications**: Remind users of upcoming bills

### Daily Spending Calculator
- **Payday Tracking**: Set payday date/frequency
- **Days Until Payday**: Calculate remaining days
- **Daily Budget**: (Primary Account Balance) / (Days Until Payday)
- **Visual Indicator**: Show remaining daily budget prominently

### Calendar & Analytics
- **Calendar View**:
  - Daily spending amounts
  - Transaction list per day
  - Bill due dates
  - Running balance visualization
- **Monthly Trends**:
  - Total income vs expenses
  - Category breakdown
  - Month-over-month comparison
  - Spending patterns

### User Interface
- **Theme Support**:
  - Light/Dark mode (follows system setting)
  - Customizable accent color
  - Consistent design language across platforms
- **Platform-Specific UI**:
  - iPhone: Full feature set
  - iPad: Optimized layouts with sidebars
  - Apple Watch: Quick transaction entry

### Data & Sync
- **iCloud Integration**:
  - Sign in with Apple ID
  - CloudKit for data storage
  - Automatic sync across devices
  - Offline support with sync queue
- **Data Security**:
  - Encryption for sensitive data
  - Face ID/Touch ID support
  - Secure data deletion

### Apple Watch Companion
- **Quick Actions**:
  - Add transaction with voice/scribble
  - View daily budget
  - Check account balances
  - Mark bills as paid
- **Complications**: Show daily budget on watch face

## Technical Architecture

### Data Models
```swift
// SwiftData Models with @Model macro
import SwiftData

@Model
final class Account {
    var id = UUID()
    var name: String
    var type: AccountType
    var balance: Decimal
    var isPrimary: Bool = false
    var colorData: Data? // Encoded Color
    var createdAt: Date
    var modifiedAt: Date
    
    @Relationship(deleteRule: .cascade) 
    var transactions: [Transaction]?
    
    @Relationship(deleteRule: .nullify)
    var bills: [Bill]?
}

@Model
final class Transaction {
    var id = UUID()
    var amount: Decimal
    var date: Date
    var desc: String // 'description' is reserved in SwiftData
    var category: String
    var type: TransactionType
    var notes: String?
    
    @Relationship(inverse: \Account.transactions)
    var account: Account?
    
    @Relationship
    var transferToAccount: Account?
}

@Model
final class Bill {
    var id = UUID()
    var title: String
    var category: String
    var amount: Decimal
    var dueDate: Date
    var recurrence: RecurrenceType
    var isPaid: Bool = false
    var lastPaidDate: Date?
    
    @Relationship(inverse: \Account.bills)
    var account: Account?
}

@Model
final class UserSettings {
    var id = UUID()
    var payday: Date
    var paydayFrequency: PaydayFrequency
    var accentColorData: Data? // Encoded Color
    var notificationsEnabled: Bool = true
}
```

### Key Technologies
- **SwiftUI**: Primary UI framework
- **SwiftData**: Modern data persistence (replaces Core Data)
- **CloudKit**: iCloud sync
- **WidgetKit**: Home screen widgets
- **WatchKit**: Apple Watch app
- **Swift Charts**: Native SwiftUI charts for analytics
- **UserNotifications**: Bill reminders
- **Observation Framework**: Modern state management (@Observable)

### App Architecture
- **MVVM Pattern**: Model-View-ViewModel with @Observable
- **Dependency Injection**: Environment values for data managers
- **Navigation Stack**: Modern SwiftUI navigation
- **Actor-based Concurrency**: Swift async/await for data operations

## Development Phases

### Phase 1: Foundation (Week 1-2)
1. **Project Setup**
   - Create Xcode project with iOS, iPadOS, watchOS targets
   - Configure SwiftData model container
   - Set up basic navigation with NavigationStack
   - Implement theme system (light/dark mode, accent colors)
   - Configure Swift Testing for unit tests

2. **Account Management**
   - Create Account SwiftData model with @Model
   - Build account list view with @Query
   - Implement add/edit account views
   - Account detail view with balance display
   - Set primary account functionality

3. **Basic UI Structure**
   - Tab bar navigation (Accounts, Transactions, Calendar, Bills, Settings)
   - Common UI components (buttons, cards, lists)
   - Color theme implementation with @Observable view model

### Phase 2: Transaction System (Week 3-4)
1. **Transaction Models & Storage**
   - Transaction SwiftData model with @Model
   - Transaction operations with ModelContext
   - Async/await for database operations

2. **Transaction Views**
   - Transaction list with @Query and filtering
   - Add transaction form with @Bindable
   - Edit transaction view
   - Transaction detail view
   - Quick add button/sheet

3. **Transfer System**
   - Transfer UI between accounts
   - Actor-based transaction manager for thread safety
   - Transfer history tracking

### Phase 3: Bills & Automation (Week 5-6)
1. **Bill Management**
   - Bill data model
   - Bill list view
   - Add/edit bill forms
   - Recurring bill logic

2. **Bill Payment Flow**
   - Mark as paid functionality
   - Auto-generate transactions
   - Payment history tracking

3. **Notifications**
   - Local notifications setup
   - Bill reminder scheduling
   - Notification preferences

### Phase 4: Analytics & Calendar (Week 7-8)
1. **Calendar Integration**
   - Calendar view implementation
   - Daily spending display
   - Transaction markers
   - Bill due date indicators

2. **Analytics Dashboard**
   - Monthly spending charts
   - Category breakdowns
   - Trend analysis
   - Custom date range reports

3. **Daily Budget Feature**
   - Payday configuration
   - Daily spending limit calculation
   - Visual progress indicators
   - Widget for home screen

### Phase 5: iCloud & Sync (Week 9-10)
1. **CloudKit Setup**
   - Configure CloudKit container
   - Design record types
   - Set up subscriptions

2. **Sync Implementation**
   - Sign in with Apple
   - Data upload/download
   - Conflict resolution
   - Offline queue management

3. **Multi-device Testing**
   - iPhone/iPad compatibility
   - Data consistency checks
   - Sync performance optimization

### Phase 6: Apple Watch App (Week 11)
1. **Watch App Setup**
   - Create watchOS target
   - Design simplified UI
   - Configure app groups

2. **Core Features**
   - Quick transaction entry
   - Account balance view
   - Daily budget display
   - Bill payment actions

3. **Complications**
   - Daily budget complication
   - Account balance complication
   - Update frequency optimization

### Phase 7: Polish & Optimization (Week 12)
1. **Performance**
   - SwiftData query optimization
   - Image loading/caching with AsyncImage
   - Animation performance with .animation(.smooth)
   - Memory management with @Observable

2. **User Experience**
   - Onboarding flow with AppStorage
   - Empty states with ContentUnavailableView
   - Error handling with Swift's Result type
   - Loading states with ProgressView
   - Haptic feedback with SensoryFeedback

3. **Accessibility**
   - VoiceOver support with accessibility modifiers
   - Dynamic Type with ViewThatFits
   - Color contrast verification
   - Keyboard navigation with @FocusState

### Phase 8: Testing & Deployment (Week 13-14)
1. **Testing**
   - Unit tests with Swift Testing framework (@Test, #expect)
   - UI tests with XCTest (still required for UI testing)
   - SwiftData migration testing
   - CloudKit sync testing with async/await
   - Multi-device testing on iOS 17+
   - Beta testing with TestFlight

2. **App Store Preparation**
   - App Store screenshots for all device sizes
   - App description with privacy focus
   - Privacy policy (data usage disclosure)
   - App Store review guidelines compliance
   - Privacy nutrition labels

## File Structure
```
spark-budget/                          # Git repository root
├── .git/
├── .gitignore
├── README.md
├── Docs/                             # Additional documentation
│   └── DevelopmentPlan.md
├── Scripts/                          # Build scripts, CI/CD
└── spark-budget/                     # Xcode project container
    ├── spark-budget.xcodeproj/
    ├── spark-budget/                 # iOS app source files
    │   ├── spark_budgetApp.swift    # App entry & ModelContainer
    │   ├── ContentView.swift        # Main content view
    │   ├── Models/
    │   │   ├── Account.swift
    │   │   ├── Transaction.swift
    │   │   ├── Bill.swift
    │   │   └── UserSettings.swift
    │   ├── ViewModels/
    │   │   ├── AccountViewModel.swift (@Observable)
    │   │   ├── TransactionViewModel.swift (@Observable)
    │   │   ├── BillViewModel.swift (@Observable)
    │   │   └── AnalyticsViewModel.swift (@Observable)
    │   ├── Views/
    │   │   ├── Accounts/
    │   │   ├── Transactions/
    │   │   ├── Bills/
    │   │   ├── Calendar/
    │   │   ├── Analytics/
    │   │   └── Settings/
    │   ├── Components/
    │   ├── Managers/
    │   │   ├── DataManager.swift (actor-based)
    │   │   ├── CloudKitManager.swift
    │   │   ├── NotificationManager.swift
    │   │   └── ThemeManager.swift (@Observable)
    │   ├── Preview Content/
    │   │   └── Preview Assets.xcassets
    │   └── Assets.xcassets
    ├── spark-budgetTests/            # Swift Testing
    │   ├── ModelTests.swift
    │   ├── ViewModelTests.swift
    │   └── CalculationTests.swift
    ├── spark-budgetUITests/          # XCTest for UI
    │   └── spark_budgetUITests.swift
    └── spark-budgetWatch/            # Future watchOS app
        ├── Views/
        └── spark_budgetWatchApp.swift
```

## Key Implementation Notes

### Data Persistence Strategy
- Use SwiftData for local storage with automatic CloudKit sync
- Implement versioned migrations with VersionedSchema
- Use @Query for efficient data fetching with predicates
- Batch operations with ModelContext for bulk updates
- Actor-based data managers for thread-safe operations

### Security Considerations
- Never store sensitive financial data (full account numbers, passwords)
- Implement biometric authentication with LocalAuthentication framework
- Use Keychain for sensitive user preferences
- SwiftData automatic encryption at rest
- Secure deletion with proper model cleanup

### Performance Optimization
- Lazy loading with @Query and pagination
- SwiftData's automatic batching and faulting
- Background sync operations with Task and async/await
- Efficient predicates and sort descriptors in queries
- Image compression for receipt photos before storage

### User Experience Best Practices
- Immediate visual feedback with @Observable state updates
- Undo support with UndoManager integration
- Smart defaults using @AppStorage for preferences
- Contextual help with TipKit (iOS 17+)
- Consistent gesture support with SwiftUI modifiers

## Success Metrics
- App launch time < 1 second
- Sync completion < 3 seconds on good connection
- Zero data loss during sync conflicts
- Support for 10,000+ transactions without performance degradation
- 99.9% crash-free rate

## Future Enhancements (Post-Launch)
- Export to CSV/PDF
- Budget categories with limits
- Recurring transaction templates
- Photo receipt OCR
- Spending insights with ML
- Family sharing support
- Third-party bank integration (Plaid)
- Currency conversion support
- Investment account tracking
- Tax report generation

## Development Tools & Resources
- **Xcode 16+**: Latest IDE with Swift Testing support
- **iOS 17+ SDK**: Minimum deployment target for modern SwiftUI features
- **SF Symbols 5**: Apple's expanded icon library
- **Swift 5.9+**: Required for @Observable and Swift Testing
- **SwiftLint**: Code style enforcement
- **Swift Testing**: Modern testing framework (@Test, #expect)
- **XCTest**: UI testing framework (still required for UI tests)
- **Instruments**: Performance profiling
- **TestFlight**: Beta testing distribution
- **Reality Composer Pro**: For any future visionOS support

## Technical Stack Summary

### Core Technologies
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI with iOS 17+ features
- **Data Persistence**: SwiftData (replaces Core Data)
- **State Management**: @Observable, @Query, @Bindable
- **Navigation**: NavigationStack, NavigationSplitView
- **Concurrency**: Swift async/await, actors
- **Testing**: Swift Testing (unit), XCTest (UI)
- **Cloud Sync**: CloudKit with SwiftData integration

### Key iOS 17+ Features to Leverage
- **SwiftData**: Modern persistence with @Model macro
- **Observation Framework**: @Observable for ViewModels
- **TipKit**: Contextual user guidance
- **SensoryFeedback**: Modern haptic feedback
- **ContentUnavailableView**: Built-in empty states
- **Swift Charts**: Native chart rendering
- **WidgetKit**: Interactive widgets
- **App Intents**: Siri and Shortcuts integration

## Getting Started with Claude Code
When using this plan with Claude Code:
1. Start with Phase 1 to establish the foundation
2. Test each phase thoroughly before moving to the next
3. Commit code frequently with clear messages
4. Reference this document for requirements and architecture decisions
5. Ask for clarification on any ambiguous requirements
6. Request code reviews at the end of each phase

### Working with the Project Structure
- The repository root (`spark-budget/`) contains git files, documentation, and scripts
- The Xcode project lives in `spark-budget/spark-budget/`
- When opening in Xcode, open `spark-budget/spark-budget/spark-budget.xcodeproj`
- All source code modifications happen within the nested `spark-budget/spark-budget/` directory
- This structure keeps the repository root clean for additional documentation and tooling

This plan provides a clear roadmap while maintaining flexibility for adjustments as development progresses.