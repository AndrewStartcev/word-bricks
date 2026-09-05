# Словопад — Asset Plan

Версия: 0.1

Цель документа — отделить **то, что действительно нужно рисовать**, от того, что лучше собирать нативно в Godot.

Главное правило: UI не собирается одним PNG. Все игровые элементы должны оставаться независимыми и программно управляемыми.

---

## 1. Что НЕ нужно рисовать отдельными растрами

Следующие элементы лучше делать через Godot `StyleBoxFlat`, `Panel`, `Label`, `TextureRect`, shader и particles:

- тёмные UI-панели;
- рамки;
- простые разделители;
- полосы прогресса;
- текст;
- цифры score/combo/time;
- сетка игрового поля;
- glow вокруг нужной буквы;
- частицы;
- подсветка линии;
- ghost-позиция фигуры.

Так мы не привязываем интерфейс к одному разрешению и не запекаем текст в изображения.

---

## 2. Утверждённый gameplay reference

Файл должен храниться в:

`docs/references/gameplay-approved.png`

Это главный референс по:

- композиции 16:9;
- ночной атмосфере;
- плотности UI;
- небольшому радиусу панелей;
- цвету блоков;
- глубине и свечению;
- фону главы «Лес»;
- сове-маскоту.

Важно: gameplay-экран **без логотипа**.

---

## 3. Priority A — ассеты, необходимые для production-визуала первого экрана

| ID | Файл | Формат | Размер | Назначение |
|---|---|---|---|---|
| A01 | `background_forest.webp` | WebP | 1920×1080 | Фон главы «Лес», без UI и текста |
| A02 | `owl_idle.webp` | WebP alpha | ~512×512 canvas | Сова в idle-позе |
| A03 | `owl_hint.webp` | WebP alpha | ~512×512 | Сова показывает подсказку |
| A04 | `owl_happy.webp` | WebP alpha | ~512×512 | Реакция на завершение слова |
| A05 | `owl_worried.webp` | WebP alpha | ~512×512 | Поле близко к заполнению |
| A06 | `owl_defeat.webp` | WebP alpha | ~512×512 | Game over |
| A07 | `tile_normal.webp` | WebP alpha | 128×128 | Синяя объёмная клетка без буквы |
| A08 | `tile_goal.webp` | WebP alpha | 128×128 | Золотая клетка нужной буквы |
| A09 | `tile_bonus.webp` | WebP alpha | 128×128 | Зелёная special-клетка, резерв |
| A10 | `tile_danger.webp` | WebP alpha | 128×128 | Красная special-клетка, резерв |
| A11 | `tile_special.webp` | WebP alpha | 128×128 | Фиолетовая special-клетка, резерв |

### Требования к tile-ассетам

- без букв;
- одинаковый размер и внутренние отступы;
- одинаковая перспектива;
- мягкий объём;
- читаемость на размере 36–64 px;
- прозрачный фон;
- без внешнего glow большого радиуса — glow добавляется в Godot;
- буква рисуется нативным шрифтом поверх текстуры.

---

## 4. Priority B — SVG-иконки HUD

Все иконки отдельными SVG, без текста.

Рекомендуемый каталог:

`godot/assets/ui/icons/`

Нужны:

- `icon_settings.svg`
- `icon_pause.svg`
- `icon_score.svg` — корона;
- `icon_combo.svg` — молния;
- `icon_time.svg` — секундомер;
- `icon_hint.svg` — лампа;
- `icon_check.svg`
- `icon_lock.svg`
- `icon_sound_on.svg`
- `icon_sound_off.svg`
- `icon_music_on.svg`
- `icon_music_off.svg`
- `icon_restart.svg`
- `icon_home.svg`

Стиль:

- простой casual-game;
- белая/светлая базовая форма;
- допустим небольшой внутренний градиент;
- без baked shadow вокруг всей кнопки;
- кнопочные контейнеры создаются в Godot.

---

