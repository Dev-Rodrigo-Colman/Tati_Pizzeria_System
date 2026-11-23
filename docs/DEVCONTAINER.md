# Entorno de desarrollo

El Codespace usa PHP 8.2 con Apache y MySQL 8.0 mediante Docker Compose. Apache publica `public/` en el puerto 80. La base de datos queda en un volumen persistente de desarrollo (`mysql_data`) y la aplicación se conecta al servicio `db`.

Las credenciales definidas en `compose.yaml` son exclusivamente para desarrollo local/Codespaces; no deben reutilizarse en producción.

## Abrir y reabrir el Codespace

1. En GitHub, abre el repositorio y selecciona **Code → Codespaces**. Crea un Codespace en la rama deseada, o selecciona **Resume** en uno detenido.
2. Al abrirlo por primera vez, acepta **Reopen in Container** si VS Code lo solicita. Dev Containers construye PHP/Apache y arranca MySQL automáticamente.
3. En la pestaña **Ports**, abre el puerto **80** etiquetado como **Tati Pizzas web**. Codespaces proporciona una URL HTTPS; puedes abrir esa URL desde el navegador del teléfono mientras tengas acceso al Codespace.
4. Si el entorno se detuvo, vuelve a **Code → Codespaces → Resume**. Los archivos del repositorio y los datos MySQL del volumen del Codespace se conservan al detenerlo. Si cambias la configuración del contenedor, ejecuta **Dev Containers: Rebuild Container** desde la paleta de comandos.

Mantén la visibilidad del puerto como **Private**; no publiques el entorno de desarrollo sin revisar antes los controles de acceso.
