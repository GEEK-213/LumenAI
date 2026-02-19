-- Seed Data for Lumen AI
-- Run this in the Supabase SQL Editor

-- 1. Create a dummy user identity to associate data with (if you want to test RLS properly)
-- OR just insert directly if RLS is disabled or if running as superuser.

-- For simplicity, we insert into public tables.
-- NOTE: You will need to use the UUID of your ACTUAL logged-in user if you want to see this data in the app.
-- REPLACE 'YOUR_USER_ID_HERE' with your actual User UID from the Authentication tab.

-- Example: 
-- insert into public.subjects (name, user_id) values ('Computer Science 101', 'YOUR_USER_ID_HERE');

-- HOWEVER, since I don't know your ID, I will create a function to help you seed for yourself.

create or replace function seed_for_user(target_user_id uuid)
returns void
language plpgsql
as $$
declare
  subject_id uuid;
begin
  -- Insert Subject
  insert into public.subjects (name, user_id, color_hex)
  values ('Computer Science 101', target_user_id, '#FF5733')
  returning id into subject_id;

  -- Insert Unit 1
  insert into public.units (name, subject_id, user_id, unit_number)
  values ('Unit 1: Introduction to AI', subject_id, target_user_id, 1);

  -- Insert Unit 2
  insert into public.units (name, subject_id, user_id, unit_number)
  values ('Unit 2: Neural Networks', subject_id, target_user_id, 2);
  
  raise notice 'Seeded data for user %', target_user_id;
end;
$$;

-- USAGE:
-- 1. Copy your User UID from the Authentication tab.
-- 2. Run: select seed_for_user('YOUR_PASTED_UUID');
