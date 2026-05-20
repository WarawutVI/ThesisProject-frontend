## 🔐 Authentication Module (Login & Sign Up)

The Entry Point of the application handles user onboarding and authentication. Since the app targets **Thai High School Students** and **Foreigners**, the user interface is designed to be modern, vibrant, highly intuitive, and accessible.

### 📱 User Interface & Flow

* **Language Selection Feature:** Both the Login and Sign Up screens include a prominent **Language Button** at the top right. This allows foreign users to switch to English/their native tongue and Thai students to keep it in Thai, eliminating barriers right from the start.
* **Dual Authentication Methods:** To maximize convenience and reduce drop-off rates, users can authenticate using two methods:
    1.  **Email & Password:** Standard registration for users who prefer traditional credentials.
    2.  **Google OAuth (Social Login):** A one-click login solution, highly preferred by high school students for quick access.
* **Clean Separation:** Dynamic switching between the "Welcome back!" Login card and the "Create account 🌟" card via a toggle at the bottom of the form.

---

### ⚙️ Backend Architecture & Authentication Pipeline

The authentication pipeline uses a hybrid architecture combining **Firebase Authentication** for secure token/session management and a **Local MySQL Database** for storing extended user profile metadata.

#### 🔄 Authentication Workflow
1. The user authenticates via Flutter using Firebase (Email/Password or Google Sign-In).
2. Firebase generates a secure, unique `firebase_uid`.
3. Upon a successful first-time authentication, the Flutter frontend sends the token and user details to your backend API.
4. The backend verifies the token and synchronizes/saves the profile data into the local MySQL database using the `firebase_uid` as the primary relation key.

#### 💾 Database Schema (`users` table)
To keep track of demographic statistics (which is crucial for an educational/AI thesis to analyze how different age groups or genders interact with Thai vowel frequencies), data is structured as follows:

