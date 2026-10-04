# Assets de los menús

Los cinco PNG se generaron con la herramienta integrada `image_gen.imagegen`, usando el atlas del templo y las piedras de los botones como referencias de estilo. Los prompts completos están en [generation_prompts.json](generation_prompts.json).

| Archivo | Uso |
| --- | --- |
| `fondo_principal.png` | Fondo de pantalla completa del menú principal. |
| `fondo_selector.png` | Fondo distinto para la selección de niveles. |
| `piedra.png` | Textura de los botones cuadrados de niveles e iconos. |
| `piedra_alargada.png` | Textura rectangular para menú principal, opciones de pausa y Volver. |
| `titulo_piedra.png` | Logotipo «RE:CONSTRUCTION» con letras de piedra para el menú principal. |
| `pausa.svg` | Botón para abrir la pausa. |
| `sonido.svg` / `silencio.svg` | Estados del botón de audio. |

La piedra cuadrada se importa a 128 px y la rectangular a 512 px. `stone_button.gd` ofrece la propiedad `elongated` para elegir la textura rectangular; recorta sus márgenes transparentes y ajusta los bordes según la altura, conservando las esquinas al variar el ancho. Los originales se conservan. Los SVG son gráficos de píxeles creados directamente en código. Las letras de los botones se dibujan en Godot, con sombra superior y luz inferior para simular el grabado; el logotipo sí forma parte de su PNG.

La fuente Noto Sans Mono Bold y su licencia están en `fonts/`.
