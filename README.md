# Hive Defense

2D-игра на **Godot 4.7.2-stable**.

## Структура проекта

- `scenes/` — сцены (`.tscn`), стартовая сцена: `scenes/main.tscn`
- `scripts/` — скрипты GDScript (`.gd`)
- `assets/` — графика, звуки, шрифты и другие ресурсы
- `project.godot` — конфигурация проекта Godot

## Работа команды в Git

### Первый запуск (для нового участника)

1. Получите доступ в репозиторий: владелец добавляет участника в **Settings → Collaborators** с ролью **Write**.
2. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/iskininarslan-beep/Hive-defense.git
   ```
3. Откройте папку проекта в **Godot 4.7.2-stable**.

### Ежедневная работа

```bash
git pull --rebase origin main
git add .
git commit -m "Краткое описание изменений"
git push origin main
```

> Перед созданием новых веток используйте `git checkout -b feature/<название>`, а затем отправляйте их командой `git push -u origin feature/<название>`.
