# Ассеты лесной главы — заметки дизайнера

Дата: 2026-09-05. Назначение: desktop-first, 16:9, базовый экран 1600×900.

Этот комплект следует текущему ТЗ: PNG для растров, SVG для иконок. Указанные в старом `docs/ASSET_PLAN.md` имена WebP к этому комплекту не относятся. Сцены, скрипты, настройки и подключения текстур не изменены.

## Стиль

Ночной синий лес, спокойная вода и горы; тёплые детали домика находятся справа. Сова — коричневая с кремовой грудкой и янтарными глазами. Плитки фронтальные, с округлёнными углами, внутренней фаской и умеренным бликом в верхнем левом углу. Светлая часть фаски — материал плитки, а не внешнее свечение. Иконки светло-голубые; корона, молния и лампа золотистые, галочка зелёная, отключение отмечено красной диагональю.

В игровых файлах нет текста, букв, цифр, UI-панелей, кнопочных подложек, интерфейсных рамок, progress bar, neon, glow или внешних теней. Фон непрозрачный; плитки и совы имеют настоящий RGBA alpha. Шахматка не впечена.

## Фон

`res://assets/backgrounds/background_forest.png`, 1920×1080, RGB PNG.

Рассчитан на показ целиком в 16:9. Рабочая центральная зона ориентировочно x=480…1344, y=108…972: низкая насыщенность и контраст, но это полноценный пейзаж, а не однотонная заливка. Деревья, камни, домик и луна сосредоточены по периферии. Фон сам по себе не гарантирует контраст букв — игровое поле и его подложку собирает Godot.

Генератор выдал 1672×941; финальный экспорт приведён к 1920×1080. Это небольшой апскейл, не нативная генерация 1920×1080. Исходное соотношение сторон отличается от 16:9 менее чем на 0,1%.

## Плитки

Все пять PNG имеют размер 256×256 и побитово одинаковую альфа-маску. Векторные мастера лежат в `godot/docs/asset_sources/tiles/` и экспортированы через Inkscape 1.2.2. Изменение цвета не меняет геометрию.

- Внешняя геометрия: x=8, y=8, width=240, height=240, radius=45.
- Прозрачное поле: 8 px с каждой стороны, то есть 3,125% размера текстуры.
- Лицевая площадка: x=27, y=25, width=202, height=199.
- Рекомендуемая безопасная область буквы: x=64…192, y=60…188.
- Центр буквы: ориентировочно (128, 124), затем оптическая корректировка по выбранному шрифту.
- При размере текстуры 40 px видимая плитка занимает 37,5 px; при 64 px — 60 px. Учитывай это при расчёте зазоров сетки.
- Масштабировать равномерно. Nine-patch не нужен: это квадратный игровой объект.

Буквы накладываются программно. Для золотой плитки понадобится тёмная буква; для остальных контраст подбирается вместе со шрифтом и его обводкой в игре. Значение состояния желательно дополнительно передавать игровым поведением/символом, а не одним цветом. Green/red/purple — только визуальные заготовки для будущих механик.

## Сова

Все состояния — 512×512 RGBA PNG. Общий полный холст сохраняется: не обрезать каждый спрайт по индивидуальному bounding box. Исходники 1254×1254 уменьшены с одним коэффициентом, без растяжения. Примерная ось тела x=256, линия лап y=480–481. У defeat голова опущена намеренно; у happy увеличивается размах крыльев, а не масштаб тела.

Для смены состояний использовать один прямоугольник/узел и один масштаб. Вариант привязки: нижняя опорная точка (256, 481) в координатах текстуры. При центрированном Sprite2D она находится приблизительно на (0, 225) относительно центра. Рекомендуемая проверка в реальном интерфейсе: 192–256 px по стороне холста.

Это пять статичных поз, не покадровая анимация. Между ними возможны небольшие различия рисовки перьев; резкая смена или короткое смешивание должны оцениваться в сцене.

## SVG-иконки

14 отдельных файлов. Холст и viewBox 64×64. Никаких внешних ресурсов, шрифтов, встроенных растров, CSS, фильтров или скриптов. Используются простые paths, rectangles, circles, ellipses и linearGradient. Нет подложки кнопки. Имена `score`, `combo`, `time`, `hint` обозначают соответственно корону, молнию, секундомер и лампу.