## 5. Priority C — chapter icons

Отдельные изображения/иконки для тем.

Первый набор:

- `chapter_forest.webp`
- `chapter_sea.webp`
- `chapter_city.webp`
- `chapter_animals.webp`
- `chapter_food.webp`
- `chapter_space.webp`
- `chapter_fairytale.webp`

Размер: 256×256, transparent WebP.

В prototype нужен только `chapter_forest`.

---

## 6. Priority D — backgrounds будущих глав

После подтверждения core loop:

- `background_sea.webp`
- `background_city.webp`
- `background_animals.webp`
- `background_food.webp`
- `background_space.webp`
- `background_fairytale.webp`

Каждый фон:

- 1920×1080;
- без UI;
- без текста;
- центральная зона должна позволять размещение поля;
- детали преимущественно по краям;
- контраст непосредственно за UI ниже, чем по краям;
- одна художественная стилистика со сценой «Лес».

---

## 7. Шрифт

Требования:

- кириллица;
- высокая читаемость на блоках;
- casual, но не детский comic;
- лицензия, разрешающая распространение с игрой.

Первый кандидат: **Rubik**.

Использование:

- Regular/Medium — secondary text;
- SemiBold — HUD;
- Bold — буквы на блоках и активное слово.

До подключения финального font-файла prototype использует fallback font Godot.

---

## 8. VFX, которые НЕ требуют отдельных картинок

Реализуем в Godot:

- glow нужной буквы;
- pulse нужного слота;
- trail перелетающей буквы;
- вспышка очищенной линии;
- stars/sparks при завершении слова;
- лёгкий screen shake при hard drop;
- pop-анимация слова;
- подсветка combo;
- затемнение background за gameplay UI.

При необходимости позже можно добавить маленький sprite atlas частиц, но в первом production-pass это не обязательно.

---

## 9. Audio assets

Каталог:

`godot/assets/audio/`

### SFX

- `move.ogg`
- `rotate.ogg`
- `soft_drop.ogg`
- `hard_drop.ogg`
- `lock.ogg`
- `line_clear.ogg`
- `goal_letter.ogg`
- `slot_fill.ogg`
- `word_complete.ogg`
- `combo_up.ogg`
- `game_over.ogg`
- `ui_hover.ogg`
- `ui_click.ogg`

### Music

- `forest_theme.ogg`

Требования:

- loop-friendly;
- спокойный темп;
- без вокала;
- не маскирует короткие gameplay SFX.

---

## 10. Что рисуем первым

После gameplay prototype и подтверждения механики:

1. `background_forest.webp`;
2. `tile_normal.webp`;
3. `tile_goal.webp`;
4. `owl_idle.webp`;
5. `owl_hint.webp`;
6. `owl_happy.webp`;
7. основной набор SVG-иконок HUD.

Этого достаточно, чтобы собрать первый экран практически в согласованном качестве.

Остальные позы, главы и special tiles не должны тормозить проверку core loop.

---

## 11. Структура assets

```text
godot/assets/
├── backgrounds/
│   └── background_forest.webp
├── characters/
│   └── owl/
│       ├── owl_idle.webp
│       ├── owl_hint.webp
│       ├── owl_happy.webp
│       ├── owl_worried.webp
│       └── owl_defeat.webp
├── tiles/
│   ├── tile_normal.webp
│   ├── tile_goal.webp
│   ├── tile_bonus.webp
│   ├── tile_danger.webp
│   └── tile_special.webp
├── ui/
│   └── icons/
├── fonts/
└── audio/
    ├── sfx/
    └── music/
```

---

## 12. Критерий готовности ассета

Ассет принимается только если:

- он работает отдельно от остального UI;
- в нём нет запечённых надписей/цен/цифр;
- прозрачность корректная;
- размеры и naming соответствуют документу;
- элемент можно переиспользовать в разных состояниях;
- он читается при реальном размере внутри 1600×900 gameplay screen.
