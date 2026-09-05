# Словопад — интеграция Yandex Games SDK

Дата проверки документации: 2026-09-05.

Ветка интеграции: `feat/yandex-games-sdk`.

## Зачем отдельная ветка

Дизайнер продолжает работу в `main`, поэтому SDK, cloud saves, реклама и Web-обвязка разрабатываются отдельно. После завершения UI-пака нужно подтянуть актуальный `main` в эту ветку, разрешить конфликты UI и только после Web-теста объединять изменения.

## Официальная документация

- SDK / подключение: https://yandex.com/dev/games/doc/en/sdk/sdk-about
- Game Ready и Gameplay API: https://yandex.com/dev/games/doc/en/sdk/sdk-game-events
- События pause/resume: https://yandex.com/dev/games/doc/en/sdk/sdk-events
- Environment / i18n: https://yandex.com/dev/games/doc/en/sdk/sdk-environment
- Требование 2.14, автоопределение языка: https://yandex.com/dev/games/doc/en/requirements/2/14
- Player Data: https://yandex.com/dev/games/doc/en/sdk/sdk-player
- Реклама: https://yandex.com/dev/games/doc/en/sdk/sdk-adv
- Размещение рекламы: https://yandex.com/dev/games/doc/en/requirements/4/4
- Review: https://yandex.com/dev/games/doc/en/sdk/sdk-review
- Shortcut: https://yandex.com/dev/games/doc/en/sdk/sdk-shortcut
- Server Time: https://yandex.com/dev/games/doc/en/sdk/sdk-server-time
- Общие требования: https://yandex.com/dev/games/doc/en/concepts/requirements
- Требования к архиву: https://yandex.com/dev/games/doc/en/console/add-new-game/draft

---

# 1. Язык: даже при одном русском i18n обязателен

Да. Yandex требует автоматическое определение языка через SDK **для всех игр**, даже если в карточке игры объявлен только один язык или в игре вообще нет текста.

При запуске обязательно читается:

```js
ysdk.environment.i18n.lang
```

В `yandex_games_service.gd` это выполняется сразу после `YaGames.init()`.

Сейчас игра поддерживает только:

```text
ru
```

Логика:

```text
Yandex lang = ru -> effective language = ru
Yandex lang = en/tr/… -> effective language = ru
```

То есть язык платформы реально определяется SDK, после чего выбирается доступная локализация игры. Когда появятся новые переводы, достаточно расширить `supportedLanguages` и Godot translations.

На debug panel индикатор `文` должен стать зелёным и показать `I18N is used` уже при запуске.

---

# 2. Подключение SDK

Для архива на серверах Yandex официальный рекомендуемый путь:

```text
/sdk.js
```

Интеграция сначала пытается загрузить именно его.

Для локальной разработки / собственного домена предусмотрен fallback:

```text
https://sdk.games.s3.yandex.net/sdk.js
```

После загрузки выполняется:

```js
const ysdk = await YaGames.init();
```

Если SDK недоступен, игра должна продолжить работать в local fallback без platform API.

---

# 3. Game Ready

`LoadingAPI.ready()` вызывается только после того, как:

1. SDK инициализирован или закончился fallback;
2. cloud save получен;
3. локальный прогресс загружен;
4. главное меню создано и игрок уже может взаимодействовать с игрой.

После этого:

```js
ysdk.features.LoadingAPI.ready();
```

Нельзя отправлять Game Ready сразу после загрузки JS, пока UI ещё не готов.

---

# 4. Gameplay markup

Используются:

```js
ysdk.features.GameplayAPI.start();
ysdk.features.GameplayAPI.stop();
```

`start()`:

- старт уровня;
- restart уровня;
- возврат из паузы;
- продолжение после рекламы, если gameplay действительно продолжается.

`stop()`:

- главное меню;
- карта мира;
- карта уровней;
- пауза;
- настройки поверх gameplay;
- victory / defeat;
- сюжетный comic transition;
- finale;
- перед показом рекламы.

Это должно быть видно в debug panel через индикатор 🎮.

---

# 5. Pause / Resume платформы

Подписка:

```js
ysdk.on('game_api_pause', ...)
ysdk.on('game_api_resume', ...)
```

Платформа использует эти события при:

- стартовой рекламе;
- fullscreen / rewarded рекламе;
- смене вкладки;
- сворачивании окна;
- некоторых platform dialogs.

На `pause`:

- gameplay ставится на паузу, если он был активен;
- музыка приложения приостанавливается;
- dirty cloud save отправляется с `flush=true`.

На `resume`:

- звук возвращается;
- gameplay автоматически продолжается только если до platform pause он действительно шёл и пользователь сам не открывал паузу / меню.

Это отдельно дополняет уже существующую Godot focus pause.

---

# 6. Cloud Save

Используется `Player`:

```js
const player = await ysdk.getPlayer();
await player.getData(['slovopad_save']);
await player.setData({ slovopad_save: payload }, flush);
```

