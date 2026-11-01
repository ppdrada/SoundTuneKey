# <img src="assets/icon/icon.png" alt="Logo de Sound Tune Key" width="36"> Sound Tune Key

🇺🇸 [English](README.md) | 🇧🇷 [Português](README.pt-BR.md) | 🇪🇸 **Español**

Controla el audio de **una aplicación específica** directamente desde el teclado.

Elige la aplicación que quieres controlar (Spotify, Google Chrome, Discord o cualquier otra que esté reproduciendo sonido) y usa atajos globales para cambiar su volumen, pausarla o saltar de canción. El volumen del resto de tu computadora no se modifica.

![Sound Tune Key en acción: volumen por aplicación, silenciar, botones multimedia y el ícono de la barra de menús](docs/demo/demo-en.gif)

[![Descargar para Windows](https://img.shields.io/badge/Windows-Descargar_.exe-1DB954?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/ppdrada/SoundTuneKey/raw/main/download/SoundTuneKey.exe) [![Descargar para macOS](https://img.shields.io/badge/macOS-Descargar_.zip-1DB954?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/ppdrada/SoundTuneKey/raw/main/download/SoundTuneKey-mac.zip)

---

## 💻 Requisitos

### Windows

- Windows 10 u 11
- No hay que instalar nada: es un único `.exe`.

### macOS

- macOS 14.2 o posterior, en Macs con chip Apple o Intel
- No hay que instalar nada: solo descomprime y abre.

---

## ⌨️ Atajos

### Windows

| Atajo | Acción |
|---|---|
| `Ctrl + Alt + ↑` | 🔊 Sube el volumen de la aplicación seleccionada |
| `Ctrl + Alt + ↓` | 🔉 Baja el volumen de la aplicación seleccionada |
| `Ctrl + Alt + P` | ⏯️ Reproducir / pausar |
| `Ctrl + Alt + →` | ⏭️ Siguiente canción |
| `Ctrl + Alt + ←` | ⏪ Reinicia la canción actual · presiónalo dos veces en menos de 1 s para ⏮️ canción anterior |
| `Ctrl + Alt + M` | 🔇 Silencia / activa el sonido de la aplicación seleccionada (se conserva su volumen) |
| `Ctrl + Alt + A` | 🔁 Cambia la aplicación controlada a la siguiente de la lista (se muestra en el aviso en pantalla) |
| `Ctrl + Alt + V` | 🎤 Silencia / activa el micrófono (sirve para Discord, juegos y todo lo demás; solo silencia el micrófono configurado como predeterminado en Windows) |

Al usar los atajos de volumen o de silenciar, un pequeño aviso muestra por un momento la aplicación y el volumen en la parte inferior de la pantalla (al silenciar, el nombre de la aplicación y el altavoz se ponen en rojo), sin quitarle el foco a tu juego. No aparece sobre juegos en pantalla completa exclusiva (en ventana sin bordes sí funciona). Para desactivarlo, apaga el interruptor **Aviso en pantalla**, junto a "Controlando" en la ventana, o **Mostrar aviso en pantalla** en el menú de la bandeja.

> ℹ️ Reproducir/pausar y saltar de canción dependen de que la aplicación exponga controles multimedia a Windows (Spotify y las pestañas de Chrome lo hacen). Las aplicaciones sin ese soporte, como Discord, solo permiten controlar el volumen.

Los atajos también aparecen dentro del programa: haz clic en **Atajos** en la parte inferior de la ventana, o en el elemento **Atajos** del ícono de la bandeja, y se abre una ventanita con la lista. Junto a él, **Acerca de** muestra la versión, el autor y el enlace de GitHub.

### macOS

| Atajo | Acción |
|---|---|
| `⌘ + ⌥ + ↑` | 🔊 Sube el volumen de la aplicación seleccionada (mantenerlo presionado repite) |
| `⌘ + ⌥ + ↓` | 🔉 Baja el volumen de la aplicación seleccionada (mantenerlo presionado repite) |
| `⌃ + ⌥ + M` | 🔇 Silencia / activa el sonido de la aplicación seleccionada (se conserva el volumen) |
| `⌃ + ⌥ + P` | ⏯️ Reproducir / pausar |
| `⌃ + ⌥ + →` | ⏭️ Siguiente canción |
| `⌃ + ⌥ + ←` | ⏪ Reinicia la canción actual · presiónalo dos veces en menos de 1 s para ⏮️ canción anterior |
| `⌃ + ⌥ + A` | 🔁 Cambia la aplicación controlada a la siguiente de la lista (se muestra en el aviso en pantalla) |
| `⌃ + ⌥ + V` | 🎤 Silencia / activa el micrófono (sirve para Discord, juegos y todo lo demás; solo silencia el micrófono configurado como predeterminado en macOS) |

Al usar los atajos de volumen, silenciar, cambio de aplicación o micrófono, un pequeño aviso muestra por un momento la aplicación y el volumen en la parte inferior de la pantalla (en rojo al silenciar), sin quitar el foco, incluso sobre juegos en pantalla completa. Para desactivarlo, apaga el interruptor **Aviso en pantalla**, junto a "Controlando" en la ventana, o **Mostrar aviso en pantalla** en el menú de la barra de menús.

> ℹ️ `⌃` es la tecla Control y `⌥` es la tecla Option. Los atajos multimedia controlan la aplicación elegida cuando es **Spotify**, **Música**, **VLC** o un video en **Google Chrome**; las teclas multimedia del propio Mac (F7/F8/F9) siguen funcionando con la aplicación que esté reproduciendo. Los atajos también aparecen dentro del programa: haz clic en **Atajos** en la parte inferior de la ventana. Junto a él, **Acerca de** muestra la versión, el autor y el enlace de GitHub, y el ícono 🎤 silencia y activa el micrófono.

---

## 🚀 Cómo usar

### Windows

1. Haz clic en **Windows · Descargar .exe** arriba.
2. Abre el programa.
3. Selecciona en la lista la aplicación que quieres controlar.
4. ¡Listo! Usa los atajos de arriba, incluso dentro del juego.

El programa recuerda la última aplicación elegida la próxima vez que se abre. Las aplicaciones que están reproduciendo muestran un altavoz junto al volumen. Las aplicaciones abiertas que aún no han reproducido sonido aparecen en gris al final de la lista: puedes elegirlas de antemano, y el control de volumen empieza cuando reproduzcan (Windows solo le da volumen propio a una aplicación después de eso).

Debajo de "Controlando", la ventana tiene la **barra de tiempo** de la canción (tiempo actual a la izquierda, duración a la derecha; arrastra para ir a otra parte de la canción o del video), los botones **⏮ ⏯ ⏭**, que hacen lo mismo que los atajos, y la barra de volumen 🔈. Haz clic en el altavoz 🔈 para silenciar o devolver el sonido (silenciada: altavoz rojo, barra atenuada y el nombre de la aplicación en rojo en la lista); cambiar el volumen también quita el silencio. Los atajos cambian el volumen de 1 % en 1 % (mantenerlos presionados repite). Con clic derecho en cualquier aplicación de la lista aparece **Silenciar**, marcado cuando esa aplicación está silenciada; esto no cambia la aplicación controlada. La barra de tiempo solo funciona con aplicaciones que informan el tiempo de la canción a Windows (Spotify y las pestañas de Chrome lo hacen).

#### ⚠️ Aviso de Windows la primera vez

El `.exe` todavía no tiene firma digital, así que Windows puede mostrar **"Windows protegió su PC"**. Para abrirlo, haz clic en **Más información** → **Ejecutar de todas formas**. Solo hay que hacerlo la primera vez.

Si Windows lo bloquea **sin el botón "Ejecutar de todas formas"**, el PC tiene activado el **Control inteligente de aplicaciones**. Bloquea todo programa sin firma digital de pago, y no hay forma de permitir solo un programa. La única manera de abrir Sound Tune Key en ese PC es desactivarlo en **Seguridad de Windows → Control de aplicaciones y navegador → Configuración del Control inteligente de aplicaciones → Desactivado**. Windows no permite volver a activarlo sin reinstalar el sistema, así que piénsalo bien. En la mayoría de los PC ya viene desactivado.

#### 🖥️ Bandeja del sistema

Cerrar o minimizar la ventana no cierra el programa: sigue en el ícono de la bandeja (junto al reloj) y los atajos siguen funcionando. El programa viene en portugués, inglés y español: elígelo en **Acerca de**; la primera vez, sigue el idioma de Windows. Haz clic derecho en el ícono para:

- **Sound Tune Key**, arriba de todo con el ícono de la aplicación: abre **Acerca de**: versión, autor, el enlace de GitHub y un botón para buscar actualizaciones
- Justo debajo, como en Spotify: la **barra de tiempo**, los botones **⏮ ⏯ ⏭** y el **volumen** de la aplicación seleccionada; el menú se queda abierto para poder hacer clic más de una vez
- **Micrófono activado / desactivado**: activa o desactiva el micrófono; se pone en rojo cuando está desactivado
- **Abrir**: muestra la ventana de nuevo
- **Aplicaciones**: muestra la aplicación controlada ("Aplicaciones - Controlando: Spotify"). Haz clic en una aplicación para controlarla; su submenú tiene **Silenciar**, y las aplicaciones silenciadas aparecen en rojo. La lista se actualiza sola (cada 5 segundos mientras está abierta). Elegir y activar/desactivar no cierran el menú, para que puedas corregir una elección equivocada al instante
- **Atajos**: abre la ventanita con la lista de atajos
- **Iniciar con Windows**: abre el programa automáticamente, ya en la bandeja, cuando se enciende el PC
- **Mostrar aviso en pantalla**: activa o desactiva el aviso de volumen y silencio
- **Buscar actualizaciones...**: dice si hay una versión nueva; **Actualizar ahora** la descarga, reemplaza el programa y lo vuelve a abrir solo. La aplicación también busca una vez al día: cuando hay una versión nueva, muestra una notificación de Windows, un elemento **Actualizar a la versión…** arriba de este menú y una franja en la parte inferior de la ventana
- **Salir**: cierra el programa

### macOS

1. Haz clic en **macOS · Descargar .zip** arriba y abre el `.zip` para descomprimirlo.
2. Mueve `SoundTuneKey.app` a la carpeta **Aplicaciones** y ábrelo.
3. Selecciona en la lista la aplicación que quieres controlar. Las aplicaciones que están reproduciendo tienen un 🔈 junto al volumen. Las aplicaciones abiertas que aún no han reproducido sonido aparecen **en gris** al final de la lista: puedes elegirlas (los controles multimedia ya funcionan), y el volumen empieza a funcionar solo cuando la aplicación reproduzca. Las aplicaciones silenciosas se muestran con "(sin sonido aún)".
4. La primera vez que cambies un volumen, macOS pide el permiso de **Grabación de audio del sistema**: acéptalo. Así es como Sound Tune Key cambia el volumen de una sola aplicación.

El programa recuerda la última aplicación elegida y el volumen de cada aplicación. El volumen solo se aplica mientras Sound Tune Key esté abierto: al cerrarlo, todas las aplicaciones vuelven a su volumen normal hasta que lo abras de nuevo.

El punto **Iniciar con Mac**, en la parte inferior de la ventana, abre el programa automáticamente, ya en la barra de menús, cuando inicias sesión. Mueve la aplicación a **Aplicaciones** antes de activarlo.

Debajo de "Controlando", la ventana tiene la **barra de tiempo** de la canción (tiempo actual a la izquierda, duración a la derecha; arrastra para ir a otra parte), los botones **⏮ ⏯ ⏭** y la barra de volumen 🔈. Haz clic en el altavoz (o clic derecho en la aplicación, en la lista) para silenciarla: el nombre y el altavoz se ponen en rojo, y cambiar el volumen quita el silencio. ⏮ reinicia la canción actual; presiónalo dos veces en menos de 1 s para ir a la canción anterior. Los botones y la barra de tiempo funcionan con **Spotify**, **Música**, **VLC** y videos en **Google Chrome**: la primera vez, macOS pregunta si Sound Tune Key puede controlarlos; solo acéptalo. Con otras aplicaciones aparecen atenuados.

> ℹ️ **Chrome:** activa, una sola vez en cada perfil de Chrome, **Ver → Desarrollador → Permitir JavaScript de Apple Events** en la barra de menús del Mac, con Chrome al frente. Mientras no esté activado, Sound Tune Key muestra un aviso con el botón **Cómo activarlo**, que explica los pasos y trae Chrome al frente. El volumen de Chrome funciona incluso sin esto. En Chrome, ⏭ y el doble ⏮ cambian de video en YouTube.

#### ⚠️ Aviso de macOS la primera vez

La aplicación no está notarizada por Apple, así que la primera vez macOS dice que **no pudo verificar que la aplicación esté libre de software malicioso**. Para abrirla:

1. Mueve primero `SoundTuneKey.app` a la carpeta **Aplicaciones** (así no tendrás que permitirla de nuevo después de moverla).
2. Abre la aplicación. En el aviso, haz clic en **OK** / **Listo**, **no** en "Mover a la Papelera".
3. Ve a **Ajustes del Sistema → Privacidad y seguridad** y desplázate hasta **Seguridad**.
4. Junto al mensaje sobre "SoundTuneKey", haz clic en **Abrir igualmente** y confirma con tu contraseña o Touch ID.

El botón **Abrir igualmente** solo aparece justo después de intentar abrir la aplicación: si no está, abre la aplicación de nuevo y vuelve a los Ajustes. Solo hay que hacerlo la primera vez.

#### 🖥️ Barra de menús

Cerrar la ventana no cierra el programa: sigue en el ícono de la barra de menús (junto al Wi-Fi) y los atajos siguen funcionando. Para mover el ícono, mantén presionado **⌘** y arrástralo. El programa viene en portugués, inglés y español: elígelo en **Acerca de**. Haz clic en el ícono para:

- Arriba, como en Spotify: la **barra de tiempo**, los botones **⏮ ⏯ ⏭** y el **volumen** de la aplicación seleccionada; el menú se queda abierto para poder hacer clic más de una vez
- **Sound Tune Key** (arriba): abre **Acerca de**; cuando hay una versión nueva, aparece **Actualizar a la versión X**. En **Acerca de**, **Português · English · Español** cambia el idioma de toda la aplicación al instante
- **Micrófono activado / desactivado**: silencia y activa el micrófono (rojo cuando está desactivado)
- **Abrir**: muestra la ventana de nuevo
- **Aplicaciones**: muestra la aplicación controlada ("Aplicaciones - Controlando: Spotify"). Haz clic en una aplicación para controlarla (la marcada es la controlada); su submenú tiene **Silenciar**. Elegir y activar/desactivar no cierran el menú, para que puedas corregir una elección equivocada al instante; las aplicaciones silenciadas aparecen en rojo, y el ícono de la barra de menús se pone rojo mientras la aplicación elegida está silenciada
- **Atajos**: abre la ventanita con la lista de atajos
- **Iniciar con Mac**: abre el programa automáticamente, ya en la barra de menús, cuando inicias sesión
- **Mostrar aviso en pantalla**: activa o desactiva el aviso de volumen y silencio
- **Buscar actualizaciones...**: busca una versión nueva; **Actualizar ahora** la descarga, reemplaza la aplicación y la abre de nuevo
- **Salir**: cierra el programa

El programa también busca una versión nueva por sí solo (al abrir y una vez al día) y te avisa con una notificación, el elemento del menú ("Versión X disponible · Actualizar") y una franja en la ventana.

Para compilarlo desde el código fuente, ejecuta `mac/build-app.sh` (necesita las herramientas de línea de comandos de Xcode: `xcode-select --install`).

---

## 🛠️ Tecnologías

### Windows

- **C# / .NET**: aplicación nativa para Windows
- **Windows Core Audio (WASAPI)**: control de volumen por aplicación
- **Windows Media Controls (SMTC)**: reproducir/pausar, siguiente, anterior y la barra de tiempo de la canción
- **Win32 `RegisterHotKey`**: atajos globales de teclado

### macOS

- **Swift / SwiftUI**: aplicación nativa para Mac
- **Core Audio process taps**: control de volumen por aplicación
- **AppleScript**: reproducir/pausar, siguiente, anterior y la barra de tiempo en Spotify, Música y VLC, y en los videos de Chrome mediante JavaScript
- **Carbon `RegisterEventHotKey`**: atajos globales de teclado
