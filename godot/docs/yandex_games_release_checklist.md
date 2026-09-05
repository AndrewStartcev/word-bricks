# Словопад — чеклист публикации в Яндекс Играх

Дата: 2026-09-05

Ветка SDK: `feat/yandex-games-sdk`

Легенда:

- `[x]` — реализовано в коде ветки;
- `[ ]` — нужно проверить или сделать перед merge/release;
- `[UI]` — зависит от нового дизайнерского UI-пака.

---

## A. SDK и запуск

- [x] Yandex Games SDK подключается при Web-запуске.
- [x] Для Yandex archive сначала используется `/sdk.js`.
- [x] Для local/custom-domain есть fallback на `https://sdk.games.s3.yandex.net/sdk.js`.
- [x] `YaGames.init()` выполняется один раз.
- [x] При недоступном SDK игра не должна ломаться: native/local fallback остаётся рабочим.
- [ ] Проверить в Yandex debug panel: loader indicator = `IT`, не `W` и не `IF`.
- [ ] Проверить DevTools Console: нет uncaught errors.

---

## B. i18n / язык

- [x] `ysdk.environment.i18n.lang` читается во время запуска.
- [x] Это выполняется даже при единственном языке `ru`.
- [x] Текущий supported language set: `ru`.
- [x] Любой неподдерживаемый Yandex locale корректно падает в `ru`.
- [x] Godot получает effective locale через `TranslationServer.set_locale()`.
- [ ] В Draft объявить только русский язык, пока реальных переводов нет.
- [ ] В debug panel проверить зелёный индикатор `文` / `I18N is used`.
- [ ] Через SDK mocks переключить язык на `en` и убедиться, что игра остаётся корректной русскоязычной single-language версией без ошибок.

---

## C. Game Ready

- [x] `LoadingAPI.ready()` подключён.
- [x] Вызывается после SDK/cloud bootstrap и создания интерактивного меню.
- [ ] Проверить debug panel: Game Ready срабатывает один раз и в правильный момент.
- [ ] Проверить Performance DevTools: присутствует mark `Game Ready`.
- [UI] После получения loading assets встроить собственный loading screen до Game Ready.

---

## D. Gameplay API

- [x] `GameplayAPI.start()` вызывается при старте уровня.
- [x] `GameplayAPI.stop()` вызывается в меню.
- [x] Stop вызывается на карте мира.
- [x] Stop вызывается на карте уровней.
- [x] Stop вызывается на pause.
- [x] Stop вызывается на victory/defeat.
- [x] Stop вызывается на comic transitions/finale.
- [x] Stop вызывается перед рекламой.
- [x] Start возвращается при реальном resume gameplay.
- [ ] В debug panel проверить индикатор 🎮 на всех сценариях.
- [ ] Проверить: gameplay green только во время активной партии.

---

## E. Focus / Pause / Audio

- [x] Подписка на `game_api_pause`.
- [x] Подписка на `game_api_resume`.
- [x] На platform pause приложение глушит музыку.
- [x] Активный gameplay ставится на pause.
- [x] На resume не снимается пользовательская ручная пауза.
- [x] Существующий Godot focus pause остаётся дополнительным fallback.
- [ ] Проверить переключение вкладки.
- [ ] Проверить сворачивание браузера.
- [ ] Проверить стартовую рекламу Yandex.
- [ ] Проверить fullscreen ad.
- [ ] Проверить rewarded ad.
- [ ] Звук должен прекращаться максимум в течение 2 секунд после потери фокуса.

---

## F. Browser UI / управление

- [x] System context menu блокируется над canvas.
- [x] Правая кнопка мыши остаётся доступна игре для поворота фигур.
- [x] Page scrolling блокируется.
- [x] `overscroll-behavior` отключает swipe-to-refresh/overscroll.
- [x] Canvas получает `touch-action: none`.
- [ ] Проверить resize окна от небольшого до fullscreen.
- [ ] Ничего не должно обрезаться/накладываться.
- [ ] Проверить отсутствие вертикального/горизонтального browser scroll bar.

---

## G. Local + Cloud save

- [x] Local save остаётся `user://word_bricks_settings.cfg`.
- [x] Используется `ysdk.getPlayer()`.
- [x] Cloud load: `player.getData(['slovopad_save'])`.
- [x] Cloud save: `player.setData({slovopad_save: ...})`.
- [x] Save содержит progress/settings/story state.
- [x] Есть schema/revision.
- [x] Cloud может восстановить более свежий save до открытия меню.
- [x] Есть debounce 2 сек, нет запроса на каждое действие.
- [x] Dirty save flush-ится при platform pause.
- [x] Используется Yandex server time для `saved_at`.
- [ ] Проверить guest player save.
- [ ] Проверить авторизованный player save.
- [ ] Проверить переход на другом устройстве/браузере.
- [ ] Проверить reset progress -> cloud тоже получает новый reset state.
- [ ] Проверить лимит payload: значительно меньше 200 KB.
- [ ] Проверить конфликт старого local save и нового cloud save.

---

## H. Authorization

- [x] Игра запускается без авторизации.
- [x] SDK wrapper для `openAuthDialog()` подготовлен.
- [x] Авторизация не вызывается автоматически.
- [ ] Если добавляем кнопку входа: явно написать выгоду (`Сохранять прогресс между устройствами`).
- [ ] Должна быть возможность отказаться и продолжить играть.
- [ ] После появления UI авторизации проверить account-change/cloud reload сценарий.

