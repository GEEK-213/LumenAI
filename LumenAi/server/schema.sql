-- Lumen AI Schema Definitions
-- Run this in Supabase SQL Editor to create necessary tables.

-- 0. Subjects Table (user's courses/subjects)
create table if not exists public.subjects (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  name text not null
);

alter table public.subjects enable row level security;
create policy "Users can manage their own subjects" on public.subjects
  for all using (auth.uid() = user_id);

-- 1. Lectures Table
create table if not exists public.lectures (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null, -- Requires valid Auth User
  unit_id uuid references public.units(id),
  title text,
  summary text,
  transcript text,
  raw_analysis jsonb -- Stores the full JSON from Gemini
);


-- 2. Flashcards Table
create table if not exists public.flashcards (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  lecture_id uuid references public.lectures(id) on delete cascade,
  front text,
  back text
);

-- 3. Quiz Questions Table
create table if not exists public.quiz_questions (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  lecture_id uuid references public.lectures(id) on delete cascade,
  question text,
  options text[], -- Array of strings
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
  due_date text -- Storing as text for simplicity, or timestamp if preferred
);

-- 7. Syllabus Sources (for context)
create table if not exists public.syllabus_sources (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null,
  unit_id uuid references public.units(id),
  title text,
  file_path text,
  extracted_text text,
  metadata jsonb
);

-- Enable RLS (Optional, recommended for production)
alter table public.lectures enable row level security;
alter table public.flashcards enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.mind_maps enable row level security;
alter table public.code_snippets enable row level security;
alter table public.extracted_tasks enable row level security;
alter table public.syllabus_sources enable row level security;

-- Basic Policy (Allow all for authenticated users matching user_id)
create policy "Users can all their own data" on public.lectures
  for all using (auth.uid() = user_id);
  
create policy "Users can all their own data" on public.flashcards
  for all using (auth.uid() = user_id);

create policy "Users can all their own data" on public.quiz_questions
  for all using (auth.uid() = user_id);

create policy "Users can all their own data" on public.mind_maps
  for all using (auth.uid() = user_id);

create policy "Users can all their own data" on public.code_snippets
  for all using (auth.uid() = user_id);

create policy "Users can all their own data" on public.extracted_tasks
  for all using (auth.uid() = user_id);

create policy "Users can all their own data" on public.syllabus_sources
  for all using (auth.uid() = user_id);
