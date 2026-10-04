# Interfaces

`Escenas/Juego.tscn` es la escena de inicio (F5). Las pantallas se pueden abrir individualmente en el editor:

- `main_menu.tscn`: Iniciar partida abre T1; Selección de niveles abre el selector; Salir cierra el juego.
- `level_selector.tscn`: T1 y T2 en la columna izquierda; niveles 1–5 y 6–10 en dos filas. Todos están disponibles.
- `pause_menu.tscn`: Continuar, Selector de niveles, Reiniciar y sonido. Escape alterna la pausa. El botón de la esquina superior derecha también la abre.
- `standalone_pause.tscn`: la misma pausa para ejecutar una sala directamente con F6, incluido el campo de pruebas `nivel_1`.

Las pantallas usan un diseño de 1280 × 720 que se escala y centra según el tamaño de ventana. Los fondos cubren toda la pantalla. Los scripts de presentación usan `@tool` para mostrar el estilo en el editor.

## Navegación y audio

`Juego.gd` carga una sala a la vez. Volver desde el selector abierto durante una pausa conserva la partida. Elegir otra sala la inicia desde cero. Reiniciar borra las vidas/sombras de la sala; R conserva las grabaciones como antes. Completar una sala avanza al siguiente destino; completar el 10 vuelve al selector.

El sonido silencia el bus Master y guarda la preferencia en `user://interface.cfg`. La pausa detiene los mecanismos, animaciones, grabaciones, reaparición y rebobinado.

## Destinos jugables

`level_catalog.gd` contiene las rutas y el orden de progreso: T1, T2 y después los niveles 1–10. La disposición del selector es independiente: muestra T1/T2 a la izquierda y los niveles numerados en dos filas.

- T1: camino corto con hielo e indicación de Fuego.
- T2: placa Metal, compuerta y rayo; permite aprender a dejar una sombra Metal y cruzar como Eléctrica.
- La puerta de T1 lleva a T2 tanto en la campaña como al ejecutar T1 directamente con F6.
- 1–5: las salas existentes.
- 6: variante de Sala01 con pinchos y rayo al final.
- 7: variante de Sala02 con compuerta vinculada a la placa y pinchos.
- 8: variante de Sala03 con hielo y compuerta vinculada a la placa elevada.
- 9: variante de Sala04 con dos placas y dos compuertas.
- 10: variante de Sala05 con ciclos de pinchos más rápidos, palanca para el rayo y otro bloque de hielo.

Los tutoriales tienen un TileMapLayer del templo. Las variantes son escenas heredadas, editables, que reutilizan salas y obstáculos existentes. Los símbolos mantienen las indicaciones sin texto en los niveles.
