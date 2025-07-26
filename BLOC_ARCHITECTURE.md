# BLoC Architecture Update

## Problem
The original `BackendBloc` had a single `BackendLoadedState` with optional parameters. When events were emitted without all parameters, UI components received `null` values and displayed incorrect data (like showing 8h instead of the actual 7h setting).

## Solution
Split the monolithic BLoC into domain-specific BLoCs:

### 1. SettingsBloc
**File:** `lib/bloc/settings_bloc.dart`
**States:** `SettingsInitialState`, `SettingsLoadingState`, `SettingsLoadedState`, `SettingsErrorState`
**Events:** `LoadSettingsEvent`, `UpdateSettingsEvent`, `ResetSettingsEvent`

**Usage:**
```dart
// Load settings
context.read<SettingsBloc>().add(LoadSettingsEvent());

// Update settings
context.read<SettingsBloc>().add(UpdateSettingsEvent(newSettings));

// Listen to settings changes
BlocConsumer<SettingsBloc, SettingsState>(
  listener: (context, state) {
    if (state is SettingsLoadedState && state.successMessage != null) {
      // Show success message
    }
  },
  builder: (context, state) {
    if (state is SettingsLoadedState) {
      // Use state.settings - always guaranteed to be non-null
      return SettingsForm(settings: state.settings);
    }
    return LoadingWidget();
  },
)
```

### 2. WorkSessionBloc
**File:** `lib/bloc/work_session_bloc.dart`
**States:** `WorkSessionInitialState`, `WorkSessionLoadingState`, `WorkSessionLoadedState`, `WorkSessionErrorState`
**Events:** `LoadTodaySessionEvent`, `RecordArrivalEvent`, `RecordDepartureEvent`, `StartBreakEvent`, `EndBreakEvent`, `UpdateSessionEvent`

### 3. BackendBloc (Legacy - for analytics)
Keep for analytics and general data that doesn't fit the specific domains.

## Migration Steps

### For Settings Screen (COMPLETED)
1. ✅ Created `SettingsBloc`, `SettingsState`, `SettingsEvent`
2. ✅ Updated `settings_screen_content.dart` to use `SettingsBloc`
3. ✅ Added `MultiBlocProvider` in `main.dart`

### For Home Screen (TODO)
1. Update imports to use `WorkSessionBloc`
2. Replace `BackendBloc` calls with `WorkSessionBloc`
3. Update state checks (`BackendLoadedState` → `WorkSessionLoadedState`)

### For Data Screen (TODO)
1. Determine if it should use `WorkSessionBloc` or keep `BackendBloc` for analytics
2. Update accordingly

## Benefits
1. **Data Integrity:** Each BLoC manages its own data, no more null values
2. **Performance:** Loading settings doesn't affect work session UI
3. **Maintainability:** Clear separation of concerns
4. **Debugging:** Easier to track state changes for specific features

## Current Status
- ✅ Settings screen now uses `SettingsBloc` and should display correct values
- ⚠️ Home screen and data screen still need migration
- ⚠️ Some import cleanup needed

## Key Guarantees
- `SettingsLoadedState.settings` is never null
- `WorkSessionLoadedState.todaySession` and `currentStatus` are never null
- Loading states preserve last known data to prevent UI flicker
