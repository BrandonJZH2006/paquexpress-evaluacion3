# schemas.py
from typing import Optional, List
from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    id_usuario: int
    nombre: str
    email: EmailStr
    rol: str
    access_token: str
    token_type: str

    class Config:
        orm_mode = True


class PaqueteBase(BaseModel):
    id_paquete: int
    codigo_rastreo: str
    direccion_destino: str
    estado: str
    lat_destino: Optional[float] = None
    lng_destino: Optional[float] = None

    class Config:
        orm_mode = True


class EntregaCreate(BaseModel):
    id_usuario: int
    id_paquete: int
    lat: float
    lng: float
    observaciones: Optional[str] = None
