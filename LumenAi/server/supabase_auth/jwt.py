class JWTBearer(HTTPBearer):
    def __init__(self, auto_error: bool = True):
        super(JWTBearer, self) .__init__(auto_error=auto_error)

    async def __call__(self, request: Request):
        credentials: HTTPAuthorizationCredentials = await super(JWTBearer, self) .__call__(request)
        if credentials:
            if not credentials.scheme == "Bearer":
                raise HTTPException(status_code=403, detail= "Invaild authentication scheme.")
            if not self.verify_jwt(credentials.credentials):
                raise HTTPException(status_code=403, detail = "Invaild token or expired token")
            return credentials.credentials
        else:
            raise HTTPEception(status_code = 403, detail="Invaild authorization code.")
        
    def verify_jwt (self, jwtoken: str) -> bool:
        isTokenVaild: bool = False

        # try:
        #     payload 