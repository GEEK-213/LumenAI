-- Canvas Pins: Persists user-pinned content blocks on the spatial canvas
CREATE TABLE IF NOT EXISTS canvas_pins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
    pin_type TEXT NOT NULL CHECK (pin_type IN ('mind_map_node', 'flashcard')),
    content JSONB NOT NULL DEFAULT '{}',
    x FLOAT DEFAULT 0,
    y FLOAT DEFAULT 0,
    width FLOAT DEFAULT 200,
    height FLOAT DEFAULT 120,
    color TEXT DEFAULT '#6C5CE7',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_canvas_pins_user_subject ON canvas_pins(user_id, subject_id);

-- RLS
ALTER TABLE canvas_pins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own pins"
    ON canvas_pins FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
