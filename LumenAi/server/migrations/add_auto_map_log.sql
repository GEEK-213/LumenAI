-- Auto-Map Log: Tracks AI suggestions for lecture → unit mapping
CREATE TABLE IF NOT EXISTS auto_map_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
    suggested_unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
    confidence FLOAT DEFAULT 0.0,
    reason TEXT,
    accepted BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast lookups by lecture
CREATE INDEX IF NOT EXISTS idx_auto_map_log_lecture_id ON auto_map_log(lecture_id);

-- RLS Policy
ALTER TABLE auto_map_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own auto-map logs"
    ON auto_map_log FOR SELECT
    USING (
        lecture_id IN (
            SELECT id FROM lectures WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Service role can insert auto-map logs"
    ON auto_map_log FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Service role can update auto-map logs"
    ON auto_map_log FOR UPDATE
    USING (true);
