import difflib

def compare(subject, course):
    subject = subject.lower()
    course = course.lower()
    
    # Fast path substring match
    if subject in course or course in subject:
        print(f"[SUBSTRING MATCH] '{subject}' in '{course}'")
        return 1.0
        
    # Difflib matching
    ratio = difflib.SequenceMatcher(None, course, subject).ratio()
    print(f"[DIFFLIB MATCH] '{subject}' <-> '{course}' | Ratio: {ratio:.3f}")
    return ratio

subject_name = "Cyber Security"

print("--- Testing Classroom Sync Fuzzy Logic ---")
compare(subject_name, "Cyber Security")
compare(subject_name, "ISA 2 Cyber Security MOOC")
compare(subject_name, "2025-26_TYBCA_Cyber Security")
compare(subject_name, "Cyber Security(2025-26_TYBCA)")
compare(subject_name, "Cloud Computing")
compare(subject_name, "Data Analytics")
compare(subject_name, "MySQL_SQL and Database Testing_course2")
compare(subject_name, "Software Engineering")
print("--- End Test ---")