```sql
CREATE TABLE users (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    firebase_uid    VARCHAR(128) NOT NULL UNIQUE, -- Links directly to Firebase Auth
    username        VARCHAR(100) NOT NULL,
    email           VARCHAR(255) NOT NULL UNIQUE,
    gender          ENUM('male', 'female', 'other') NOT NULL, -- Crucial for voice/formant analysis
    age             TINYINT UNSIGNED NOT NULL, -- Helps categorize High Schoolers vs. Adults
    login_provider  ENUM('email', 'google') NOT NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

## 🧑‍💻 Onboarding Module (Demographics Collection)

This onboarding step immediately follows registration or a user's first-time login. It is designed to capture essential demographic data (`gender` and `age`) with minimal friction, keeping the interface highly visual and optimized for quick interaction.

### 📱 User Interface & Flow

* **Gender Selection Screen:** * Displays clear, minimalist, and interactive graphic selectors representing male and female options. 
    * Offers instant visual feedback (changing to the primary green theme color) upon selection to guide the user.
    * Includes a **"Skip"** action at the bottom to ensure user autonomy and prevent onboarding fatigue.
* **Age Selection Screen (Cupertino Picker):**
    * Uses a native Flutter **`CupertinoPicker`** widget for age selection. This provides a smooth, barrel-rolling wheel interface that feels premium and responsive for both iOS and Android users.
* **Google OAuth Data Integration Flow:**
    * If a user registers via **Google Sign-In**, basic info (like `email` and `username`) is pulled automatically from their Google Account profile.
    * Because Google API accounts don't always expose exact gender or age metrics due to privacy regulations, this onboarding bridge seamlessly gathers the remaining mandatory information before sending the complete payload to the local MySQL database.

---

### ⚙️ System Workflow & Data Synchronization

When a user completes or skips this stage, the mobile frontend packages the authenticated payload and synchronizes it with the backend server.

#### 💾 Database State Transition
The responses captured on these screens map directly to the `gender` and `age` columns within the `users` table:

* **Gender Selection:** Maps to the `ENUM('male', 'female', 'other')`. Choosing "Skip" or choosing not to identify default-maps to an 'other' or neutral fallback profile depending on system settings.
* **Age Selection:** Maps to the `TINYINT UNSIGNED` data slot, ensuring low database memory footprint while accurately storing values typically ranging from 12 to 80.

---

> 📌 **Thesis Relevance (Acoustic Phonetics Connection):** > Collecting gender and age isn't just for user profiling; it serves a deep technical purpose for the **CNN Audio Classification Model**. 
> Human vocal cords (vocal folds) and vocal tract lengths differ dramatically based on biological sex and developmental age. For example, high school students and women generally have higher fundamental frequencies ($F_0$) and higher formant configurations ($F_1, F_2, F_3$) than adult males. By tracking this metadata alongside saved sound samples, the thesis can evaluate if the CNN model requires acoustic normalization or separate weight adjustments when classifying vowels across distinct demographic brackets.

## 🧑‍💻 Onboarding Module (Demographics Collection)

This onboarding step immediately follows registration or a user's first-time login. It is designed to capture essential demographic data (`gender` and `age`) with minimal friction, keeping the interface highly visual and optimized for quick interaction.

### 🎨 UI/UX Design & Theming Philosophy

* **Flexible Theming:** The interface intentionally utilizes a minimalist layout with clean geometric placeholders. The theme and color palette are **not rigidly fixed**, allowing the application's visual style to remain completely adaptable. This flexibility makes it easy to implement future rebranding, dynamic system dark/light modes, or student-friendly colorful themes without rewriting structural layout code.
* **Gender Selection Screen:** * Displays clear, minimalist, and interactive graphic selectors representing male and female options. 
    * Offers instant visual feedback (changing to the primary green theme color) upon selection to guide the user.
    * Includes a **"Skip"** action at the bottom to ensure user autonomy and prevent onboarding fatigue.
* **Age Selection Screen (Cupertino Picker):**
    * Uses a native Flutter **`CupertinoPicker`** widget for age selection. This provides a smooth, barrel-rolling wheel interface that feels premium and responsive for both iOS and Android users.

---

### ⚙️ System Workflow & Data Synchronization

When a user completes or skips this stage, the mobile frontend packages the authenticated payload and synchronizes it with the backend server.

## 🏠 Main Dashboard (Home Screen)

The Home Screen serves as the primary navigation hub of the application after successful authentication. Designed with gamification and micro-learning principles in mind, it provides clean, distraction-free access to the app's three core functional pillars.

### 🎨 UI/UX Design & Flexible Assets

* **Adaptive Asset Philosophy:** In alignment with the flexible layout strategy, the visual components—including the cards, colors, illustrations, and **icons are not rigidly fixed**. The current visual elements serve as structural placeholders, allowing the engineering team to swap icons, update vector graphics, or implement dynamic custom asset packs seamlessly in future iterations without breaking the underlying layout logic.
* **Header Controls:** * **Language Switcher:** Continuously available at the top right, ensuring international users can toggle system languages instantly across the core dashboard.
    * **Sign-Out Action:** A clean, accessible logout icon allowing secure session termination via Firebase Authentication.
* **Modular Navigation Cards:** The dashboard uses large, high-contrast, clickable card components (implemented with Flutter's `GestureDetector` or `InkWell`). Each card targets a specific user intent:
    1.  **Practice Card:** Redirects users to the interactive AI-assisted recording module where they can test their vowel pronunciation.
    2.  **Lessons Card:** Takes users to the foundational training material to learn the theory behind phonetic rules and basic mouth positioning for Thai vowels.
    3.  **Your Progress Card:** Leads to the analytics dashboard where students can view their historical accuracy scores, tracked sessions, and improvement metrics.
* **Gamified Onboarding Element:** Includes an engaging mascot character illustration at the bottom with a positive call-to-action phrase (*"Have Fun with Thai Vowels"*). This lowers the intimidation barrier for foreign beginners and mimics modern EdTech standards to keep high schoolers motivated.

---

### ⚙️ Technical Architecture & Routing

* **Navigation System:** Built using Flutter's routing system (`Navigator.push`). Tapping any card initializes the corresponding sub-module view state.
* **Session Lifecycle:** Upon entering this page, the app holds the authenticated state synced from the local storage or Firebase state stream (`authStateChanges`).
* **Color-Coded Visual Segmentation:** The cards utilize a soft pastel color-coding system to visually segment the options, keeping the system structure highly intuitive even if exact branding styles change later.

## 🎯 Practice Module Selection (Category Menu)

This module serves as the primary entry gate for the interactive AI vowel training. Since Thai vowels are fundamentally divided by vowel length—which dramatically alters word meanings—the application splits the learning pathway into two main linguistic categories.

### 📱 User Interface & Flow

* **Category Selection Hub (Main Practice Screen):**
    * Presents a simple two-choice interface: **"Short Vowel"** (สระเสียงสั้น) or **"Long Vowel"** (สระเสียงยาว). 
    * The large, stacked action buttons minimize cognitive load for high schoolers and foreign beginners, making the starting point completely unambiguous.
* **Linguistic Progression Grids (Practice 1 & Practice 2):**
    * Selecting a category navigates the user to a dedicated dashboard dedicated to that specific vowel length class.
    * **Short Vowel Dashboard (`Practice1`):** Displays a $3 \times 3$ grid of standard short vowels (e.g., สระอะ `-ะ`, สระอิ `ิ `, สระอึ `ึ `).
    * **Long Vowel Dashboard (`Practice2`):** Displays a corresponding grid of long vowels (e.g., สระอา `-า`, สระอี `ี `, สระอือ `ื `).
* **Progress Tracking Metrics:** * **Overall Progress Indicator:** Displays a macro fractional score at the top right (e.g., `4 / 9` or `5 / 9`), showing how many unique vowel sets the user has successfully master-trained within that class.
    * **Micro-Vowel Progression Counters:** Each single vowel card features a sub-fraction indicator (e.g., `0 / 9`, `1 / 10`, `2 / 10`). This tracks the user's specific attempts or target success rates for individual sounds.
* **Navigation Architecture:** * Includes an explicit back arrow button in the header for smooth stack popping.
    * Features a prominent, accessible floating-style **Home Button** at the bottom of the grid pages to allow immediate return to the main dashboard.

---

### 🎨 UI/UX Design & Flexible Assets

* **Adaptive Assets & Theme:** Similar to the dashboard, the illustrations (e.g., the cartoon elephants and dinosaurs), colors, and layout icons serve as functional structural placeholders. The interface assets are not permanently fixed, allowing easy implementation of cleaner academic icons, alternative mascot variations, or adaptive color palettes at a later stage without requiring code overhauls.

---

### ⚙️ Technical Logic & Linguistic Significance

* **Dynamic Grid Building:** The vowel grids are built using Flutter’s `GridView.builder` component, fetching vowel asset structures dynamically from a local configuration array or backend data schema.
* **Thesis Relevance (Phonetic Duration Principle):**
    > 📌 **Thesis Relevance:** In Thai phonology, vowel duration (short vs. long) is a distinctive feature that differentiates minimal pairs (e.g., *ka* กะ vs. *kaa* กา). 
    > In signal processing, this distinction directly translates to **temporal duration thresholds**. When the recorded speech files are converted to Mel-Spectrograms, short vowels exhibit significantly shorter time-axis distributions than long vowels. Classifying them into separate modules allows for future targeted pipeline configurations, helping the CNN model better extract acoustic features based on temporal boundaries.


    ## 🎙️ Vowel Practice & Articulatory Instruction Module

Once a user selects a specific vowel (such as the long vowel สระอา `-า`), they enter the dedicated Practice Room. This screen provides a guided phonetic training environment that combines visual instructions, multi-word contextual practice, and instantaneous feedback.

### 📱 User Interface & Flow

* **Contextual Word Grid:** * To ensure comprehensive training, the interface goes beyond isolating the raw vowel. It populates a grid of simple Thai words combining the target vowel with various initial consonants (e.g., กา `kaa`, ขา `khaa`, งา `ngaa`, ซา `saa`). 
    * This helps users—especially foreigners—practice how the vowel interacts with different consonant articulation points (velar, alveolar, labial, etc.).
* **Articulatory Instruction Modal (`Practice1.3`):**
    * Tapping the **Information Info Icon (`i`)** at the top right triggers a clean, focused pop-up dialog overlay.
    * **Text Instructions:** Provides precise, step-by-step physical guidance on mouth positioning tailored for beginners (e.g., *"Open your mouth a bit wide. Let your tongue relax and stay low in your mouth..."*).
    * **Video Player Placeholder:** Includes an embedded media player layout intended for streaming or playing local video clips. This allows users to visually match their own mouth, lip rounding, and jaw openings with a native speaker's anatomical demonstration.
* **Dynamic Evaluation Feedback System (`Practice1.2`):**
    * Once a recording is submitted and evaluated by the system, individual item cards change color states dynamically to reflect the evaluation results:
    * **🟩 Green Border/Card State:** Indicates a **Correct/Passed** pronunciation attempt that matches the target acoustic properties.
    * **🟧 Orange Border/Card State:** Indicates an **Incorrect/Failed** attempt, signaling to the user that their pronunciation needs adjustments.

---

### 🎨 UI/UX Design & Flexible Assets

* **Adaptive Assets Reminder:** In adherence to the overall app framework, the specific placement of the informational dialogs, video frameworks, and mascot placeholders remain entirely adaptive. The icons and fonts serve as clear visual guides that can easily adapt to updated UI packages or design tweaks down the road.

---

### ⚙️ Technical Logic & Signal Processing Framework

* **State Management for Color Feedback:** In Flutter, the color transitions are driven by reactive state checking. Based on the JSON payload returned from the backend classification engine, the app evaluates an array of score structures, updating the widget state conditionally:
  ```dart
  // Conceptual conditional styling based on backend response
  Color getCardColor(String status) {
    if (status == 'correct') return Colors.greenAccent;
    if (status == 'incorrect') return Colors.orangeAccent;
    return Colors.grey[300]!; // Default unattempted state
  }


  ## 🎙️ Interactive Recording & Acoustic Feedback Module

