# Astrum Nova

**Astrum Nova** es un simulador astronómico tridimensional para crear y explorar sistemas de cuerpos celestes. Permite configurar proyectos y simulaciones, observar su evolución y consultar los datos físicos de cada cuerpo desde una interfaz interactiva.

> **Estado del proyecto:** en desarrollo. En este momento no hay compilaciones descargables publicadas. El primer canal de distribución previsto es GitHub Releases para Windows.

## Funcionalidades

- Crear proyectos con una o más simulaciones y guardar sus datos localmente.
- Agregar y editar cuerpos celestes con masa, radio, posición, velocidad y color.
- Ejecutar, pausar, reiniciar y ajustar la velocidad de la simulación.
- Explorar el sistema en una vista 3D con cámara orbital, trayectorias e indicador de orientación X/Y/Z.
- Consultar y seleccionar cuerpos desde el inspector, tanto individualmente como desde la lista de cuerpos.
- Simular atracción gravitatoria entre los cuerpos.
- Resolver colisiones conservando el cuerpo de mayor masa y actualizando la masa, la velocidad, la posición y el radio resultantes.
- Mostrar superficies procedurales, iluminación estelar, resplandor de estrellas y miniaturas de los cuerpos.
- Configurar unidades de visualización, ubicación de proyectos y modo de ventana o pantalla completa.
- Conectarse opcionalmente a un servidor para cargar, subir y sincronizar proyectos remotos.

## Descargar e instalar

Las versiones compiladas se publicarán en la página de [Releases de Astrum Nova](https://github.com/Santino7537/Astrum-Nova/releases). **Todavía no hay una versión publicada allí.**

Cuando haya una release para Windows:

1. Abrí la página de [Releases](https://github.com/Santino7537/Astrum-Nova/releases) y elegí la versión más reciente.
2. Descargá el paquete de Windows adjunto, que se distribuirá como un archivo ZIP.
3. Extraé el ZIP en una carpeta de tu elección.
4. Ejecutá el archivo `.exe` incluido.

La compilación exportada incluirá los archivos que necesita el cliente y no requerirá instalar Godot. Las plataformas disponibles y los requisitos específicos se indicarán en cada release.

### Ejecutar desde el código fuente

Para probar o modificar el proyecto no hace falta esperar a una release, pero sí instalar **Godot 4.6**:

1. Descargá Godot 4.6 desde el [archivo oficial de versiones](https://godotengine.org/download/archive/) e instalalo o descomprimí el ejecutable.
2. Cloná el repositorio:

   ```bash
   git clone https://github.com/Santino7537/Astrum-Nova.git
   ```

3. Abrí Godot, importá el proyecto ubicado en `client/project.godot` y esperá a que termine la importación de recursos.
4. Ejecutá el proyecto desde el editor con **F5**. **F6** ejecuta la escena que esté abierta actualmente en el editor.

El cliente está configurado para Godot 4.6 con el renderizador **Compatibility**.

## Uso básico

- Creá o abrí un proyecto desde el menú principal. Los proyectos se guardan en la ubicación configurada en los ajustes.
- Creá una simulación y agregá sus cuerpos celestes.
- En la vista 3D, arrastrá con el botón izquierdo para orbitar la cámara, usá la rueda del ratón para acercar o alejar y seleccioná un cuerpo para enfocarlo.
- Usá los controles de simulación para iniciar, pausar o reiniciar la evolución y cambiar su velocidad.
- Abrí el inspector para consultar o editar los datos del cuerpo seleccionado, o para elegir otro desde la lista.

## Modelo de simulación y alcance

La interacción gravitatoria se calcula con la ley de gravitación newtoniana entre los cuerpos. El movimiento se integra numéricamente y se usa un suavizado gravitatorio para evitar singularidades cuando dos cuerpos están muy cerca. Las colisiones se representan como una fusión inelástica: sobrevive el cuerpo de mayor masa y se combinan las propiedades físicas correspondientes.

El modelo es una aproximación interactiva y **no está validado como herramienta de predicción astronómica de alta precisión**. No representa todos los fenómenos físicos de un sistema real. Las texturas, la iluminación y los efectos visuales son representaciones procedurales destinadas a facilitar la exploración.

## Proyectos remotos (opcional)

El cliente puede conectarse a una instancia del servidor incluida en el repositorio. El servidor permite almacenar, cargar y sincronizar proyectos seleccionados; no es necesario para crear y ejecutar proyectos locales.

Para instrucciones de instalación y configuración del servidor, consultá [`server/README.md`](server/README.md). **Importante:** el protocolo actual utiliza TCP sin cifrado; las credenciales y los proyectos se transmiten en texto claro. Usalo solamente en redes de confianza y no expongas el servidor directamente a Internet.

## Publicar una compilación para Windows

Para habilitar la descarga desde GitHub Releases, quien mantiene el proyecto debe:

1. Instalar Godot 4.6 y las plantillas de exportación correspondientes.
2. En **Project > Export**, crear un preset **Windows Desktop** y exportar el cliente.
3. Probar los archivos exportados en una instalación limpia de Windows, sin depender del editor de Godot.
4. Empaquetar en un ZIP todos los archivos generados que sean necesarios para ejecutar la aplicación.
5. Crear una release en GitHub con una etiqueta de versión (por ejemplo, `v0.1.0`), adjuntar el ZIP y describir los cambios y requisitos.

Después de publicar la primera release, se puede actualizar esta sección con un enlace directo al paquete más reciente. Por ahora la publicación y la exportación son pasos manuales; este repositorio no incluye un flujo de compilación automática para releases.

## Estructura del repositorio

```text
client/   Cliente de escritorio y proyecto Godot
server/   Servidor opcional para almacenar y sincronizar proyectos
```

## Tecnologías

- [Godot Engine 4.6](https://godotengine.org/)
- GDScript
- JSON para almacenar los proyectos
- TCP para la comunicación opcional entre cliente y servidor

## Licencia

En el repositorio actual no se encontró un archivo de licencia. Consultá con las personas responsables del proyecto antes de reutilizar o redistribuir su código.
