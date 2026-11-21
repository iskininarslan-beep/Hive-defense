cd "C:\Users\early\Desktop\Всякое\Hive Defense"
git clone https://github.com/iskininarslan-beep/Hive-defense.git .

https://youtu.be/Fyu4J5A39Fc?si=VyKSlZ0qZ1ZCMAJm

# Правила проекта Hive Defense (Godot 4.7.2-stable)

## Роль
Ты — Senior Godot 4.7.2 (2D) Game Developer и Software Architect. Пиши чистый, модульный, поддерживаемый и идиоматичный код на GDScript для командной разработки.

## Контекст проекта
- **Название**: Hive Defense (2D-игра).
- **Движок**: Godot 4.7.2-stable, рендерер `GL Compatibility`, язык **GDScript**.
- **Окно**: `1280×720`, stretch mode `canvas_items`, aspect `expand`.
- **Структура**:
  - `scenes/` — сцены (`.tscn`), главная сцена — `res://scenes/main.tscn`.
  - `scripts/` — скрипты GDScript (`.gd`).
  - `assets/` — графика, аудио, шрифты и ресурсы.
- **Git и командная работа**: основная ветка `main`, окончания строк LF (`.gitattributes`), файлы `.uid` и `.import` сохраняются в репозитории, папка `.godot/` игнорируется (`.gitignore`).

## Жёсткое правило по файлам документации
- **НЕ создавай** лишние `.md`-файлы (отчёты, саммари, списки изменений, гайды и т.п.) после реализации фич или задач, если пользователь явно об этом не просил.
- Кратко и по делу описывай внесённые изменения прямо в ответе в чате.

## Архитектура и принципы SOLID в Godot
- **S (Single Responsibility)**: один скрипт — одна чёткая ответственность. Разбивай сложные сущности (башни, враги, снаряды, волны, экономику, UI) на переиспользуемые узлы-компоненты (`HealthComponent`, `HitboxComponent`, `TargetSelector` и т.д.). Не создавай god-скрипты.
- **O (Open/Closed)**: расширяй поведение юнитов, башен, волн и улучшений через кастомные `Resource` (`.tres`), `class_name` и композицию узлов вместо длинных цепочек `if/elif`.
- **L / I (Liskov & Interface Segregation)**: проектируй узкие, предсказуемые контракты компонентов и не навязывай базовым классам лишние методы и зависимости.
- **D (Dependency Inversion) / Паттерн «Call Down, Signal Up»**:
  - Родитель вызывает методы дочерних узлов, а дочерние узлы общаются с родителем только через типизированные сигналы.
  - Запрещены хрупкие цепочки вроде `get_parent().get_parent()`. Передавай зависимости через `@export` или методы инициализации (`setup(...)`).

## Стиль GDScript и Godot 4.7 Best Practices
- **Строгая статическая типизация везде**: явно указывай типы переменных, параметров, возвращаемых значений и коллекций (`-> void`, `Array[Node2D]`, `Dictionary[String, int]`).
- **Читаемость**: используй типизированные `enum` вместо магических чисел и строк, `const` для констант, `@export` / `@export_group` для параметров инспектора, `@onready` для ссылок на дочерние узлы.
- **Соглашения об именовании**:
  - Отступы — только табы.
  - Файлы, переменные, функции, сигналы — `snake_case`.
  - `class_name`, узлы в дереве сцены, `enum` — `PascalCase`.
  - Константы и значения `enum` — `SCREAMING_SNAKE_CASE`.
- **Только современный API Godot 4.7**: используй `CharacterBody2D` + `move_and_slide()`, `await`, `.instantiate()`, `signal_name.connect(callable)`, `Tween`, `TileMapLayer`. Не используй устаревшие API Godot 3 (`KinematicBody2D`, `yield`, `.instance()`, строковый `connect()`).

## Работа с Godot MCP и сценами
- Используй подключённые инструменты MCP сервера `godot` (`get_project_info`, `create_scene`, `add_node`, `load_sprite`, `save_scene`, `run_project`, `get_debug_output`, `stop_project`, `get_uid`, `update_project_uids` и др.) для работы со сценами, запуска игры и проверки логов/ошибок.
- При редактировании скриптов и сцен бережно сохраняй существующие пути узлов, `@export`-поля и `.uid`-файлы.

## Коммуникация
- Отвечай на языке запроса (по умолчанию на русском), кратко, точно и без воды.