This screen represents the core interactive layer of the AI vowel training application. It manages the hardware recording lifecycle, packages raw audio payloads, interfaces with the deep learning backend, and handles the scientific visualization of pronunciation scores.

### 📱 User Interface & Flow

* **Audio Playback Feature:** Tapping the **Speaker Icon** at the top right plays a high-quality reference audio track of a native speaker pronouncing the target vowel/word, giving users a clear acoustic benchmark before attempting it themselves.
* **Microphone State Management (`Practice1.12` & `Practice1.13`):**
    * **Idle State:** Displays a green microphone button with explicit, clear guidance designed for beginners: *"When you're ready, press microphone and speak once."*
    * **Active Recording State:** Tapping the microphone toggles the view state. The button changes to a red square (Stop button) while displaying a real-time counter tracking elapsed duration (e.g., *"recording 2 seconds"*). This gives users clear confirmation that their speech is actively being processed.
* **AI Evaluation Dialog Overlay (`Practice1.14`):**
    * Once the recording stops, the application streams the file to your backend server and instantly catches the API response, displaying it in a comprehensive modal.
    * **Acoustic Waveform Visualization:** Features a dynamic line chart component that superimposes the user's vocal properties against the target standard profile. It maps two overlapping color indicators:
        * 🟠 **Sample Audio (Orange Line):** The native reference frequency contour.
        * 🟢 **Your Audio (Green Line):** The user's recorded frequency mapping.
    * **Quantitative Accuracy Metric:** Displays an explicit, calculated evaluation score (e.g., `accuracy 80%`) paired with a qualitative verdict (`Correct 🎉` or `Great pronunciation 👍`).
    * **Phonetically-Driven Actionable Suggestions:** Provides intelligent text feedback to help the user self-correct on subsequent attempts (e.g., *"suggestion : Try opening your mouth wider, lowering your tongue slightly..."*).
    * **Navigation Actions:** Offers dual pathways via a **"Try Again"** loop button to re-attempt the exercise instantly or a **"Finish"** button to commit the session data and return.

