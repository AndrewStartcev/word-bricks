# Музыка и звуки — происхождение и условия

Дата проверки источников: 2026-09-05. Все 13 аудиофайлов выбраны с CC0 1.0. Это не буквально «без лицензии»: CC0 разрешает копирование, переработку и коммерческое использование без обязательной атрибуции. [Условия CC0](https://creativecommons.org/publicdomain/zero/1.0/).

## Источники

| Материал | Автор | Страница | Условия на странице |
|---|---|---|
| Peaceful Forest | Samza | [OpenGameArt](https://opengameart.org/content/peaceful-forest) | CC0; автор указал возможность коммерческого и некоммерческого использования |
| Interface Sounds 1.0 | Kenney | [Kenney](https://kenney.nl/assets/interface-sounds) | Creative Commons CC0 |

Файл `licenses/kenney_interface_sounds_LICENSE.txt` скопирован из скачанного архива без изменения. Старый комментарий под музыкой обсуждает прежнюю формулировку attribution; в текущем описании она исправлена, автор подтвердил правку. Выбор основан на текущей странице CC0, а не только на подборке или поисковой выдаче.

## Файлы и соответствия

Музыка: `godot/assets/audio/music/music_forest_loop.ogg`, Ogg Vorbis stereo 44,1 kHz, длительность 61,109365 s. Исходник: `Peaceful Forest.wav`, 63,109365 s.

| Событие | Файл в godot/assets/audio/sfx/ | Исходник Kenney | Длительность, s | Gain плеера, dB | Cooldown, ms |
|---|---|---|---:|---:|---:|
| ui_click | `sfx_ui_click.wav` | `click_001.ogg` | 0.097120 | -15 | 80 |
| ui_back | `sfx_ui_back.wav` | `back_001.ogg` | 0.060975 | -15 | 100 |
| piece_move | `sfx_piece_move.wav` | `tick_001.ogg` | 0.044989 | -23 | 65 |
| piece_rotate | `sfx_piece_rotate.wav` | `switch_001.ogg` | 0.614762 | -19 | 90 |
| piece_lock | `sfx_piece_lock.wav` | `drop_002.ogg` | 0.188186 | -13 | 100 |
| line_clear | `sfx_line_clear.wav` | `glass_001.ogg` | 0.275533 | -12 | 180 |
| word_complete | `sfx_word_complete.wav` | `confirmation_002.ogg` | 0.539002 | -10 | 400 |
| chapter_complete | `sfx_chapter_complete.wav` | `confirmation_004.ogg` | 0.490408 | -9 | 1000 |
| hint | `sfx_hint.wav` | `question_001.ogg` | 0.490680 | -14 | 250 |
| invalid | `sfx_invalid.wav` | `error_002.ogg` | 0.165442 | -20 | 300 |
| defeat | `sfx_defeat.wav` | `minimize_004.ogg` | 0.417959 | -13 | 1000 |
| coin_collect | `sfx_coin_collect.wav` | `pluck_001.ogg` | 0.099524 | -16 | 80 |

## Обработка

Музыкальный loop собран из исходника: первые/последние 2 s сведены линейным crossfade. Порядок: исходный участок [2 s, T−2 s), затем blend последней и первой двухсекундных частей. Продолжительность T−2 s. Статическое усиление выставлено по измерению loudness с целью −24 LUFS, затем кодирование libvorbis quality=4. Динамическая компрессия и изменение высоты тона не применялись. Это технический loop-edit исходной композиции, а не новая авторская аранжировка. Музыкальную естественность перехода нужно прослушать в игре.

SFX декодированы из оригинальных OGG, сведены в mono 44,1 kHz, пиковый уровень приведён к −3 dBFS, добавлены краевые fade-in 2 ms / fade-out 5 ms. Сохранены PCM signed 16-bit WAV. Это конвертация уже сжатых источников, а не восстановление исходного качества. Игровые уровни в таблице применяются дополнительно на плеерах; пользовательская громкость — на шинах.

Проверено декодирование всех файлов и отсутствие цифрового clipping. Стык декодированного OGG: максимальная разница последнего/первого отсчёта ≈0,000905, при p99 соседних шагов ≈0,024454. Это проверка отсутствия грубого скачка, не замена слуховой приёмки. Итоговый микс в Godot пока не прослушан.

## Контроль происхождения

Оригинальные большие WAV/ZIP не дублируются в игровом каталоге. Прямые адреса и SHA-256 позволяют сверить повторное скачивание; per-file хеши SFX находятся в `audio_manifest.json`.

| Оригинал | Прямая загрузка | SHA-256 |
|---|---|---|
| Peaceful Forest.wav | [WAV](https://opengameart.org/sites/default/files/Peaceful%20Forest.wav) | `acf1576167caffddf87599bec49d1d37f83c4dd0b11c7d744cc12ea30232ebc0` |
| Interface Sounds ZIP | [ZIP](https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip) | `f2193d072726d6758a5f7871b2dcc54dcce0d5c35c6f0a62f92549b327c81232` |

## Добровольные титры

Обязательной атрибуции для выбранных CC0-файлов нет. При желании: «Music: Peaceful Forest — Samza (CC0). Sound effects: Kenney (CC0).» Самостоятельно нарисованная графика и AI-изображения этим документом не объявляются CC0.
