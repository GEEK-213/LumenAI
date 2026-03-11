-- Add columns for lazy AI processing architecture
-- Run this in the Supabase SQL Editor

ALTER TABLE lectures ADD COLUMN IF NOT EXISTS drive_file_id TEXT;
ALTER TABLE lectures ADD COLUMN IF NOT EXISTS is_analyzed BOOLEAN DEFAULT TRUE;

-- Set existing lectures as already analyzed (they were processed by the old pipeline)
UPDATE lectures SET is_analyzed = TRUE WHERE is_analyzed IS NULL;
