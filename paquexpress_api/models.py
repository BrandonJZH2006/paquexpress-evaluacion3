# models.py
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, DECIMAL, Text
from sqlalchemy.orm import relationship

from database import Base


class Usuario(Base):
    __tablename__ = "usuarios"

    id_usuario = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    email = Column(String(100), nullable=False, unique=True, index=True)
    password_hash = Column(String(255), nullable=False)
    rol = Column(String(50), nullable=False, default="agente")
    activo = Column(Boolean, nullable=False, default=True)
    fecha_creacion = Column(DateTime)

    entregas = relationship("Entrega", back_populates="usuario")
    asignaciones = relationship("Asignacion", back_populates="usuario")


class Paquete(Base):
    __tablename__ = "paquetes"

    id_paquete = Column(Integer, primary_key=True, index=True)
    codigo_rastreo = Column(String(50), nullable=False, unique=True)
    direccion_destino = Column(String(255), nullable=False)
    lat_destino = Column(DECIMAL(10, 8))
    lng_destino = Column(DECIMAL(11, 8))
    estado = Column(String(20), nullable=False, default="pendiente")
    fecha_creacion = Column(DateTime)

    entregas = relationship("Entrega", back_populates="paquete")
    asignaciones = relationship("Asignacion", back_populates="paquete")


class Asignacion(Base):
    __tablename__ = "asignaciones"

    id_asignacion = Column(Integer, primary_key=True, index=True)
    id_paquete = Column(Integer, ForeignKey("paquetes.id_paquete"), nullable=False)
    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=False)
    fecha_asignacion = Column(DateTime)

    paquete = relationship("Paquete", back_populates="asignaciones")
    usuario = relationship("Usuario", back_populates="asignaciones")


class Entrega(Base):
    __tablename__ = "entregas"

    id_entrega = Column(Integer, primary_key=True, index=True)
    id_paquete = Column(Integer, ForeignKey("paquetes.id_paquete"), nullable=False)
    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=False)
    fecha_hora = Column(DateTime)
    lat_entrega = Column(DECIMAL(10, 8), nullable=False)
    lng_entrega = Column(DECIMAL(11, 8), nullable=False)
    foto_url = Column(String(255), nullable=False)
    observaciones = Column(Text)

    paquete = relationship("Paquete", back_populates="entregas")
    usuario = relationship("Usuario", back_populates="entregas")
