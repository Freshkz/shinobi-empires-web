# Shinobi Empires — sitio web

Página de presentación y descarga del juego. Se publica con GitHub Pages.
El juego se descarga desde la sección Releases (`ShinobiEmpires.zip`).

## Publicar una versión nueva del juego

1. Generar el build de Windows del juego (`shinobi-empires\Builds\Windows`).
2. Doble clic en `publicar_juego.bat`. Comprime el build y lo sube como Release; la página baja siempre la última.

Requisitos en cada PC: este repo clonado **al lado** de `shinobi-empires` (misma carpeta padre) y `gh auth login` hecho.
Si el juego está en otra carpeta: `publicar_juego.bat -Build "D:\ruta\Builds\Windows"`.
Para probar sin subir nada: `publicar_juego.bat -Prueba` (deja el ZIP en el Escritorio).
