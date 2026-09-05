# Словопад — состояние полной кампании

## Контент

Кампания рассчитана на 6 локаций × 10 уровней × 5 слов = 60 уровней / 300 слов.

Порядок:

1. Лес
2. Деревня
3. Море
4. Город
5. Сказки
6. Башня
7. Финальный комикс

`res://scripts/level_catalog.gd` содержит данные всех 60 уровней.

## Runtime

- `res://scripts/game_world.gd` подключает production-фоны и chapter icons всех шести локаций.
- `res://scripts/app_runtime_full.gd` управляет полной прогрессией, картой мира, картами 10 уровней, переходными комиксами и финалом.
- `res://scenes/gameplay.tscn` запускает `game_world.gd`.
- `res://main.tscn` запускает `app_runtime_full.gd`.

## Переходы

После 10/10 предыдущей локации показывается одна comic-page из трёх кадров:

- Лес → Деревня: `assets/comics/village_unlock/`
- Деревня → Море: `assets/comics/sea_unlock/`
- Море → Город: `assets/comics/city_unlock/`
- Город → Сказки: `assets/comics/fairytales_unlock/`
- Сказки → Башня: `assets/comics/tower_unlock/`

После Башни 10/10 показывается финальный комикс `assets/comics/finale/` в двух страницах по два кадра.

## Сохранения

Полный прогресс хранится в `user://word_bricks_settings.cfg`:

- `campaign/<location>_completed` — 0..10;
- `story/<location>_transition_seen`;
- `story/finale_seen`;
- `campaign/last_location`;
- `campaign/last_level`.

Старые Forest/Village поля продолжают синхронизироваться для совместимости предыдущих runtime-слоёв.

## Что проверить в Godot

Среда разработки ChatGPT не содержит исполняемого Godot, поэтому обязательна локальная runtime-проверка:

1. новый профиль: intro → Forest 1;
2. последовательное открытие Forest 1..10;
3. Forest 10 → village comic → Village map;
4. аналогично переходы Village → Sea → City → Fairytales → Tower;
5. фон, иконка, название и слова каждой локации;
6. Tower 10 → finale page 1 → page 2 → menu;
7. выход в меню и на карту из gameplay;
8. reset progress;
9. повторный запуск после сохранения между локациями;
10. старый save предыдущей версии.

## Отдельно перед релизом

Это не заменяет финальный UI polish, баланс времени прохождения, Web/Yandex SDK integration и полный QA Web-export.
