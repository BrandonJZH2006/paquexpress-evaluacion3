📦 Paquexpress – Sistema de Entregas con Evidencia (FastAPI + Flutter + MySQL)
Proyecto desarrollado como parte de la Evaluación Unidad 3, integrando una aplicación móvil/web para agentes de entrega, una API REST en FastAPI y una base de datos estructurada en MySQL.
Incluye:
📱 App Flutter (Web y Android)
🚚 Registro de entregas con foto + GPS
🗺 Mapa interactivo (OpenStreetMap + flutter_map)
🔐 Inicio de sesión con JWT
🗃 API FastAPI conectada a MySQL
🗄 Script SQL completo
🧪 Datos de prueba para validación
🔧 Tecnologías Utilizadas
    Componente	Tecnología
    Backend API	FastAPI, Python 3.11, SQLAlchemy
    Frontend App	Flutter 3.x (Web/Android)
    Base de Datos	MySQL 8 / MariaDB
    Seguridad	JWT (python-jose), SHA-256
    Multimedia	image_picker, geolocator, flutter_map
🛠 Estructura del Repositorio
paquexpress-evaluacion3/
│── DB/
│   └── db.sql                    # Script de creación de base de datos y datos de prueba
│
│── paquexpress_api/              # API FastAPI
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   ├── schemas.py
│   ├── requirements.txt
│   └── fotos/                    # Carpeta donde se guardan las imágenes
│
│── paquexpress_app/              # Aplicación Flutter
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
│
└── README.md

🗃 Base de Datos
  Carga la base con:
  SOURCE DB/db.sql;
  Incluye:
    Usuarios de prueba:
        agente@paquexpress.com / 123456
        brandon@gmail.com / 123456
    Paquetes PKG y BR asignados a ambos usuarios.
    Entregas simuladas con evidencia para pruebas.
    Tablas: usuarios, paquetes, asignaciones, entregas.

⚙️ Instalación del Backend (FastAPI)
      1. Crear entorno virtual
        cd paquexpress_api
        python -m venv .venv
      2. Activar entorno
        Windows:
        .\.venv\Scripts\activate
      3. Instalar dependencias
        pip install -r requirements.txt
      4. Levantar servidor
        uvicorn main:app --reload
      Documentación automática:
        http://127.0.0.1:8000/docs

📱 Instalación de la App Flutter
    1. Entrar al proyecto:
      cd paquexpress_app
      flutter pub get
    2. Ejecutar versión Web (recomendada)
      flutter run -d edge
    3. O en Chrome:
      flutter run -d chrome

🔑 Credenciales de Prueba
      Usuario	Rol	Email	Contraseña
        Agente Prueba	agente	agente@paquexpress.com   	123456
        Brandon	agente	brandon@gmail.com 	123456
🚀 Características Principales
    ✔ Inicio de sesión seguro
        Validación SHA-256 del password.
        Generación y uso de tokens JWT.
        Endpoints protegidos con HTTPBearer.
    ✔ Consulta de paquetes asignados
        El usuario visualiza solo sus paquetes pendientes.
        Cargados desde MySQL vía FastAPI.
    ✔ Visualización en mapa
        Uso de flutter_map + OpenStreetMap.
        Pin exacto del destino de entrega.
    ✔ Registro de entrega
        Captura de foto (image_picker).
        Obtención de GPS (geolocator).
        Envío multipart a FastAPI.
        Guardado en carpeta /fotos/ + DB.
        Observaciones opcionales.
    ✔ Historial real
        Paquetes entregados aparecen como “entregado”.
        Entregas registradas con:
          foto
          coordenadas
          fecha
          id del agente
🧪 Ejecución del Flujo Completo
      Iniciar sesión.
      Ver lista de paquetes asignados.
      Seleccionar paquete.
      Ver ubicación del destino en mapa.
      Capturar fotografía.
      Obtener ubicación GPS.
      Enviar entrega.
      Ver confirmación.
      Validar en historial o en BD.
📝 Notas del Proyecto
      Perfecto para prácticas de:
      API REST
      Seguridad
      Movilidad
      Geolocalización
      Pruebas de integraciones
      Código modular y listo para escalar.
      Backend y app conectados completamente.
