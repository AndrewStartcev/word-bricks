# Реестр ассетов — версия 2.0

Дата: 2026-09-05. Desktop 1600×900, 16:9.

47 игровых файлов: 16 PNG, 18 SVG, 1 OGG, 12 WAV. В `docs/asset_sources/` дополнительно 9 SVG-мастеров (5 плиток + 4 FX). Код игры не изменялся.

| Путь от корня Git | Назначение | Формат / размер |
|---|---|---|
| `godot/assets/audio/music/music_forest_loop.ogg` | Фоновая музыка лесной главы | Ogg Vorbis, stereo 44,1 kHz, 61,109 s |
| `godot/assets/audio/sfx/sfx_chapter_complete.wav` | chapter_complete | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/audio/sfx/sfx_coin_collect.wav` | coin_collect | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/audio/sfx/sfx_defeat.wav` | defeat | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/audio/sfx/sfx_hint.wav` | hint | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/audio/sfx/sfx_invalid.wav` | invalid | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/audio/sfx/sfx_line_clear.wav` | line_clear | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/audio/sfx/sfx_piece_lock.wav` | piece_lock | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/audio/sfx/sfx_piece_move.wav` | piece_move | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/audio/sfx/sfx_piece_rotate.wav` | piece_rotate | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/audio/sfx/sfx_ui_back.wav` | ui_back | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/audio/sfx/sfx_ui_click.wav` | ui_click | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/audio/sfx/sfx_word_complete.wav` | word_complete | PCM WAV, mono 44,1 kHz, 16-bit |
| `godot/assets/backgrounds/background_forest.png` | Фон лесной главы | PNG RGB, 1920×1080 |
| `godot/assets/characters/owl/owl_defeat.png` | Поражение | PNG RGBA, 512×512 |
| `godot/assets/characters/owl/owl_happy.png` | Успех | PNG RGBA, 512×512 |
| `godot/assets/characters/owl/owl_hint.png` | Подсказка | PNG RGBA, 512×512 |
| `godot/assets/characters/owl/owl_idle.png` | Спокойное ожидание | PNG RGBA, 512×512 |
| `godot/assets/characters/owl/owl_worried.png` | Беспокойство | PNG RGBA, 512×512 |
| `godot/assets/fx/particle_dot.png` | Белая точка для tint | PNG RGBA, 64×64 |
| `godot/assets/fx/particle_leaf.png` | Белый лист для tint | PNG RGBA, 64×64 |
| `godot/assets/fx/particle_shard.png` | Белый фрагмент для tint | PNG RGBA, 64×64 |
| `godot/assets/fx/particle_spark.png` | Белая искра для tint | PNG RGBA, 64×64 |
| `godot/assets/rewards/coin_gold.png` | Спрайт полёта монеты | PNG RGBA, 256×256 |
| `godot/assets/tiles/tile_bonus_green.png` | Бонус, резерв | PNG RGBA, 256×256 |
| `godot/assets/tiles/tile_danger_red.png` | Опасность, резерв | PNG RGBA, 256×256 |
| `godot/assets/tiles/tile_goal_gold.png` | Целевая плитка | PNG RGBA, 256×256 |
| `godot/assets/tiles/tile_normal_blue.png` | Обычная плитка | PNG RGBA, 256×256 |
| `godot/assets/tiles/tile_special_purple.png` | Специальная, резерв | PNG RGBA, 256×256 |
| `godot/assets/ui/icons/icon_chapter_forest.svg` | Значок лесной главы | SVG 64×64 |
| `godot/assets/ui/icons/icon_check.svg` | Подтверждение | SVG 64×64 |
| `godot/assets/ui/icons/icon_clue_paw.svg` | Значок подсказки о животном | SVG 64×64 |
| `godot/assets/ui/icons/icon_coin.svg` | Валюта / монета, резерв механики | SVG 64×64 |
| `godot/assets/ui/icons/icon_combo.svg` | Комбо / молния | SVG 64×64 |
| `godot/assets/ui/icons/icon_hint.svg` | Подсказка / лампа | SVG 64×64 |
| `godot/assets/ui/icons/icon_home.svg` | Главное меню | SVG 64×64 |
| `godot/assets/ui/icons/icon_leaf.svg` | Декоративный лист | SVG 64×64 |
| `godot/assets/ui/icons/icon_lock.svg` | Заблокировано | SVG 64×64 |
| `godot/assets/ui/icons/icon_music_off.svg` | Музыка выключена | SVG 64×64 |
| `godot/assets/ui/icons/icon_music_on.svg` | Музыка включена | SVG 64×64 |
| `godot/assets/ui/icons/icon_pause.svg` | Пауза | SVG 64×64 |
| `godot/assets/ui/icons/icon_restart.svg` | Начать заново | SVG 64×64 |
| `godot/assets/ui/icons/icon_score.svg` | Счёт / корона | SVG 64×64 |
| `godot/assets/ui/icons/icon_settings.svg` | Настройки | SVG 64×64 |
| `godot/assets/ui/icons/icon_sound_off.svg` | Звук выключен | SVG 64×64 |
| `godot/assets/ui/icons/icon_sound_on.svg` | Звук включён | SVG 64×64 |
| `godot/assets/ui/icons/icon_time.svg` | Время / секундомер | SVG 64×64 |

## Документы

- `godot/docs/programmer_integration.md` — главный документ для подключения в Godot.
- `godot/docs/designer_notes.md` — сравнение с концептами и геометрия.
- `godot/docs/audio_sources.md` — условия, преобразования, авторы.
- `godot/docs/audio_manifest.json` — реальные пути, gains, cooldown, loop и хеши.
- `godot/docs/asset_validation.json` — результаты технической проверки.

## Мастера

| SVG-источник | Растровый экспорт |
|---|---|
| `godot/docs/asset_sources/fx/particle_dot.svg` | `godot/assets/fx/particle_dot.png` |
| `godot/docs/asset_sources/fx/particle_leaf.svg` | `godot/assets/fx/particle_leaf.png` |
| `godot/docs/asset_sources/fx/particle_shard.svg` | `godot/assets/fx/particle_shard.png` |
| `godot/docs/asset_sources/fx/particle_spark.svg` | `godot/assets/fx/particle_spark.png` |
| `godot/docs/asset_sources/tiles/tile_bonus_green.svg` | `godot/assets/tiles/tile_bonus_green.png` |
| `godot/docs/asset_sources/tiles/tile_danger_red.svg` | `godot/assets/tiles/tile_danger_red.png` |
| `godot/docs/asset_sources/tiles/tile_goal_gold.svg` | `godot/assets/tiles/tile_goal_gold.png` |
| `godot/docs/asset_sources/tiles/tile_normal_blue.svg` | `godot/assets/tiles/tile_normal_blue.png` |
| `godot/docs/asset_sources/tiles/tile_special_purple.svg` | `godot/assets/tiles/tile_special_purple.png` |

## SHA-256

| Файл | SHA-256 |
|---|---|
| `godot/assets/audio/music/music_forest_loop.ogg` | `b919dc49d93ea68641c3c8f08e470954019bd9ed68e31ed39bf426292a157884` |
| `godot/assets/audio/sfx/sfx_chapter_complete.wav` | `57b6a61b27caca642006860cdcab3798bed293398a6b6838053b26b4c5a54eb9` |
| `godot/assets/audio/sfx/sfx_coin_collect.wav` | `a6f1c86f030ec59feda001bf0fb086655f0a43e3b2473382f99f130508f5204b` |
| `godot/assets/audio/sfx/sfx_defeat.wav` | `657711605703771f7a316f819e07cff97229cef9c720f5c76b4f275f479dd52e` |
| `godot/assets/audio/sfx/sfx_hint.wav` | `3e38e762107f5b365a581c5b52f78d9ffca035118d80b7cde497263e3c73129e` |
| `godot/assets/audio/sfx/sfx_invalid.wav` | `7d0e1b94efbd1a5ae6de3f84878dd48d3ddce274924689f2e17b8bffb31d2734` |
| `godot/assets/audio/sfx/sfx_line_clear.wav` | `68605ed7cb7e30ed3b7ba1ee588d2fcbe67070d78e8f2b6e599eeb363851ac46` |
| `godot/assets/audio/sfx/sfx_piece_lock.wav` | `a42acf23f1a4e63c355db9b2f3e0a5b55ef9a0f03631f59f2965fc20bbb8f755` |
| `godot/assets/audio/sfx/sfx_piece_move.wav` | `375c232612fb73eb446ed987fd9ebc437434c680cc303bd368b972d69cb44076` |
| `godot/assets/audio/sfx/sfx_piece_rotate.wav` | `92b00969ca56a15c684f3fb4e3b270c2db9cbae8b89222405da11279b8490834` |
| `godot/assets/audio/sfx/sfx_ui_back.wav` | `c993d30ec30479e8e389b3d7e85952b71bf1a98f28a878ec87e4b19a5ae623b2` |
| `godot/assets/audio/sfx/sfx_ui_click.wav` | `4f86d0f33c4e0e818b0ba64f9cd18fabcfe23b3dbb742896857010e96a98c11c` |
| `godot/assets/audio/sfx/sfx_word_complete.wav` | `1b81259e38c9e53eebb48718581bdd10e7c8b56e259a3e3aae888d4bb4ea9d0e` |
| `godot/assets/backgrounds/background_forest.png` | `0b9419f5e12eb502ea3db96b14f0e23caf93c398da4cac74aa5b4734417d86fb` |
| `godot/assets/characters/owl/owl_defeat.png` | `9af09d9c4d92732d5dcc0a295362361bcc210cf1923bced35499a4dd5700b703` |
| `godot/assets/characters/owl/owl_happy.png` | `ef55077eabb07716dc00828b94a5dbee55a50e108f7578b517fa9f988950669e` |
| `godot/assets/characters/owl/owl_hint.png` | `8af5cef2961dedaf1d47d6fdb0016aabaf8313d1e97f83877398621ae085445e` |
| `godot/assets/characters/owl/owl_idle.png` | `ecf16e1bad393a9eb3f16680d86179ad802cdac137d971855a02949e30de7ab7` |
| `godot/assets/characters/owl/owl_worried.png` | `84a58773e7d18007a7f75e5fb3eb69d4debbd35861156487a6a348aaf9e4cd62` |
| `godot/assets/fx/particle_dot.png` | `7dd7edb27d94ef27fd55c2a9dbb1f4921adba995e7a7eb04184040ee05ab747e` |
| `godot/assets/fx/particle_leaf.png` | `2b8de6d090eb153f0a4d26e0f422831c6af33a0fb3ffa7ca1eb1de12c16d22c3` |
| `godot/assets/fx/particle_shard.png` | `8df1c46772df349e769bc0f58b3fc38b84ad728ae72288defdb232b5fa3d95a5` |
| `godot/assets/fx/particle_spark.png` | `701548130d0be2278fa1d3829fc2ce432170409bad8ad099e5a445ed0a00c8ff` |
| `godot/assets/rewards/coin_gold.png` | `2a3becc3c99307efc3bb7a972237948a6e5cc60d6ce0d9d2fd57986ccc2f751d` |
| `godot/assets/tiles/tile_bonus_green.png` | `61f055d5e5b2e3a6118ac155302622b4d27530efe0f88582916131b3204c2215` |
| `godot/assets/tiles/tile_danger_red.png` | `d2503f58bc55e3bc58a0b80a69654df7f390c8d000acf429fc992f50b4c56a03` |
| `godot/assets/tiles/tile_goal_gold.png` | `147198a76426367026acd985b6bcd6e176e3f97e8de6529814781c6dccc29f22` |
| `godot/assets/tiles/tile_normal_blue.png` | `32150f01e0a805a3dcc12b3ff4d76add26f92eadaa104f382f30a82fd7244766` |
| `godot/assets/tiles/tile_special_purple.png` | `b10a981814e8edf6fcea3562d9fb2ce569041f7cf9ce52ef2582fc5c4cd210dd` |
| `godot/assets/ui/icons/icon_chapter_forest.svg` | `47d44905e2404b24fbc0f10e81a04111b410d3c1aa87825b983222c8e5c6b6f9` |
| `godot/assets/ui/icons/icon_check.svg` | `50b1f77cd4d561650eec166a8c6bbcd8499a9640315abcb302cf13a521cf9206` |
| `godot/assets/ui/icons/icon_clue_paw.svg` | `088141ea2e693896ba7b5461520525faf8b34e0a074f2476e5ce77146e75dd17` |
| `godot/assets/ui/icons/icon_coin.svg` | `c8fbcbb3d8241239c79dcce79ac5a4ed8c9add1652ee601b9b25cf709184a255` |
| `godot/assets/ui/icons/icon_combo.svg` | `d45961833e523e63abd5e0abf279a30a709fa009e5c22017f743c91fbc086562` |
| `godot/assets/ui/icons/icon_hint.svg` | `a84a589b17d46b95ee54a559201748f174a9bb029fb89db62873911373ad1140` |
| `godot/assets/ui/icons/icon_home.svg` | `57981b9c58e06efb35d343101a8bea9ffa3dda2531a6b2bf1ea4c137f5e6bfff` |
| `godot/assets/ui/icons/icon_leaf.svg` | `5110369ed05d2c18b2bae554da6d3be923ff1cb305c34ef8b236355633808b85` |
| `godot/assets/ui/icons/icon_lock.svg` | `3c2bc2b015e1998785a98c739a769fa9a485a4f5c7a2f5ff2fa39e0e01c2ccd8` |
| `godot/assets/ui/icons/icon_music_off.svg` | `aaafab958d16ddea20206152ed12bbe12603b57f97790c9c273686b5916c6f1d` |
| `godot/assets/ui/icons/icon_music_on.svg` | `174d8428891292f19f67bed7ba2b9e8ab5a07b091dc40e94e74adb785d5af0ba` |
| `godot/assets/ui/icons/icon_pause.svg` | `8ec76efdc5b2b458fbbe44db8af9e2bf0d48fc6f21e10e2a3e3a610c9b2ee446` |
| `godot/assets/ui/icons/icon_restart.svg` | `55980d65e51131ba3099530f0e8c2ac8a5a06f74c847ee9a310b87ea65cd0bc4` |
| `godot/assets/ui/icons/icon_score.svg` | `a97ae9ee9b209d3c6bbe7f8b16eefacf1da839a426987c39dc4494f7c6769dbf` |
| `godot/assets/ui/icons/icon_settings.svg` | `be8f87c7cfe5eef3a8725d25cd3acc15c48a80b410d5c694128165fbac1991b2` |
| `godot/assets/ui/icons/icon_sound_off.svg` | `5cd0670ffcf01e245cbfd5c34da076a6d0866ab56370c2854bc8fd33407d2294` |
| `godot/assets/ui/icons/icon_sound_on.svg` | `1ff8b26cf1527407fda4ca3399398c60da7f42a0c71c971a7b9056ccff781dbc` |
| `godot/assets/ui/icons/icon_time.svg` | `2d78496d419d5278a0a675cf1bb1a113da180f3842fd0661fa0cfc0874173af4` |