Иконка не задаёт область клика: её создаёт интерфейс. Иконки рассчитаны на тёмные поверхности. Варианты off повторяют соответствующий on и добавляют красную диагональ.

## Передача в Godot

Файловый путь `godot/assets/...` соответствует ресурсу `res://assets/...`, поскольку корень Godot-проекта — `godot/`. Конкретные настройки импорта остаются на этапе интеграции. Для проверки начать с lossless и линейной фильтрации, без repeat; не включать pixel-art обработку для рисованной совы. Буквы, эффекты выделения, HUD и интерактивные области остаются отдельными элементами Godot.

Нативный импорт и отрисовка в Godot в этой передаче не проверены: выполнена проверка самих файлов и рендер SVG через Inkscape. Комплект готов к подключению, но в текущую игру автоматически не подключён.

## Проверки

Проверены размеры всех 11 PNG, RGBA и диапазон alpha для 10 прозрачных текстур, полное совпадение альфа-масок пяти плиток, XML и размер 14 SVG. Просмотрены плитки в 40, 64 и 128 px, совы вместе на светлой подложке, иконки на тёмной. Геометрия и характеры визуально различимы. Старые генерации с впечённой шахматкой исключены из комплекта.

## Происхождение и задания генератору

Фон и совы созданы встроенным imagegen. Приложенный пользователем лист служил визуальным ориентиром; изображения не вырезались из него. Плитки и иконки созданы как векторная графика. Ниже сохранены задания для воспроизведения направления; новая генерация не гарантирует пиксельного совпадения.

### background_forest

Create a single production game background asset background_forest.png, landscape 1920x1080 16:9. Polished hand-painted casual puzzle game illustration: blue nighttime forest lake, distant layered mountains, dark indigo pine forest. Quiet low-contrast middle 60 percent for a word puzzle board placed later. Rich detailed tree trunks, leaves, stones at far left and right edges, small cozy cabin near far right shore, modest moon upper right. No neon, no glow effects, no bloom. Natural restrained moonlight. No UI, text, letters, numbers, logos, frames, panels, characters or tiles. Full bleed landscape, opaque background. Reference aesthetic: friendly storybook forest, blue and navy with restrained warm gold accents. This is an actual background only, not a preview sheet.

### owl_idle

Single separate game sprite owl_idle.png. 512x512 square transparent PNG with real alpha, no checkerboard. A charming plump little woodland owl mascot, polished hand-painted casual puzzle game 2D illustration. Front facing, symmetrical, dark plum-brown wings and ear tufts, warm cream face discs and scalloped chest feathers, very large amber eyes, small orange beak and orange feet. Calm attentive expression, wings resting at sides. Entire body visible. Center body at x256, feet baseline y460, head top near y65, body roughly 260px wide, reserve room on both sides for later wing poses. Clean bold silhouette and simplified feather groups. No ground, cast shadow, glow, outline halo, props, text, speech bubble, UI or border. One owl only, matching the attached reference owl aesthetic.

Фактическая посадка после генерации описана выше; запрошенная в prompt геометрия не была принята на веру.

### Остальные позы

Каждая создана отдельным редактированием исходной owl_idle. Общая часть задания: Preserve exact same character identity, body proportions, palette, full body front view. OUTPUT MUST HAVE REAL ALPHA TRANSPARENCY like input. Use background removal for genuine RGBA transparent pixels. DO NOT DRAW CHECKERBOARD. No background of any color, no ground, no shadows, no speech bubble, no text. Square separate game sprite. Keep same body scale and feet baseline.

- **hint:** transform reference owl to a helpful hint pose. One wing on viewer right raised with one feather pointing upwards, eyes looking at raised feather. Entire wing in frame.
- **happy:** transform reference owl to happy pose, closed crescent smiling eyes, small open happy beak, both wings lifted outward joyfully. All feathers fit inside frame.
- **worried:** transform reference owl expression to worried, inner eyebrows raised with concerned large amber eyes and small closed beak, wings held close to body.
- **defeat:** transform reference owl expression to dejected after losing puzzle, head bowed slightly, eyes closed looking down, ear tufts drooping a little, wings resting low at sides. Head slightly lower due to bowing.
