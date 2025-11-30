# main.py
# main.py
from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Form, Header
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

import os
import shutil
from datetime import datetime, timedelta
from decimal import Decimal
from typing import List, Optional

from jose import JWTError, jwt
import hashlib
from fastapi.security import HTTPBearer
from database import Base, engine, get_db
from models import Usuario, Paquete, Asignacion, Entrega
from schemas import LoginRequest, LoginResponse, PaqueteBase

# Crear tablas si no existen 
Base.metadata.create_all(bind=engine)

app = FastAPI(title="API Paquexpress")
bearer_scheme = HTTPBearer()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================
# CONFIGURACIÓN DE SEGURIDAD
# ==========================

SECRET_KEY = "CAMBIA_ESTA_CADENA_POR_ALGO_MAS_LARGO_Y_SECRETO"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60  # 1 hora


def get_password_hash(password: str) -> str:
    """
    Genera un hash SHA-256 de la contraseña.
    No es bcrypt, pero es un hash seguro para efectos académicos.
    """
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Compara el hash de la contraseña que el usuario escribe
    con el hash almacenado en la base de datos.
    """
    return get_password_hash(plain_password) == hashed_password



def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def get_current_user(
    token: str = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> Usuario:
    """
    Obtiene el token del usuario mediante HTTPBearer,
    valida el JWT y regresa el usuario autenticado.
    """

    # token.credentials ya contiene SOLO el JWT limpio
    raw_token = token.credentials

    try:
        payload = jwt.decode(raw_token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")

        if email is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido: no contiene 'sub'"
            )

    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado"
        )

    # Buscar el usuario en BD
    usuario = db.query(Usuario).filter(Usuario.email == email).first()

    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no encontrado"
        )

    if not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuario inactivo"
        )

    return usuario

def read_root():
    return {"message": "API Paquexpress funcionando"}


# LOGIN BÁSICO

@app.post("/login", response_model=LoginResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(Usuario.email == data.email).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales inválidas (usuario no encontrado)"
        )

    # Ahora verificamos usando bcrypt
    if not verify_password(data.password, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales inválidas (contraseña incorrecta)"
        )

    # Generar token JWT
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
      data={"sub": usuario.email},
      expires_delta=access_token_expires,
    )

    return LoginResponse(
        id_usuario=usuario.id_usuario,
        nombre=usuario.nombre,
        email=usuario.email,
        rol=usuario.rol,
        access_token=access_token,
        token_type="bearer",
    )



# PAQUETES ASIGNADOS A UN AGENTE

@app.get("/paquetes/asignados/{id_usuario}", response_model=List[PaqueteBase])
def obtener_paquetes_asignados(
    id_usuario: int,
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    if current_user.id_usuario != id_usuario:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para ver paquetes de otro usuario",
        )

    paquetes = (
        db.query(Paquete)
        .join(Asignacion, Asignacion.id_paquete == Paquete.id_paquete)
        .filter(Asignacion.id_usuario == id_usuario)
        .filter(Paquete.estado == "pendiente")
        .all()
    )

    return paquetes



@app.post("/entregas/")
async def registrar_entrega(
    id_usuario: int = Form(...),
    id_paquete: int = Form(...),
    lat: float = Form(...),
    lng: float = Form(...),
    observaciones: str = Form(""),
    foto: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    # Validar que el usuario que manda la entrega sea el mismo del token
    if current_user.id_usuario != id_usuario:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No puedes registrar entregas a nombre de otro usuario",
        )

    # Verificar que el paquete exista
    paquete = db.query(Paquete).filter(Paquete.id_paquete == id_paquete).first()
    if not paquete:
        raise HTTPException(status_code=404, detail="Paquete no encontrado")

    fotos_dir = os.path.join(os.path.dirname(__file__), "fotos")
    os.makedirs(fotos_dir, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    extension = os.path.splitext(foto.filename)[1]
    filename = f"entrega_{id_paquete}_{timestamp}{extension}"
    save_path = os.path.join(fotos_dir, filename)

    with open(save_path, "wb") as buffer:
        shutil.copyfileobj(foto.file, buffer)

    lat_dec = Decimal(str(lat))
    lng_dec = Decimal(str(lng))

    nueva_entrega = Entrega(
        id_paquete=id_paquete,
        id_usuario=id_usuario,
        lat_entrega=lat_dec,
        lng_entrega=lng_dec,
        foto_url=f"fotos/{filename}",
        observaciones=observaciones if observaciones else None,
        fecha_hora=datetime.now(),
    )

    db.add(nueva_entrega)
    paquete.estado = "entregado"

    db.commit()
    db.refresh(nueva_entrega)

    return {
        "message": "Entrega registrada correctamente",
        "id_entrega": nueva_entrega.id_entrega,
        "foto_url": nueva_entrega.foto_url,
    }

@app.post("/util/hash-password")
def util_hash_password(password: str):
    return {"password": password, "hash": get_password_hash(password)}

