# Статус интеграции gameplay-пака и UI shell

Дата: 2026-09-05

## Точка входа

Главная сцена `godot/main.tscn` теперь использует `res://scripts/app_runtime.gd`.

Gameplay вынесен в отдельную сцену:

- `res://scenes/gameplay.tscn`;
- `res://scripts/game.gd` — core gameplay;
- `res://scripts/game_presentation.gd` — presentation overrides поверх gameplay.

Это отделяет меню/модалки от игрового поля и позволяет дальше развивать интерфейс без разрастания одного `_draw()`.

## Добавлен UI flow

Реализованы отдельные экраны/состояния:

- главное меню;
- выбор уровней;
- gameplay;
- пауза;
- настройки;
- победа;
- поражение.

### Главное меню

- фон главы «Лес» используется как полноэкранный background;
- сова вынесена в отдельный заметный decorative/mascot layer;
- кнопки: `Играть`, `Уровни`, `Настройки`;
- показывается статус первого уровня.

### Выбор уровней

Подготовлена сетка на 6 глав:

1. Лес — доступен;
2. Море — locked;
3. Город — locked;
4. Еда — locked;
5. Космос — locked;
6. Сказки — locked.

Пока это UI-каркас: контент будущих глав не добавлен.

### Пауза

Новая пауза — реальная Control-модалка, а не текстовый overlay из gameplay renderer.

Кнопки:

- `Продолжить`;
- `Начать заново`;
- `Настройки`;
- `К уровням`;
- `В меню`.

### Победа

Показываются:

- happy-сова;
- собранные слова;
- очки;
- время;
- лучший combo;
- `К уровням`;
- `Играть ещё раз`;
- `В меню`.

### Поражение

Показываются:

- defeat-сова;
- фактически собранные слова;
- очки;
- время;
- лучший combo;
- `Начать заново`;
- `Играть ещё раз`;
- `В меню`.

### Настройки

- отдельный Music toggle;
- отдельный SFX toggle;
- отдельные sliders громкости Music/SFX;
- значения сохраняются в `user://word_bricks_settings.cfg`;
- туда же записывается факт прохождения первой главы, best score и best time.

## Gameplay presentation pass

`game_presentation.gd` убирает из gameplay технические overlays, потому что их теперь рисует `app_runtime.gd`.

Изменено:

- сова увеличена и заметнее встроена слева;
- удалены длинные tutorial-подсказки;
- удалена строка управления снизу;
- правая панель стала компактнее;
- подсказка сокращена до одной action-кнопки + charges;
- слева вместо длинного списка locked words используется компактный chapter progress;
- игровой HUD использует более мягкий системный font stack: Rubik → Nunito → Trebuchet MS → Verdana → Arial.

Важно: это временный font fallback. Для Web нужен встроенный production font-файл, см. `designer_request_ui_pass.md`.

## Графика

Подключены production-файлы из `res://assets/`:

- `backgrounds/background_forest.png`;
- `tiles/tile_normal_blue.png`;
- `tiles/tile_goal_gold.png`;
- 5 состояний совы;
- SVG HUD;
- FX sprites.

Буквы и UI-текст остаются динамическими. Glow и gameplay FX не запекаются в ассеты.

## Gameplay / UX

- глава 1: 5 слов, по 2–3 добываемые буквы;
- золотая плитка — текущая нужная буква;
- мышь перемещает активную фигуру по X;
- ЛКМ — hard drop;
- ПКМ — rotate;
- клавиатура сохранена;
- движение фигуры сглаживается;
- ghost, hard-drop trail, lock burst, line flash, particles;
- нужная буква перелетает из линии в слот слова;
- owl reactions: idle / hint / happy / worried / defeat.

## Audio

Используется `res://scripts/audio_service.gd`:

- Music + SFX buses;
- 8-player SFX pool;
- per-event gain/cooldown из `audio_manifest.json`;
- Web audio unlock после пользовательского ввода;
- pause/settings/focus suspend;
- Music/SFX mute и volume независимо.

## Что проверить в Godot после `git pull`

1. Parser: `app_runtime.gd`, `game_presentation.gd`, `game.gd`, `audio_service.gd`.
2. Старт игры должен открывать главное меню, а не сразу gameplay.
3. Menu → Levels → Лес → Gameplay.
4. Esc/P и HUD pause открывают новую Control-модалку.
5. Settings из меню и из паузы.
6. Победа/поражение не показывают старый технический overlay из `game.gd`.
7. Мышь по полю не должна блокироваться UI shell.
8. Music/SFX сохраняются после перезапуска.
9. Проверить UI на 1280×720, 1600×900 и 1920×1080.
10. Отдельно оценить: размер совы, плотность FX, читаемость плиток и ощущение от нового меню.

## Следующий этап

После живого скрина/прогона правим только фактические проблемы композиции и game feel. Новые ассеты заказываются только когда становится ясно, что текущего production pack недостаточно.
