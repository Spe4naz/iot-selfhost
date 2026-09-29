# IoT MODULAR SYSTEM — SELF-HOST

Готовый к запуску стек для самостоятельного хостинга IoT Modular System:
сигнальный сервер (реестр устройств) + MQTT + защищённый веб с HTTPS от
Let's Encrypt + раздача прошивок по OTA.

## Что внутри

| Сервис | Контейнер | Назначение |
|---|---|---|
| `server` | `./server` | REST API (братируется из `Spe4naz/iot-signaling-server`) |
| `mqtt` | mosquitto | 1883 (TCP) + 9001 (WebSockets), пароли/ACL |
| `web` | nginx | SPA/приложение, OTA (`/fw`), прокси `* -> /api/v1`, 80/443 |
| `certbot` | certbot/certbot | Автосертификат Let's Encrypt (`--profile certbot`) |

Данные — в томах `data/` (реестр, алерты, правила, метрики, журнал стабильности,
настройки) и в каталоге `/mosquitto` внутри контейнеров; сертификаты — в томе
`letsencrypt`.

## Веб-панель (/panel)

Сервер поставляется с админ-панелью в стиле 3X-UI: дашборд с графиками
CPU/MEM/load/латентности/онлайна, карточки устройств с аптаймом, CRUD
устройств/алертов/правил, настройки сервера (stale, rate-limits, глубина
метрик, API-токен, пароль панели) и перезапуск.

```bash
open https://ВАШ_ДОМЕН/panel
```

Вход — единый пароль. Обязательная переменная:

| Переменная | Описание |
|---|---|
| `PANEL_PASSWORD` | Пароль панели. **Пусто = панель отключена (503).** |

Всё остальное настраивается внутри панели и перезаписывает переменные среды
(файл `data/settings.json` приоритетнее env). При первом заходе задайте пароль в
`.env` (или через `install.sh`) и пересоберите: `docker compose up -d --build`.

## Быстрая установка на свежий сервер

```bash
sudo apt-get update
sudo apt-get install -y git curl
git clone https://github.com/Spe4naz/iot-selfhost.git
cd iot-selfhost
sudo bash install.sh
```

`install.sh` сам: установит Docker + compose plugin, спросит домен/token/пароли
(или сгенерирует их), напишет `.env`, откроет порты **80, 443, 1883, 9001**
(если найден активный ufw/firewalld), поднимет стек и подождёт health.

Требования: Ubuntu/Debian/Fedora (x86_64 или arm64), root, публичный IP и
заранее созданная **DNS A-запись** домена → IP сервера, если нужен HTTPS.

## Ручной запуск

```bash
cp .env.example .env     # заполнить значения
# HTTP (LAN / быстрый старт):
docker compose up -d --build
# HTTPS (Let's Encrypt):
docker compose --profile certbot up -d --build
```

При `NGINX_TLS=1`: certbot-контейнер крутится фоном (certonly --webroot + renew
каждые 12 часов), nginx автоматически включает HTTPS-конфиг, как только выпущен
первый сертификат. Если DNS ещё не указывает на сервер — выпуск будет повторяться
автоматически, ничего делать не надо.

## Настройка приложения и устройств

После установки приложение (и прошивки ESP32) настраиваются так:

- **API URL** в приложении: `https://ВАШ_ДОМЕН/api/v1`
- **Токен записи (API)**: значение `REGISTER_TOKEN` из `.env`
- **MQTT в приложении**: server = `ВАШ_ДОМЕН`, порт, `MQTT_USER` / `MQTT_PASSWORD` из `.env`
- **OTA URL (прошивки)** в приложении: `https://ВАШ_ДОМЕН/fw`
- **Прошивка ESP32** (`config.h`): `SERVER_URL`, `mqtt_user`/`mqtt_password`
  = `MQTT_DEVICE_USER` / `MQTT_DEVICE_PASSWORD`

Файлы для OTA кладутся в `site/fw/`. Имя файла должно совпадать со значением
`OTA_FIRMWARE` в прошивке (например `firmware_esp32_v1.2.0.bin`) — версия не ниже
текущей на устройстве, иначе устройство откатит обновление.

## Переменные окружения (`env`)

| Переменная | Обязательно | Описание |
|---|---|---|
| `NGINX_DOMAIN` | да | FQDN сервера (A-запись → сервер) |
| `REGISTER_TOKEN` | да | Токен записи API (устройства + приложение) |
| `MQTT_USER` / `MQTT_PASSWORD` | да | Учётка MQTT приложения |
| `MQTT_DEVICE_USER` / `MQTT_DEVICE_PASSWORD` | да | Общая учётка MQTT всех устройств (в прошивке) |
| `NGINX_TLS` | нет | `0` = только HTTP, `1` = HTTPS + Let's Encrypt |
| `CERTBOT_EMAIL` | при TLS=1 | Email уведомлений Let's Encrypt |
| `PORT`, `STALE_MS`, `MAX_DEVICES_PER_IP`, `RATE_LIMIT_*` | нет | Тюнинг сервера |
| `METRICS_HOURS`, `METRICS_INTERVAL_MS`, `METRICS_FLUSH_SECONDS` | нет | История метрик панели |
| `PANEL_PASSWORD` | нет | Пароль веб-панели (`/panel`); пусто = панель выключена |
| `PANEL_SESSION_TTL_MS` | нет | TTL сессии панели (по умолч. 24 ч) |

## Полезные команды

```bash
docker compose ps                 # статус
docker compose logs -f            # логи всех сервисов
docker compose logs -f web        # логи nginx (запросы на /api/* и /fw/*)
docker compose down               # остановить (данные сохраняются)
docker compose up -d --build      # пересоздать после правок .env / кода
```

Бэкап: сохранить том `iot-data` (каталог `data/` внутри контейнера `server`) —
это JSON-файлы реестра, алертов, правил, метрик, журнала стабильности и настроек
панели.

## Источники

- Сервер: <https://github.com/Spe4naz/iot-signaling-server> (в `./server` — снимок кода)
- Приложение/прошивки: исходники в монорепозитории проекта (закрыто)