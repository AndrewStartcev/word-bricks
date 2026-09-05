# Заметки дизайнера — версия 2.0

Дата: 2026-09-05. Комплект уточнён по двум концептам «Ночная лесная головоломка: Глава 1» и «Словопад: ночная лесная головоломка». Концепты использованы как референсы; готовые UI-фрагменты из них не вырезались. Референсные PNG в репозиторий не добавлены.

## Что изменено

| Элемент | Решение по концептам |
|---|---|
| Фон | Перерисован: более насыщенные синие тона, упрощённая сказочная живопись, домик справа, причал и фонарь внизу справа, камень и фонарь слева для совы |
| Плитки | Скругление уменьшено 45→31 px, цвета насыщеннее, фаска компактнее, светлая кромка преимущественно сверху/слева |
| Основные 14 иконок | Проверены, оставлены: формы соответствуют символам концепта, свечение добавляет движок |
| Монета | Добавлены icon_coin.svg для HUD и coin_gold.png для полёта награды, без цифр и валютных букв |
| Лес / подсказка | Добавлены icon_chapter_forest.svg, icon_clue_paw.svg и дополнительный icon_leaf.svg |
| FX | Добавлены 4 белые текстуры частиц: dot, spark, shard, leaf; оттенок, прозрачность и движение задаёт код |
| Сова | Пять существующих поз сохранены: соответствуют тёплой лесной палитре, масштаб/опора уже согласованы |
| Аудио | 1 CC0 музыка и 12 CC0 SFX; условия и источники в audio_sources.md |

## Геометрия и безопасные зоны

Фон: один непрозрачный PNG 1920×1080. Новый генераторный исходник 1672×940 приведён к целевому размеру небольшим апскейлом. Центр спокойнее периферии, но горы/озеро остаются видны — контраст поля обеспечивается отдельной подложкой Godot. На фоне есть нарисованный локальный свет фонарей/луны, а не игровые ореолы. Фон показывать целиком в 16:9; свободный crop сдвигает место для совы и домика.

Плитки: 256×256 RGBA; внешний силуэт x=8,y=8,w=240,h=240, radius=31; лицевая зона x=24,y=23,w=208,h=201. Оптический центр буквы (128,124); безопасная область x=64…192,y=60…188. У всех пяти PNG одинаковый alpha. При 40 px холста видимое тело 37,5 px; при 64 px — 60 px. Фаска принадлежит материалу плитки и не является интерфейсной рамкой. SVG-мастера — docs/asset_sources/tiles/.

Сова: 512×512 RGBA, все исходники уменьшены одним коэффициентом с 1254×1254. Ось x=256, лапы y≈481. Не обрезать позы по разным bounding box. У defeat голова ниже намеренно; у happy размах крыльев больше без изменения масштаба тела. Пять поз статичные, не анимационная последовательность. Микроразличия в рисовке перьев допустимы; смену поз проверять в сцене.

Монета: icon_coin.svg 64×64, прозрачный холст; coin_gold.png — тот же рисунок, экспортированный в 256×256. Монета не заменяет корону очков. Механика валюты ещё отсутствует в исходном прототипе.

FX: каждый PNG 64×64 с настоящим alpha и белым силуэтом, без свечения, тени и текста. Белый позволяет менять цвет через modulate/цвет частиц. Это формы отдельных частиц, не запечённая анимация эффекта. SVG-мастера — docs/asset_sources/fx/.

## Границы графического комплекта

Нет запечённых букв, логотипа «Словопад», UI-панелей, кнопочных подложек, цифр, полос прогресса, ghost-рамок и игровых ореолов. Эти элементы и световые эффекты из концептов описаны для реализации в programmer_integration.md. Форма облака реплики совы также создаётся внутри Godot.

Иконки имеют фиксированные цвета и рассчитаны на тёмные поверхности. SVG автономны, без шрифтов, внешних картинок и filters. Размеры PNG/SVG, alpha, совпадение масок плиток и декодирование аудио проверены; результаты — asset_validation.json. Итоговая сцена и звуковой микс остаются на этапе интеграции.

## Происхождение и генерация

Фон/совы созданы встроенным imagegen. Плитки, иконки, монета и частицы — векторная графика с экспортом PNG через Inkscape. Новый фон заменяет старый по тому же пути; старый вариант доступен в истории Git, отдельные legacy-копии в проект не добавлены. Изменения художественные, игровая логика не менялась.

### background_forest v2 — задание генератору

Reference: второй присланный концепт, только визуальный стиль и композиция.

Create ONLY the standalone forest background painting from the visual style of this game concept. Final asset background_forest.png, landscape 16:9 1920x1080. The reference is for composition and painterly casual game art style, NOT an edit target UI. Absolutely NO UI panels, no board, no tiles, no logo, no words, no text, no numbers, no owl. Rich stylized storybook nighttime lake, saturated royal blue and navy colors, layered angular pine forests and mountains, moon near far upper right, tiny cozy timber cabin at extreme right middle near shoreline, foreground wooden jetty and warm lantern at far lower right, lower left flat rock perch for a separately drawn owl with a small warm lantern beside it, leafy tree canopy framing far upper left, ferns and stones along lower perimeter. Details concentrated outer 15 percent of frame. Central 60 percent is subdued dark blue misty lake and mountains with very little fine detail, to place puzzle board later. Beautiful hand painted game illustration with broad simplified shapes rather than realistic bark/photographic texture. Full bleed opaque landscape. No neon, no bloom, no glowing particles: lantern light painted locally only. Do not reproduce any interface or mascot from the reference.

### owl_idle

Single separate game sprite owl_idle.png. 512x512 square transparent PNG with real alpha, no checkerboard. A charming plump little woodland owl mascot, polished hand-painted casual puzzle game 2D illustration. Front facing, symmetrical, dark plum-brown wings and ear tufts, warm cream face discs and scalloped chest feathers, very large amber eyes, small orange beak and orange feet. Calm attentive expression, wings resting at sides. Entire body visible. Center body at x256, feet baseline y460, head top near y65, body roughly 260px wide, reserve room on both sides for later wing poses. Clean bold silhouette and simplified feather groups. No ground, cast shadow, glow, outline halo, props, text, speech bubble, UI or border. One owl only, matching the attached reference owl aesthetic.

Фактическая посадка после генерации описана выше; запрошенная в prompt геометрия не была принята на веру.

### Остальные позы

Каждая создана отдельным редактированием исходной owl_idle. Общая часть задания: Preserve exact same character identity, body proportions, palette, full body front view. OUTPUT MUST HAVE REAL ALPHA TRANSPARENCY like input. Use background removal for genuine RGBA transparent pixels. DO NOT DRAW CHECKERBOARD. No background of any color, no ground, no shadows, no speech bubble, no text. Square separate game sprite. Keep same body scale and feet baseline.

- **hint:** transform reference owl to a helpful hint pose. One wing on viewer right raised with one feather pointing upwards, eyes looking at raised feather. Entire wing in frame.
- **happy:** transform reference owl to happy pose, closed crescent smiling eyes, small open happy beak, both wings lifted outward joyfully. All feathers fit inside frame.
- **worried:** transform reference owl expression to worried, inner eyebrows raised with concerned large amber eyes and small closed beak, wings held close to body.
- **defeat:** transform reference owl expression to dejected after losing puzzle, head bowed slightly, eyes closed looking down, ear tufts drooping a little, wings resting low at sides. Head slightly lower due to bowing.
