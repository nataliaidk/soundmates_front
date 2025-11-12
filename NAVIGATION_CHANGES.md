# Profile Navigation Flow Changes

## Overview
Updated the profile screen navigation logic to improve user experience:
- `/profile` route now defaults to **view mode** (not edit mode)
- **Post-registration only**: Users are automatically taken to edit Step 1
- **Edit button**: Goes directly to Step 2 (tags/description/members) instead of Step 1
- **File uploads**: Added "Add Media" button in profile view Multimedia tab

## Changes Made

### 1. Default to View Mode (`profile_screen_new.dart`)

**Location:** `initState()` method
```dart
// Before:
_isEditing = widget.startInEditMode;

// After:
_isEditing = false; // Always start in view mode
```

**Effect:** When users navigate to `/profile`, they see their profile view instead of edit mode.

---

### 2. Force Edit Only After Registration (`profile_screen_new.dart`)

**Location:** `_initialize()` method after loading profile
```dart
// Before:
if (_shouldForceEditMode()) {
  setState(() {
    _isEditing = true;
    _currentStep = 1;
  });
}

// After:
// Only force edit mode Step 1 if coming from registration and profile incomplete
if (_isFromRegistration && _shouldForceEditMode()) {
  setState(() {
    _isEditing = true;
    _currentStep = 1;
  });
}
```

**Effect:** Profile edit Step 1 is only shown when:
- User just registered (`_isFromRegistration == true`)
- AND profile is incomplete (missing name, location, birth date, etc.)

---

### 3. Edit Button Goes to Step 2 (`profile_screen_new.dart`)

**Location:** `onEditProfile` callback in `ProfileViewTabs`
```dart
// Before:
onEditProfile: () {
  setState(() {
    _isEditing = true;
    _currentStep = 1;
  });
},

// After:
onEditProfile: () {
  setState(() {
    _isEditing = true;
    _currentStep = 2; // Go directly to Step 2 (tags/description)
  });
},
```

**Effect:** When users click "Edit" in profile view, they go directly to Step 2 where they can edit:
- Description
- Tags (genres, instruments, etc.)
- Band members (if band account)
- Profile photo

Basic info (name, location, birth date, gender) is edited less frequently, so Step 1 is only shown:
- During initial registration
- If user manually goes back from Step 2

---

### 4. Add Media Button in View Mode (`profile_view_tabs.dart`)

**Location:** Multimedia tab, above photo grid
```dart
// Added button to Photos & Videos section header:
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'Photos & Videos',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    TextButton.icon(
      onPressed: widget.onEditProfile,
      icon: const Icon(Icons.add_photo_alternate, size: 16),
      label: const Text('Add Media'),
    ),
  ],
),
```

**Effect:** Users can add photos/videos directly from profile view without explicitly entering "edit mode" first.

---

## User Flow Summary

### New User (Just Registered)
1. Complete registration → Redirected to `/profile`
2. Profile incomplete → Automatically shown **Step 1** edit form
3. Fill basic info (name, location, birth date) → Click "Next"
4. Shown **Step 2** (tags, description, members) → Click "Save"
5. Redirected to **profile view** with tabs (Your Info, Multimedia)

### Existing User (Navigating to /profile)
1. Navigate to `/profile` route
2. Profile complete → Shown **profile view** (not edit mode)
3. Can view tags, description, photos in two tabs
4. Click "Edit" button → Go to **Step 2** directly
5. Edit tags/description/members → Click "Save"
6. Return to **profile view**

### Adding Photos/Videos
1. In profile view, go to **Multimedia** tab
2. Click "Add Media" button
3. Opens **Step 2** (where photo picker is available)
4. Pick photo → Click "Save"
5. Return to profile view with new photo visible

---

## Benefits

1. **Less friction**: Users see their profile immediately instead of edit form
2. **Clearer intent**: Edit button takes you to the most commonly edited section (Step 2)
3. **Post-registration guidance**: New users still get proper onboarding (Step 1 → Step 2)
4. **Media upload convenience**: Can add photos from view mode without full edit flow
5. **Separation of concerns**: Basic info (Step 1) vs tags/content (Step 2)

---

## Files Modified

- `lib/screens/profile/profile_screen_new.dart` (3 changes)
- `lib/screens/profile/profile_view_tabs.dart` (1 change)

---

## Testing Checklist

- [ ] New user registration → auto-redirect to Step 1
- [ ] Existing user navigates to `/profile` → shows view mode
- [ ] Click "Edit" in view → goes to Step 2
- [ ] Click "Add Media" in Multimedia tab → goes to Step 2
- [ ] Back button in Step 2 → goes to Step 1
- [ ] Save in Step 2 → returns to view mode
- [ ] Profile photo picker works in Step 2
- [ ] Photo upload successful → visible in Multimedia tab