---

## I. Fullscreen ads

- [x] `showFullscreenAdv()` интегрирован.
- [x] Реклама вызывается только после завершения уровня и нажатия кнопки продолжения.
- [x] Не вызывается во время активной партии.
- [x] Gameplay markup останавливается перед ad call.
- [x] После `onClose` продолжается следующий уровень / переход.
- [x] `wasShown=false` не блокирует продолжение.
- [ ] В Developer Console включить YAN monetization.
- [ ] Проверить debug ad mock.
- [ ] Проверить, что ad call начинается сразу после user action (до 0.33 сек).
- [ ] Проверить, что звук полностью выключен на время рекламы.

---

## J. Rewarded ads

- [x] `showRewardedVideo()` wrapper готов.
- [x] Reward tag `hint` готов.
- [x] `onRewarded` добавляет `+1` hint charge.
- [ ] [UI] Добавить добровольную кнопку `Смотреть рекламу — +1 подсказка`.
- [ ] [UI] Не маскировать рекламу под обычную подсказку.
- [ ] Игрок должен иметь возможность пройти игру без rewarded ads.
- [ ] Проверить onOpen/onRewarded/onClose/onError.

---

## K. Review / shortcut

- [x] `feedback.canReview()` + `requestReview()` wrapper подготовлен.
- [x] `shortcut.canShowPrompt()` + `showPrompt()` wrapper подготовлен.
- [ ] Решить, нужна ли кнопка/автопредложение review после первой полностью пройденной локации.
- [ ] Не запрашивать review чаще одного раза за session.
- [ ] Shortcut показывать только если `canShowPrompt()` разрешает.

---

## L. Monetization

- [x] В игре есть fullscreen ad integration, поэтому можно включать YAN.
- [x] Rewarded bridge также подготовлен.
- [ ] В Draft/Advertising реально включить monetization.
- [ ] Стартовая реклама платформы сама по себе НЕ считается достаточной монетизацией.
- [ ] Sticky banner пока не использовать без отдельного UX-решения.
- [ ] Third-party ads отсутствуют.

---

## M. Web export

- [x] Добавлен `godot/export_presets.cfg` / preset `Web`.
- [ ] На машине с Godot выполнить реальный Web export.
- [ ] Убедиться, что в `build/web/` появился `index.html`.
- [ ] ZIP создавать из **содержимого** `build/web/`, не из самой папки.
- [ ] В корне ZIP должен лежать ровно один `index.html`.
- [ ] В путях build нет кириллицы и пробелов.
- [ ] Проверить WebGL2 / Compatibility в Chrome, Yandex Browser, Firefox, Safari при заявлении поддержки.

---

## N. Размер build — очень важно

- [ ] Измерить **распакованный** `build/web/`.
- [ ] Итог <= 100 MB.
- [ ] После дизайнерского UI-пака повторить измерение.
- [ ] Если >100 MB: оптимизировать PNG/WebP и export filter.
- [ ] Не экспортировать ненужные docs/generation/reference-файлы.
- [ ] Проверить дубли больших comic/background assets.

---

## O. Loading/UI после дизайнерской поставки

- [ ] [UI] Подключить production логотип `Словопад`.
- [ ] [UI] Подключить loading background/decor.
- [ ] [UI] Подключить loading bar.
- [ ] [UI] Загрузка не должна показывать технический текст.
- [ ] [UI] `LoadingAPI.ready()` оставить только после полной готовности интерактивного меню.
- [ ] [UI] Подключить новые menu buttons/panels/world map/level map skins.
- [ ] [UI] После merge повторно проверить все Yandex lifecycle вызовы — визуальный рефактор не должен их потерять.

---

## P. Контент и модерация

- [ ] Игра выглядит завершённой, без debug-кнопок/F-cheat перед отправкой на moderation.
- [ ] Нет технических сообщений на экране.
- [ ] Нет пустых кнопок/заглушек.
- [ ] Нет битых изображений.
- [ ] Текст русский без орфографических ошибок.
- [ ] AI-generated статичные арты допустимы; интерактивный generative AI в игре не используется.
- [ ] Реальные gameplay screenshots занимают >=70% промо-скриншотов.

---

## Q. Yandex debug panel — финальный прогон

Открыть draft с `debug-mode=16` и проверить:

- [ ] SDK loader `IT`.
- [ ] `文` = `I18N is used`.
- [ ] Game Ready срабатывает корректно.
- [ ] 🎮 green в gameplay / red вне gameplay.
- [ ] ▶️/⏸️ platform pause/resume не ломает игру.
- [ ] Ads mock: fullscreen.
- [ ] Ads mock: rewarded.
- [ ] Cloud save / clear cloud data.
- [ ] После рекламы нет black screen / lost input.
- [ ] После tab switch нет звука.
- [ ] После resize интерфейс остаётся рабочим.

---

# Перед merge этой ветки в main

1. Дождаться UI-пака дизайнера в `main`.
2. Подтянуть свежий `main` в `feat/yandex-games-sdk`.
3. Перенести Yandex adapter поверх нового UI runtime.
4. Убедиться, что `main.tscn` стартует Yandex runtime.
5. Убедиться, что Autoload `YandexGames` сохранён.
6. Удалить любые временные preview/debug shortcuts.
7. Сделать Web export.
8. Прогнать Yandex debug panel.
9. Только после этого merge в `main`.
