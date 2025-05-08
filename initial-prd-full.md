**prompt**
Please craft a PRD for an mobile ios diary app "Symptomly" using swift to track person's symptoms during a day with easy and simple interface allowing to to add new symptoms, refer the previous ones with a reminder to the end of the day

**Product Requirements Document: Symptomly**

**1. Introduction**
Symptomly is a simple, intuitive iOS mobile application designed to help users easily track their physical or mental symptoms throughout the day. It provides a straightforward interface for logging new symptoms, reviewing past entries, and includes an end-of-day reminder to encourage consistent tracking. The primary goal is to empower users to better understand their health patterns and provide accurate information to healthcare professionals if needed.

**2. Goals**
*   **Primary Goal:** Enable users to quickly and easily log symptoms they experience during the day.
*   **Secondary Goal:** Allow users to review their symptom history to identify patterns or triggers.
*   **Tertiary Goal:** Encourage consistent logging through a daily reminder.
*   **User Experience Goal:** Provide a clean, uncluttered, and intuitive user interface.

**3. Target Audience**
*   Individuals with chronic conditions who need to monitor recurring symptoms (e.g., migraines, IBS, arthritis).
*   People experiencing acute illnesses wanting to track symptom progression (e.g., flu, common cold).
*   Users monitoring reactions to new medications, foods, or environmental factors.
*   Anyone who wants a simple way to keep a personal health log for better self-awareness or for doctor's visits.

**4. User Stories**

*   **US1 (Logging):** As a user, I want to quickly add a new symptom with its name, perceived severity, and optional notes, so I can accurately record how I'm feeling at a specific time.
*   **US2 (Viewing Today):** As a user, I want to see all symptoms I've logged for the current day in a clear, chronological list, so I can get an overview of my day.
*   **US3 (Viewing History):** As a user, I want to easily navigate to and view symptoms logged on previous days, so I can identify patterns or recall past experiences.
*   **US4 (Editing):** As a user, I want to be able to edit or delete a symptom entry I made, in case I made a mistake or my perception of the symptom changes.
*   **US5 (Reminder):** As a user, I want to receive a reminder notification at the end of the day, so I don't forget to log any symptoms I might have missed or to do a final check-in.
*   **US6 (Symptom Reuse):** As a user, when adding a new symptom, I want to see suggestions based on symptoms I've previously logged, so I can log recurring symptoms faster and maintain consistency.
*   **US7 (Simplicity):** As a user, I want the app to be extremely simple and focused, without overwhelming features, so I can log my symptoms without friction.

**5. Key Features (MVP - Minimum Viable Product)**

*   **5.1. Symptom Logging Screen:**
    *   **Symptom Name:** Text input field. Autocomplete suggestions based on previously entered symptom names.
    *   **Severity:** A simple scale (e.g., 1-5 numerical scale, or descriptive: Mild, Moderate, Severe). Visual representation (e.g., slider, segmented control).
    *   **Timestamp:** Automatically populated with the current date and time. User can tap to adjust if logging retroactively (within the same day or recent past).
    *   **Notes:** Optional multi-line text field for additional context (e.g., "after eating spicy food," "woke up with it").
    *   **"Save Symptom" Button.**

*   **5.2. Daily Diary View:**
    *   **Main Screen:** Defaults to showing symptoms logged for the current day.
    *   **Chronological List:** Symptoms displayed in reverse chronological order (most recent first).
    *   **Entry Display:** Each entry should clearly show symptom name, severity, time, and a snippet of notes (if any).
    *   **"Add New Symptom" Button:** Prominently displayed (e.g., floating action button or "+" in navigation bar).

*   **5.3. Historical View:**
    *   **Calendar Navigation:** A simple way to select a previous date (e.g., a mini-calendar picker, or "<" ">" buttons to go day-by-day).
    *   **Display:** Shows logged symptoms for the selected date, similar to the Daily Diary View.

*   **5.4. Symptom Editing/Deletion:**
    *   Users can tap on a logged symptom entry to view its full details.
    *   From the detail view, users can edit any field or delete the entire entry.
    *   Standard iOS swipe-to-delete gesture on the list view for quick deletion.

