import os
import json
from cryptography.fernet import Fernet
import base64

# Base64 32-byte key - in production, this should be set in environment variables!
# Example of generating one: Fernet.generate_key()
_DEFAULT_KEY = b'G1yB-c741qQkP-1F6hIHTm4d0tT8WJq1z6Qz0lZb_Gk='
_ENCRYPTION_KEY = os.getenv('ENCRYPTION_KEY', _DEFAULT_KEY)
_fernet = Fernet(_ENCRYPTION_KEY)

def encrypt_dict(data: dict) -> str:
    """Encrypts a dictionary into a base64 string."""
    json_bytes = json.dumps(data).encode('utf-8')
    encrypted_bytes = _fernet.encrypt(json_bytes)
    return base64.b64encode(encrypted_bytes).decode('utf-8')

def decrypt_dict(encrypted_data: str) -> dict:
    """Decrypts a base64 string back into a dictionary."""
    encrypted_bytes = base64.b64decode(encrypted_data)
    json_bytes = _fernet.decrypt(encrypted_bytes)
    return json.loads(json_bytes.decode('utf-8'))