Авторизация не требуется для запуска игры. Игра остаётся полностью доступной гостю.

Облачное сохранение содержит:

```text
schema
revision
saved_at
config
```

`config` — сериализованное состояние текущего `ConfigFile`:

- прогресс 60 уровней;
- открытые переходы;
- финал;
- best score / best time;
- настройки музыки и SFX;
- last location / last level;
- story flags.

## Local-first

Основным быстрым сохранением остаётся:

```text
user://word_bricks_settings.cfg
```

Cloud используется для восстановления и синхронизации между устройствами.

Синхронизация не выполняется на каждый тик / игровое действие.

Используется debounce:

```text
2 секунды
```

При уходе приложения в platform pause dirty save отправляется сразу.

Лимит Yandex `player.setData()` — до 200 KB на player data и не более 100 запросов за 5 минут. Текущий save значительно меньше лимита.

---

# 7. Авторизация

Автоматически открывать auth dialog запрещено.

Подготовлен метод:

```gdscript
request_yandex_auth()
```

Но вызывать его можно только после явного действия пользователя на понятной кнопке, например:

```text
Войти в Яндекс
Сохранять прогресс между устройствами
```

Гость всегда должен иметь возможность играть дальше.

---

# 8. Fullscreen ads

Fullscreen ad вызывается только после явного нажатия игроком на кнопку продолжения после завершённого уровня.

Схема:

```text
Уровень завершён
-> modal victory
-> игрок нажимает «Следующий уровень»
-> GameplayAPI.stop
-> showFullscreenAdv
-> onClose
-> запускается следующий уровень / comic transition
```

Реклама не вызывается посреди активной партии.

Yandex сам регулирует реальную частоту показа, поэтому игру можно вызывать на логических паузах, а SDK может вернуть `wasShown=false`.

---

# 9. Rewarded ads

SDK-обвязка готова:

```gdscript
request_rewarded_hint()
```

Reward tag:

```text
hint
```

После `onRewarded` игрок получает:

```text
+1 подсказку
```

Но **кнопка rewarded пока намеренно не добавлена**. После UI-пака нужно сделать явную формулировку, например:

```text
Смотреть рекламу
+1 подсказка
```

Rewarded должен быть полностью добровольным и не блокировать прохождение без рекламы.

---

# 10. Review и Shortcut

Подготовлены wrappers:

```gdscript
request_yandex_review()
request_yandex_shortcut()
```

Review сначала проверяет:

```js
ysdk.feedback.canReview()
```

Shortcut сначала проверяет:

```js
ysdk.shortcut.canShowPrompt()
```

Автоматически эти окна пока не вызываются. Рекомендуемая точка для review — после заметного прогресса, например после первой полностью восстановленной локации, но решение нужно принять отдельно.

---

# 11. Server Time

Используется:

```js
ysdk.serverTime()
```

Сейчас timestamp записывается в cloud payload как `saved_at`.

Это оставляет нормальную основу для будущих daily rewards / событий без доверия системным часам игрока.

---

# 12. Browser guards

В Web автоматически:

- отключается системный context menu на canvas;
- блокируется browser page scrolling;
- включается `overscroll-behavior: none`;
- canvas получает `touch-action: none`;
- canvas нельзя drag-and-drop выделять как HTML-элемент.

Это особенно важно для «Словопада», потому что правая кнопка мыши используется как игровое управление и браузерное контекстное меню не должно появляться.

---

# 13. Web export

Добавлен:

```text
godot/export_presets.cfg
```

Preset:

```text
Web
```

Ожидаемый результат:

```text
build/web/index.html
```

Перед Yandex upload содержимое `build/web/` нужно положить **в корень ZIP**, чтобы `index.html` находился непосредственно в корне архива.

---

# 14. Размер архива — критическая проверка

Yandex требует:

```text
не более 100 MB в распакованном виде
```

В проекте много 1920×1080 PNG comic/background assets. После получения нового UI-пака размер нужно обязательно пересчитать.

Если Web build превышает 100 MB:

- gameplay backgrounds -> WebP, где качество приемлемо;
- comic frames -> WebP с визуальной проверкой текста;
- убрать неиспользуемые исходники из export;
- проверить дубликаты;
- не экспортировать docs / generation sources, если они попадают в build.

Нельзя ориентироваться на размер ZIP: модерация проверяет распакованный объём.

---

# 15. Что намеренно не интегрировано

Пока игре не нужны:

- Payments;
- Leaderboards;
- Multiplayer;
- Remote Config;
- sticky banners.

Неиспользуемые SDK-функции не надо добавлять просто «для галочки».

---

# 16. Файлы интеграции

```text
godot/scripts/yandex_games_service.gd
godot/scripts/app_runtime_yandex.gd
godot/export_presets.cfg
godot/project.godot
godot/main.tscn
```

Platform service подключён через Autoload:

```text
YandexGames
```

Core gameplay напрямую от SDK не зависит.
