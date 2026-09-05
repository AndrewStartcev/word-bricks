# Статус интеграции gameplay-пака

Дата: 2026-09-05

## Подключено

Главная сцена `godot/main.tscn` теперь использует `res://scripts/game.gd`.

### Графика

Подключены production-файлы из `res://assets/`:

- `backgrounds/background_forest.png` — фон главы;
- `tiles/tile_normal_blue.png` — обычная игровая плитка;
- `tiles/tile_goal_gold.png` — нужная буква;
- все 5 состояний совы;
- SVG HUD: settings, pause, score, combo, time, hint, check, lock, chapter, clue, music/sound;
- FX sprites: spark, shard, leaf.

Буквы и UI-текст по-прежнему рисуются кодом. Glow не запечён в ассеты.

### Gameplay / UX

- глава 1: 5 слов, по 2–3 добываемые буквы вместо одной;
- золотая плитка обозначает только актуальную нужную букву;
- мышь перемещает активную фигуру по X;
- ЛКМ над полем — hard drop;
- ПКМ над полем — поворот;
- клавиатура сохранена как альтернативное управление;
- движение фигуры визуально сглаживается;
- добавлены ghost, hard-drop trail, lock burst, line flash, particles;
- нужная буква перелетает из очищенной линии в слот слова;
- добавлены реакции совы idle / hint / happy / worried / defeat.

### Audio

Создан `res://scripts/audio_service.gd`.

Подключены события:

- `piece_move`;
- `piece_rotate`;
- `piece_lock`;
- `line_clear`;
- `word_complete`;
- `chapter_complete`;
- `hint`;
- `invalid`;
- `defeat`;
- UI click/back.

Используется пул из 8 `AudioStreamPlayer` для SFX и отдельный player для музыки. Gain/cooldown соответствуют `audio_manifest.json`.

Создаются шины `Music` и `SFX`. Пользовательские громкости применяются на шинах, event gain — на player.

Музыка не стартует до первого реального ввода пользователя, что важно для Web.

### Пауза / настройки

- `P` / `Esc` и кнопка pause останавливают gameplay и приостанавливают музыку;
- потеря фокуса переводит игру в паузу;
- settings открывается по шестерёнке и также приостанавливает gameplay;
- в settings можно независимо включать/выключать Music/SFX;
- громкость Music/SFX регулируется с шагом 10%;
- настройки пока живут только в текущей сессии и позже должны попасть в SaveService.

## Что проверить в Godot

1. Импорт PNG/SVG/WAV/OGG без ошибок.
2. Парсинг `scripts/game.gd` и `scripts/audio_service.gd`.
3. Первый ввод запускает музыку, до ввода музыка молчит.
4. Мышь: позиция → ЛКМ hard drop → ПКМ rotate.
5. Нужная буква действительно собирается только через очищенную линию.
6. Один hard drop не создаёт серию `piece_move` SFX.
7. Music/SFX mute и +/- работают независимо.
8. `P`, Esc, settings и loss of focus не запускают отложенные gameplay-действия.
9. Проверить 1280×720, 1600×900 и 1920×1080.

## Следующий шаг после запуска

После первого живого прогона фиксируем только реальные проблемы: parser/runtime, размеры ассетов, баланс 1–2 минут, громкость микса, плотность FX и положение UI. До этого не расширяем механику новыми бонусными плитками.
