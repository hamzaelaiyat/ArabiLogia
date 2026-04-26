# Arabilogia - Product Requirements Document

## 1. Overview

**Product Name:** Arabilogia (عربيلوجيا)
**Type:** Arabic Language Exam Preparation Platform
**Core Summary:** A mobile/web platform for high school students (ages 15-18) across Egypt to practice Arabic exams created by teacher Walid Kotb (وليد قطب).
**Target Users:** Secondary school students (Grades 10-12) in Egypt

---

## 2. Problem Statement

High school students in Egypt need to pass Arabic exams but have limited practice resources. Walid Kotb (وليد قطب) - a master Arabic teacher - needs a platform to deliver exam questions to his students in a structured, gamified way.

---

## 3. Product Goals

1. **Primary Goal:** Enable students to take Arabic exams (grammar, literature, poetry, reading comprehension) on mobile/web/desktop
2. **Secondary Goal:** Track student progress and scores with leaderboard competition
3. **Tertiary Goal:** Provide teacher (Walid Kotb) with basic analytics on student performance

---

## 4. User Personas

### 4.1 Primary Persona: Student (Ages 15-18)

- **Name:** Ahmed (example)
- **Context:** Egyptian high school student preparing for Arabic exams
- **Goals:** Practice Arabic exams, improve scores, compete on leaderboard
- **Pain Points:** Limited practice resources, no way to track progress

### 4.2 Secondary Persona: Teacher

- **Name:** Walid Kotb (وليد قطب)
- **Context:** Arabic language teacher in Egypt
- **Goals:** Manage exams, view student analytics
- **Pain Points:** No platform to distribute exams to students digitally

---

## 5. User Stories

### Student User Stories

| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-01 | As a user, I want to register with email/password so I can create an account | User can sign up with email + password, account stored in Supabase |
| US-02 | As a user, I want to login so I can access my account | User can login with email + password, JWT token issued |
| US-03 | As a user, I want to see exams for my grade so I can only access appropriate exams | User's grade is assigned during registration; exams filtered to their grade |
| US-04 | As a user, I want to change my grade from settings every 3 days | Grade changeable from profile/settings with 3-day cooldown between changes |
| US-05 | As a user, I want to see available exams organized by subject so I can choose what to practice | Exams displayed in tabs by subject: Grammar (النحو), Literature (الأدب), Poetry (الشعر), Reading (القراءة) |
| US-06 | As a user, I want to take a multiple-choice exam so I can practice | Student selects answers, submits, gets score |
| US-07 | As a user, I want to see questions randomized each time I attempt an exam | Questions shuffled randomly on each new attempt |
| US-08 | As a user, I want to have optional timer with bonus points for faster completion | Teacher can add timer by setting duration per exam; if teacher adds timer: student can't change it but can opt-out; if no timer added by teacher: student can optionally enable it for bonus points |
| US-09 | As a user, I want to go back and change answers during the exam | Can navigate back and change answers before submission |
| US-10 | As a user, I want to see my score immediately after finishing an exam (with brief animation) | 1-2 second animation, then score displayed as percentage with time taken |
| US-11 | As a user, I want to see wrong answers after completing the exam | Results show list of wrong answers (not correct ones) |
| US-12 | As a user, I want to retry exams unlimited times in practice mode | After first completion, unlimited retakes allowed; first attempt only counts for leaderboard |
| US-13 | As a user, I want to view my exam history so I can track my progress | List of past attempts with scores displayed |
| US-14 | As a user, I want to see my rank on the leaderboard so I can compete with others | Leaderboard ranks students by total points, filtered by grade level |
| US-15 | As a user, I want to view other students' profiles (unless they disable it) | Can view other students' profiles; users can disable profile visibility in settings |
| US-16 | As a user, I want to share my score as an image so I can share on social media | Generate shareable image with score, can share to WhatsApp/Facebook |
| US-17 | As a user, I want to receive notifications when new exams are available | Push notifications for new exam content |
| US-18 | As a user, I want to delete my own account from settings | Self-delete account option in settings |
| US-19 | As a student, I want exams to unlock sequentially so I can track my progress | Student must complete Exam N to unlock Exam N+1 within same subject/grade; first exam in each subject is always unlocked |

### Teacher User Stories

| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-20 | As a teacher, I want to create exams with manual entry | Add questions one by one through admin panel |
| US-21 | As a teacher, I want to bulk import questions via Excel/CSV | Import questions in bulk from spreadsheet file |
| US-22 | As a teacher, I want to set exam duration per exam | Define time limit for each exam when creating it |
| US-23 | As a teacher, I want to view student scores and analytics so I can track progress | Dashboard showing student performance data |
| US-24 | As a teacher, I want to set exam availability dates so I can control when exams are released | Date picker to set exam release/lock dates |
| US-25 | As a teacher, I want to delete users so I can remove spam or inactive students | Teacher can select and delete user accounts from dashboard |
| US-26 | As a teacher, I want students to be able to flag/report problematic questions | Students can report questions that seem wrong or misleading |