---

### 🎨 UI/UX Design & Flexible Assets

* **Adaptive Assets Reminder:** In compliance with the overarching application framework, the specific placement of the charts, audio play icons, and buttons are built flexibly. The chart parameters and text hierarchies use abstract placeholders, ensuring that the presentation style can adapt smoothly to updated interface models or dynamic system theme modes later on.

---

### ⚙️ Technical Architecture & Pipeline Infrastructure


## 📚 Theory & Lessons Module (Foundational Learning)

Before engaging with the active AI evaluation loop, users can access the Lessons Module. This component acts as the foundational educational layer of the application, designed to teach the acoustic and articulatory mechanics of Thai vowels. It is particularly useful for foreign beginners who have no prior exposure to Thai phonology.

### 📱 User Interface & Flow

* **Comprehensive Vowel Index (Main Lesson Screen):**
    * Displays a unified scrollable view containing categories for both **Long Vowels** and **Short Vowels** organized in clean, predictable grid cards.
    * This allows users to browse and pick specific sounds systematically, rather than feeling overwhelmed by a single large list.
* **Articulatory Tutorial Screen:**
    * Selecting a vowel card maps the user directly to its dedicated lecture sub-page.
    * **Descriptive Articulation Guide:** Displays an explicit text block explaining exactly how to physically position the vocal tract components (e.g., *"Relax your mouth and throat muscles. Open your mouth fairly wide... Your tongue should stay low... Do not round your lips..."*).
    * **Multimedia Video Integration:** Features a large video player container where students can watch a native speaker's facial movements, mouth shapes, and lip positions in real-time.
