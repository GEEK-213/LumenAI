from .supabase import supa

@app.get("/signup")
def signup():
    res = supa.auth.signup(email = "fjdksal@gmail.com", password ="1234")
    return res.get("access_token")

@app.get("/signout")
def signout():
    supa = init_supabase()
    res = supa.auth.sign_out()
    return "success"

@app.get("signin")
def signin():
    supa = init_supabase()
    res = supa.auth.sign_in_with_password({"email": "fjdksal@gmail.com", "password" :"1234"})
    return res.get("access_token")