| US-27 | As a teacher, I want to override progressive unlock for specific students | Teacher can manually unlock exams for struggling students from dashboard |

---

## 6. Functional Requirements

### 6.1 Authentication

- Email/password registration and login
- JWT-based session management
- Password reset functionality
- Grade assignment during registration
- Grade changeable from settings/profile every 3 days (cooldown enforced)

### 6.2 Exam System

- **Database Schema:**
  - Table `exams`: `duration_minutes` is NOT NULL (teacher must set it)
  - Table `exam_attempts`: Tracks which exams have been completed for progressive unlock
  - Table `user_settings`: `profile_visible` boolean (default: true)

- **Exam Structure:**
  - Grade levels: Grade 10 (الصف الأول الباكالوري), Grade 11 (الصف الثاني ثانوي), Grade 12 (الصف الثالث ثانوي)
  - Subjects: Grammar (النحو), Morphology (الصرف), Literature (الأدب), Poetry (الشعر), Reading (القراءة والنصوص)
  - Question type: Multiple choice only
  - Question count: Variable (as teacher adds)
  - Each student sees ONLY their grade's exams (locked to grade)

- **Exam Flow:**
  1. User sees exams filtered by their assigned grade → selects subject tab → selects exam
  2. Exam presents questions one by one
  3. Questions randomized on each new attempt
   4. Timer logic:
      - Teacher MUST set a fixed duration per exam (teacher explicitly adds it - required)
      - Student CANNOT change the time duration set by teacher
      - Student CAN choose to disable/opt-out of the timer (no bonus points if disabled)
  5. User can navigate back and change answers before submission
  6. User submits answers
  7. Brief animation (1-2 seconds) builds anticipation
  8. Score calculated and displayed (percentage + time taken)
  9. List of wrong answers shown (not correct answers)
  10. First attempt: Points awarded for leaderboard (if score ≥ 60%)
  11. Subsequent attempts: Practice mode (no points, unlimited retakes)

- **Scoring:**
  - Passing score: 60%
  - Points = exam score percentage (first attempt only)
  - Timer bonus: Extra points awarded for finishing early (only if student completed exam before time runs out AND student did NOT opt-out of the timer)

- **Progressive Unlock:**
  - Database: `exam_attempts` table tracks completed exams per student
  - Logic: Student must score ≥ 60% on Exam N to unlock Exam N+1 within same grade+subject
  - First exam in each grade+subject combination is always unlocked
  - Teacher can manually unlock exams for specific students from dashboard (bypasses progressive unlock check)

### 6.3 Navigation (Responsive)

- **Mobile:** Bottom navigation bar with 5 items
- **Desktop/Tablet:** Sidebar navigation
- **Exam Access:** Exams accessible via navigation (second tab)

### 6.4 Theme

- Light/Dark mode toggle (manual)
- Auto mode (follows system settings)
- Both options available in settings

### 6.5 Scoring & Leaderboard

- First attempt score saved as official
- Points = exam score percentage
- Leaderboard ranks students by total points
- Leaderboard filters: By grade level
- Additional filters: All-time, This week, This month

### 6.6 Social Sharing

- Generate image with:
  - Student name (optional)
  - Exam name
  - Score percentage
  - Arabilogia branding
- Share via native share (WhatsApp, Facebook, etc.)

### 6.7 Profile & Privacy

- Users can view other students' profiles
- Users can disable profile visibility in settings for privacy
- Users can delete their own account from settings

### 6.8 Offline Support

- Cache downloaded exams for offline access
- Sync results when back online
- Offline indicator in app
- *Note: Deferred to v1.1*

### 6.9 Teacher Dashboard

- View all students
- View student scores per exam
- View aggregate analytics (average scores per exam/subject)
- Set exam availability dates
- Delete users
- Create questions manually (one by one)
- Bulk import questions via Excel/CSV
- Set exam duration per exam

### 6.10 Question Flagging

- Students can flag/report questions as wrong/misleading
- Flagged questions reviewed by teacher
- *Note: For v1.0*

### 6.11 Notifications

- New exam available
- Exam reminder (optional)
- *Note: Push notifications deferred to v1.1*

---

## 7. Technical Architecture

### 7.1 Stack

- **Frontend:** Flutter (Mobile + Web via flutter_web)
- **Backend:** Supabase (PostgreSQL + Auth + Realtime)
- **State Management:** Provider
- **Routing:** GoRouter


