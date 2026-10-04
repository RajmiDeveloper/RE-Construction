# Assets de los menús

Los tres PNG se generaron con la herramienta integrada `image_gen.imagegen`, usando el atlas del templo como referencia de estilo. Los prompts completos están en [generation_prompts.json](generation_prompts.json).

| Archivo | Uso |
| --- | --- |
| `fondo_principal.png` | Fondo de pantalla completa del menú principal. |
| `fondo_selector.png` | Fondo distinto para la selección de niveles. |
| `piedra.png` | Textura transparente compartida por los botones. |
| `pausa.svg` | Botón para abrir la pausa. |
| `sonido.svg` / `silencio.svg` | Estados del botón de audio. |

La piedra se importa a 128 px para que los bordes de `StyleBoxTexture` entren en los botones cuadrados. Los originales se conservan. Los SVG son gráficos de píxeles creados directamente en código. Las letras se dibujan en Godot, con sombra superior y luz inferior para simular el grabado; no forman parte de los PNG.

La fuente Noto Sans Mono Bold y su licencia están en `fonts/`.