* **Direct Bridging Navigation Loop:**
    * Includes an intuitive, interactive text-arrow button at the bottom: **"go to practice ➔"**.
    * This allows the user to immediately transition from theoretical learning (understanding the mechanics) to muscle memory training (recording their voice) inside the Practice Module for that exact vowel.

---

### 🎨 UI/UX Design & Flexible Assets

* **Adaptive Asset Philosophy:** In alignment with the application's overall design constraints, the specific layout structures, text parameters, media panels, and mascot placements are completely modular. These placeholders ensure that media sources (streaming video links vs. local assets) or interface color schemes can be hot-swapped or updated effortlessly later on.

---

### ⚙️ Technical System Design & Pedagogical Relevance

* **Hierarchical State Transitions:** Clicking **"go to practice"** does not just load a blank page. The Flutter router passes the active `vowel_id` or asset token down the widget stack directly into the **Practice Room Module**, making the user journey continuous and frictionless.
  ```dart
  // Example of passing context from Lesson to Practice
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PracticeRoomScreen(vowelId: activeLesson.vowelId),
),
  );


  ## 📊 Analytics & Progress Tracking Module (`Progress1`)

The "Your Progress" screen acts as a personal learning analytics dashboard. It aggregates historical session data from the local database to give high school students and foreign learners a clear, visual breakdown of their pronunciation consistency, improvements over time, and practice frequency.

### 📱 User Interface & Data Visualization

* **Practice Count Module (Categorized Bar Chart):**
    * Uses an interactive bar chart representation to display the raw volume of practice attempts per vowel phoneme.
    * Features an asynchronous **Dropdown Menu Filter** (e.g., toggling between `long vowels` and `short vowels`). This allows users to inspect exactly which specific characters they are spending their time on or neglecting.
* **Macro Accuracy Metrics (Donut/Radial Charts):**
    * Displays twin circular radial charts highlighting global average metrics: one dedicated strictly to **Long Vowels** and another to **Short Vowels** (e.g., demonstrating a `43%` baseline proficiency level).
    * Providing this high-level separation helps users pinpoint whether their core pronunciation difficulty lies in temporal vowel length control or sound articulation.
* **Accuracy Trend Tracking (Time-Series Line Chart):**
    * Implements a continuous line chart mapping average accuracy percentages over a weekly timeline grid (`Sun` to `Sat`).
    * This visualizes the learning curve directly, giving high school students tangible proof of their progress and a clear sense of academic achievement as the trend line moves upward.
* **Granular Session History Log:**
    * Features a scrollable, list-style **History Feed** at the base of the dashboard displaying recent attempts.
    * Each card explicitly logs:
        * The specific target vowel character glyph.
        * The categorical class type (`long vowels` / `short vowels`).
        * The chronological date timestamp of the attempt.
        * The exact classification accuracy score achieved (e.g., `80%`).
    * Includes a **"See more ∨"** accordion trigger to dynamically paginate or unpack older user log history.

---

### 🎨 UI/UX Design & Flexible Assets

* **Adaptive Layout Continuity:** In keeping with the application's overarching decoupled design requirements, all chart vectors, labels, data nodes, and custom scroll behaviors are engineered as dynamic UI modules. The layout logic parses variable dataset structures cleanly, ensuring that if font styles, accent boundary colors, or structural borders change, the data maps natively without alignment issues.

---

### ⚙️ Technical Data Flow & Backend Architecture