### 7.2 Project Structure 

```
lib/
├── core/
│   ├── constants/    # Error messages, routes, etc.
│   ├── routes/      # App router
│   ├── services/    # Supabase service, data service
│   ├── theme/       # App themes
│   └── widgets/     # Reusable widgets
├── features/
│   ├── auth/        # Login, register, password recovery
│   ├── dashboard/  # Home, tasks, leaderboard, profile, settings
│   ├── legal/       # Privacy, terms
│   └── navigation/  # Navigation components (bottom bar, sidebar)
├── providers/       # Auth, settings, tasks, leaderboard
└── main.dart        # Entry point
```

---

## 8. MVP Scope (v1.0)

### Must Have (v1.0)

- [ ] Student registration/login (email/password) with grade selection
- [ ] Grade-locked exam listing (user sees only their grade's exams)
- [ ] Grade changeable every 3 days from profile/settings
- [ ] Subject tabs for organizing exams
- [ ] Take multiple-choice exam
- [ ] Questions randomized each attempt
- [ ] Optional timer with bonus points
- [ ] Navigate back and change answers during exam
- [ ] Score calculation and display with brief animation
- [ ] Show wrong answers after completion
- [ ] Passing score: 60%
- [ ] Practice mode (unlimited retakes, no points)
- [ ] Exam history view
- [ ] Leaderboard by grade level
- [ ] Profile viewing with privacy option
- [ ] Self-delete account in settings
- [ ] Social sharing (image generation)
- [ ] Dark/Light/Auto theme toggle
- [ ] Push notifications (new exams)
- [ ] Basic teacher analytics dashboard
- [ ] Teacher: Manual question entry
- [ ] Teacher: Bulk CSV import
- [ ] Teacher: Set exam duration per exam
- [ ] Teacher: Delete users
- [ ] Question flagging by students

### Not in v1.0 (Deferred)

- [ ] Offline mode (defer to v1.1)
- [ ] Advanced teacher features (defer to v1.1)
- [ ] Web version (defer to v1.2)
- [ ] Google sign up (defer to v1.2)

---

## 9. Design Requirements

### 9.1 UI/UX

- **Language:** Arabic (RTL) only
- **Theme:** Light/Dark/Auto mode toggle (existing implementation)
- **Primary Color:** Amber Gold `#EB8A00` (oklch 0.72 0.17 65)
- **Background:** Light `#F7FCFF` / Dark `#191B1D`
- **Typography:**
  - Headlines/Display: **ReadexPro** (bold, modern Arabic-optimized)
  - Body/UI: **Rubik** (clean, readable for Arabic)
- **Accent Color:** Sunset Glow `#EB5833`
- **Semantic Colors:** Error `#FF3B30`, Success `#34C759`, Warning `#FFCC00`
- **Layout:** Mobile-first, responsive for web with sidebar

### 9.2 Navigation (Responsive)

- **Mobile:** Bottom navigation bar with 5 items (Home, Tasks/Exams, Leaderboard, Profile, Settings)
- **Desktop/Tablet:** Sidebar navigation with same 5 items
- **Exams:** Accessible via navigation tabs

### 9.3 Screens Required

1. **Auth:** Login, Register (multi-step with grade selection), Forgot Password
2. **Dashboard:** Home (exam categories), Tasks/Exams (subject tabs), Leaderboard, Profile, Settings
3. **Exam:** Exam list, Exam taking, Results (score + time + wrong answers)
4. **Teacher:** Dashboard with analytics, question management
5. **Student Profile (viewable by other students):**
   - Avatar (initials-based or uploaded)
   - Display name
   - Grade level
   - Stats: Total exams completed, Average score (%), Total points
   - Badges earned (if gamification added in v1.1)
   - "Private profile" indicator if user disabled visibility

---

## 10. Timeline

- **v1.0 Launch:** Less than 15 days
- **v1.1:** 
-- Notifications (push)
-- Offline mode
-- Advanced teacher features
- **v1.2:** 

-- Web version release 
-- Google sign up

---

## 11. Success Metrics

| Metric | Target |
|--------|--------|
| Student registrations | Track via Supabase |
| Daily active users | >100 within first month |
| Average exam completion rate | >70% |
| Leaderboard engagement | >50% students checked leaderboard weekly |
| Student satisfaction | >4.0 rating (future) |

---

## 12. Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Tight 15-day timeline | Prioritize MVP, leverage existing code |
| Exam content creation | Walid Kotb provides questions; bulk import tool |
| Teacher dashboard complexity | Start with read-only analytics |
| Offline sync complexity | Defer to v1.1 |

---

*Document Version: 1.4*
*Created: April 1, 2026*
