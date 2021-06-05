## Sobre Competitive Maker

Competitive Maker es un modo competitivo para el juego Counter-Strike 1.6 que incluye las últimas características al estilo CS:GO. Facilitamos las tareas más habituales que se suelen utilizar en cualquier partida competitiva, como por ejemplo:

- Modo auto mix o modo manual
- Quitar o cambiar la contraseña de servidor
- Prender o apagar AMXX  
- Intercambiar equipos
- Transferirse a espectador
- Resultado del cerrado y datos de conexión en chat global
- Modo de desempate
- Corte de equipos
- Modo práctica
- Mostrar equipamiento en tiempo de enfriamiento
- Pantalla negra a los espectadores
- Resultado del cerrado en el nombre del servidor
- Público automático por abandonar la partida
- Pausar la ronda
- Posibilidad de rendirse
- Espectadores activos
- Control de entrada a los equipos
- Teletransportación a zona de corte
- Frags y muertes al cambiar de lado
- Traspaso de equipos automático
- Bloquear cambio de nick y uso del chat global
- Información del jugador al espectear

### Pre requisitos 📋
```
AMX Mod X >= 1.8.3
```

¡Compatible con ReHLDS! 

### Installation 🔧

1. Clone el repositorio en su máquina local o servidor

```
# git clone https://github.com/stefanofabi/srlab.git
```

2. Cree una copia del archivo .env.example y cámbiele el nombre a .env. En su interior editaremos las variables de entorno para establecer la conexión a la base de datos

```
# cd srlab
# cp .env.example .env
# vim .env
```

3. Proceda a instalar las dependencias requeridas para el proyecto y generar los archivos javascript y estilos

```
# composer install
# npm install
# npm run dev
```
4. Cree un enlace a la carpeta de almacenamiento que contiene todo lo relacionado con la aplicación y cree la clave de la aplicación que protegerá las sesiones de los usuarios y otros datos.

```
# php artisan storage:link
# php artisan key:generate
```

5. Finalmente ejecute las migraciones y semillas.

```
# php artisan migrate
# php artisan db:seed
```

6. La ejecución de las semillas le permitirá iniciar sesión con algunos usuarios de prueba.
```
- Administrator 
Email: admin@community
Password: password
```

¡Recuerde modificar las contraseñas en producción!


## Contribuyendo

¡Gracias por considerar contribuir con el complemento Competitive Maker! Podés hacerlo en: 
- [MercadoPago](https://www.mercadopago.com.ar/subscriptions/checkout?preapproval_plan_id=2c93808479896d7201798d47849b0243)
- [PayPal](https://paypal.me/4evergaming)
- [Bitcoin](https://www.blockchain.com/btc/address/1BxrkKPuLTkYUAeMrxzLEKvr5MGFu3NLpU)

## Hosting
¿Estas considerando alquilar un servidor de Counter-Strike 1.6? No dudes en visitar la página de nuestro principal patrocinador [4evergaming](https://4evergaming.com.ar)
