## Servidor de proyectos

La carpeta `server` contiene un proyecto Godot independiente que puede ejecutarse en modo headless. Mantiene una conexión TCP persistente y almacena cada proyecto como el mismo JSON que utiliza el cliente, dentro de una carpeta por proyecto. No requiere cuentas, perfiles, servicios de terceros ni dependencias de pago.

### Ejecutar con Docker

Desde la raíz del repositorio:

```
docker build -t astrum-nova-server ./server
docker run --rm -e ASTRUM_SERVER_PASSWORD="password123" -p 2456:2456 -v astrum-nova-data:/data astrum-nova-server
```

El volumen `astrum-nova-data` conserva los proyectos aunque se elimine el contenedor. La imagen descarga el ejecutable oficial gratuito de Godot 4.6 durante la compilación.

También se puede abrir `server/project.godot` con Godot y ejecutar el proyecto en modo headless. En PowerShell:

```powershell
$env:ASTRUM_SERVER_PASSWORD = "cambia-esta-clave"
godot --headless --path server
```

`ASTRUM_SERVER_PASSWORD` es obligatoria. Se puede cambiar el puerto con `ASTRUM_SERVER_PORT` (por defecto `2456`) y el directorio de datos con `ASTRUM_DATA_DIR` (por defecto `user://projects`; en Docker, `/data`).

### Uso desde el cliente

En **CONNECT TO SERVER**, introduce la IP o el nombre de host del servidor; se puede añadir el puerto como `host:puerto`. Introduce la misma contraseña configurada en el servidor. La conexión autenticada permanece abierta al cerrar el menú y se puede cortar volviendo a abrirlo y pulsando **Disconnect**.

Los proyectos remotos aparecen en **OPEN SIMULATION** con el icono de nube. Al seleccionarlos se descargan a la carpeta configurada en el cliente y se abren con el flujo de simulación actual. Los proyectos locales no se suben automáticamente: con el cliente conectado, pulsa **Upload** en la fila del proyecto que quieras subir. Si ya existe un proyecto remoto con ese nombre, la subida lo reemplaza. Los cambios posteriores de proyectos remotos (descargados o subidos explícitamente) guardados mientras el cliente está conectado también se sincronizan al servidor; el resto de los proyectos locales no se sube automáticamente.

El protocolo intercambia JSON delimitado por líneas sobre TCP. No cifra el tráfico: contraseña y proyectos viajan en texto claro. Está pensado para redes de confianza, tal como requiere este proyecto; no se recomienda exponerlo directamente a Internet.