*   **5.5. End-of-Day Reminder:**
    *   **Local Notification:** A single, daily local notification.
    *   **Default Time:** Defaults to a reasonable time (e.g., 8:00 PM).
    *   **Customizable Time:** User can adjust the reminder time in settings.
    *   **Toggle:** User can enable/disable the reminder.

*   **5.6. Settings Screen:**
    *   Reminder Time Configuration.
    *   Reminder On/Off Toggle.
    *   (Future: Data export, About, Feedback).

**6. Design & UX Considerations**

*   **Simplicity:** Minimalist design. Avoid clutter. Focus on core functionality.
*   **Intuitive Navigation:** Easy to understand how to add symptoms and view history. Standard iOS navigation patterns.
*   **Clarity:** Clear typography, sufficient contrast for readability.
*   **Quick Entry:** The process of adding a new symptom should be as fast as possible.
*   **Visual Feedback:** Clear indication when a symptom is saved or an action is performed.
*   **Accessibility:** Consider basic accessibility features (e.g., Dynamic Type support).

**7. Technical Considerations**

*   **Platform:** iOS (iPhone first).
*   **Language:** Swift.
*   **UI Framework:** SwiftUI (recommended for its declarative nature, fitting the "simple interface" goal). UIKit is also an option.
*   **Data Persistence:**
    *   **Core Data:** Suitable for structured local data storage.
    *   **Realm:** Alternative to Core Data.
    *   `UserDefaults` for simple settings like reminder time.
*   **Notifications:** `UserNotifications` framework for local reminders.
*   **Architecture:** Consider MVVM (Model-View-ViewModel) if using SwiftUI, or MVC/MVVM for UIKit.
*   **Minimum iOS Version:** Target a reasonably recent iOS version (e.g., iOS 15+) to balance feature availability and user base.
*   **Privacy:** All data will be stored locally on the user's device for MVP. No cloud sync or external data transmission. A clear privacy statement should be available.

**8. Monetization (Post-MVP / Future Consideration)**
*   **MVP:** Free, no ads. Focus on user adoption and feedback.
*   **Potential Future:**
    *   One-time purchase for premium features (e.g., advanced analytics, PDF export, iCloud sync).
    *   A very subtle, non-intrusive ad model (if absolutely necessary, but generally discouraged for utility apps like this).

**9. Future Considerations / Roadmap (Post-MVP)**
*   **Symptom Categories/Tags:** Allow users to categorize or tag symptoms (e.g., "Pain," "Digestive," "Mood").
*   **Trend Analysis & Charts:** Basic charts showing symptom frequency or severity over time.
*   **Data Export:** Allow users to export their data (e.g., CSV, PDF) to share with doctors.
*   **iCloud Sync:** Optionally sync data across a user's iOS devices.
*   **Customizable Severity Scales:** Allow users to define their own severity labels.
*   **Medication/Treatment Logging:** Option to log medications or treatments taken alongside symptoms.
*   **HealthKit Integration:** (Carefully consider privacy implications) Potentially read relevant data (e.g., sleep, activity) or write symptom data if appropriate.
*   **iPad Version.**

**10. Success Metrics (MVP)**
*   **Daily Active Users (DAU) / Monthly Active Users (MAU).**
*   **Retention Rate:** Percentage of users returning to the app after 1 week, 1 month.
*   **Average Symptoms Logged per User per Day.**
*   **App Store Rating & Reviews.**
*   **Crash-Free User Rate.**
*   **Task Completion Rate:** How easily users can add a symptom.

**11. Open Questions / Assumptions**
*   **Assumption:** Users prefer free-text for symptom names over a predefined list for MVP simplicity, with autocomplete aiding consistency.
*   **Assumption:** A simple 1-5 or Mild/Moderate/Severe scale is sufficient for MVP severity.
*   **Question:** What is the ideal default reminder time? (Propose 8 PM, but make it configurable).
*   **Question:** For editing timestamps, what is the acceptable range for retroactive logging?
- within last 24/48 hours

---
