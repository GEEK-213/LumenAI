-- Lumen AI Schema Definitions
-- Run this in Supabase SQL Editor to create necessary tables.

-- 0. Subjects Table (user's courses/subjects)
create table if not exists public.subjects (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  name text not null
);

-- 0b. Units Table (modules within a subject)
create table if not exists public.units (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  subject_id uuid references public.subjects(id) on delete cascade not null,
  unit_number int,
  name text not null,
  description text
);

-- 1. Lectures Table
create table if not exists public.lectures (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  subject_id uuid references public.subjects(id) on delete cascade,
  unit_id uuid references public.units(id),
  title text,
  summary text,
  transcript text,
  raw_analysis jsonb,
  is_analyzed boolean default false,
  drive_file_id text
);

-- 2. Flashcards Table
create table if not exists public.flashcards (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  lecture_id uuid references public.lectures(id) on delete cascade,
  front text,
  back text
);

-- 3. Quiz Questions Table
create table if not exists public.quiz_questions (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  lecture_id uuid references public.lectures(id) on delete cascade,
  question text,
  options text[],
  correct_answer text,
  explanation text
);

-- 4. Mind Maps Table
create table if not exists public.mind_maps (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  lecture_id uuid references public.lectures(id) on delete cascade,
  nodes jsonb,
  edges jsonb
);

-- 5. Code Snippets Table
create table if not exists public.code_snippets (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  lecture_id uuid references public.lectures(id) on delete cascade,
  title text,
  language text,
  code_content text
);

-- 6. Extracted Tasks Table
create table if not exists public.extracted_tasks (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  lecture_id uuid references public.lectures(id) on delete cascade,
  title text,
  due_date text
);

-- 6b. Quiz Attempts (scoring history)
create table if not exists public.quiz_attempts (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  lecture_id uuid references public.lectures(id) on delete cascade not null,
  score int not null,
  total int not null,
  percentage numeric(5,2) generated always as (case when total > 0 then (score::numeric / total * 100) else 0 end) stored
);

-- 7. Syllabus Sources (for context)
create table if not exists public.syllabus_sources (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  subject_id uuid references public.subjects(id) on delete cascade,
  unit_id uuid references public.units(id),
  title text,
  file_path text,
  extracted_text text,
  metadata jsonb
);

-- 8. User Integrations (Google Classroom tokens, etc.)
create table if not exists public.user_integrations (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null unique,
  google_tokens jsonb
);


-- ═══════════════════════════════════════════════════════════
-- INDEXES (query performance on foreign keys)
-- ═══════════════════════════════════════════════════════════

create index if not exists idx_subjects_user_id on public.subjects(user_id);
create index if not exists idx_units_subject_id on public.units(subject_id);
create index if not exists idx_units_user_id on public.units(user_id);
create index if not exists idx_lectures_user_id on public.lectures(user_id);
create index if not exists idx_lectures_subject_id on public.lectures(subject_id);
create index if not exists idx_lectures_unit_id on public.lectures(unit_id);
create index if not exists idx_flashcards_user_id on public.flashcards(user_id);
create index if not exists idx_flashcards_lecture_id on public.flashcards(lecture_id);
create index if not exists idx_quiz_questions_user_id on public.quiz_questions(user_id);
create index if not exists idx_quiz_questions_lecture_id on public.quiz_questions(lecture_id);
create index if not exists idx_mind_maps_lecture_id on public.mind_maps(lecture_id);
create index if not exists idx_code_snippets_lecture_id on public.code_snippets(lecture_id);
create index if not exists idx_extracted_tasks_user_id on public.extracted_tasks(user_id);
create index if not exists idx_extracted_tasks_lecture_id on public.extracted_tasks(lecture_id);
create index if not exists idx_quiz_attempts_user_id on public.quiz_attempts(user_id);
create index if not exists idx_quiz_attempts_lecture_id on public.quiz_attempts(lecture_id);
create index if not exists idx_syllabus_sources_user_id on public.syllabus_sources(user_id);
create index if not exists idx_syllabus_sources_subject_id on public.syllabus_sources(subject_id);
create index if not exists idx_user_integrations_user_id on public.user_integrations(user_id);


-- ═══════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (Granular Policies)
-- ═══════════════════════════════════════════════════════════

-- Enable RLS on all tables
alter table public.subjects enable row level security;
alter table public.units enable row level security;
alter table public.lectures enable row level security;
alter table public.flashcards enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.mind_maps enable row level security;
alter table public.code_snippets enable row level security;
alter table public.extracted_tasks enable row level security;
alter table public.syllabus_sources enable row level security;
alter table public.user_integrations enable row level security;
alter table public.quiz_attempts enable row level security;

-- Subjects: granular policies
create policy "subjects_select" on public.subjects for select using (auth.uid() = user_id);
create policy "subjects_insert" on public.subjects for insert with check (auth.uid() = user_id);
create policy "subjects_update" on public.subjects for update using (auth.uid() = user_id);
create policy "subjects_delete" on public.subjects for delete using (auth.uid() = user_id);

-- Units: granular policies
create policy "units_select" on public.units for select using (auth.uid() = user_id);
create policy "units_insert" on public.units for insert with check (auth.uid() = user_id);
create policy "units_update" on public.units for update using (auth.uid() = user_id);
create policy "units_delete" on public.units for delete using (auth.uid() = user_id);

-- Lectures: granular policies
create policy "lectures_select" on public.lectures for select using (auth.uid() = user_id);
create policy "lectures_insert" on public.lectures for insert with check (auth.uid() = user_id);
create policy "lectures_update" on public.lectures for update using (auth.uid() = user_id);
create policy "lectures_delete" on public.lectures for delete using (auth.uid() = user_id);

-- Flashcards: granular policies
create policy "flashcards_select" on public.flashcards for select using (auth.uid() = user_id);
create policy "flashcards_insert" on public.flashcards for insert with check (auth.uid() = user_id);
create policy "flashcards_update" on public.flashcards for update using (auth.uid() = user_id);
create policy "flashcards_delete" on public.flashcards for delete using (auth.uid() = user_id);

-- Quiz Questions: granular policies
create policy "quiz_questions_select" on public.quiz_questions for select using (auth.uid() = user_id);
create policy "quiz_questions_insert" on public.quiz_questions for insert with check (auth.uid() = user_id);
create policy "quiz_questions_update" on public.quiz_questions for update using (auth.uid() = user_id);
create policy "quiz_questions_delete" on public.quiz_questions for delete using (auth.uid() = user_id);

-- Mind Maps: granular policies
create policy "mind_maps_select" on public.mind_maps for select using (auth.uid() = user_id);
create policy "mind_maps_insert" on public.mind_maps for insert with check (auth.uid() = user_id);
create policy "mind_maps_update" on public.mind_maps for update using (auth.uid() = user_id);
create policy "mind_maps_delete" on public.mind_maps for delete using (auth.uid() = user_id);

-- Code Snippets: granular policies
create policy "code_snippets_select" on public.code_snippets for select using (auth.uid() = user_id);
create policy "code_snippets_insert" on public.code_snippets for insert with check (auth.uid() = user_id);
create policy "code_snippets_update" on public.code_snippets for update using (auth.uid() = user_id);
create policy "code_snippets_delete" on public.code_snippets for delete using (auth.uid() = user_id);

-- Extracted Tasks: granular policies
create policy "extracted_tasks_select" on public.extracted_tasks for select using (auth.uid() = user_id);
create policy "extracted_tasks_insert" on public.extracted_tasks for insert with check (auth.uid() = user_id);
create policy "extracted_tasks_update" on public.extracted_tasks for update using (auth.uid() = user_id);
create policy "extracted_tasks_delete" on public.extracted_tasks for delete using (auth.uid() = user_id);

-- Syllabus Sources: granular policies
create policy "syllabus_sources_select" on public.syllabus_sources for select using (auth.uid() = user_id);
create policy "syllabus_sources_insert" on public.syllabus_sources for insert with check (auth.uid() = user_id);
create policy "syllabus_sources_update" on public.syllabus_sources for update using (auth.uid() = user_id);
create policy "syllabus_sources_delete" on public.syllabus_sources for delete using (auth.uid() = user_id);

-- User Integrations: granular policies
create policy "user_integrations_select" on public.user_integrations for select using (auth.uid() = user_id);
create policy "user_integrations_insert" on public.user_integrations for insert with check (auth.uid() = user_id);
create policy "user_integrations_update" on public.user_integrations for update using (auth.uid() = user_id);
create policy "user_integrations_delete" on public.user_integrations for delete using (auth.uid() = user_id);

-- Quiz Attempts: granular policies
create policy "quiz_attempts_select" on public.quiz_attempts for select using (auth.uid() = user_id);
create policy "quiz_attempts_insert" on public.quiz_attempts for insert with check (auth.uid() = user_id);
create policy "quiz_attempts_update" on public.quiz_attempts for update using (auth.uid() = user_id);
create policy "quiz_attempts_delete" on public.quiz_attempts for delete using (auth.uid() = user_id);
