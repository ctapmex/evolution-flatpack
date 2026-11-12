# Сборка и ветки

`local-3.62` в `src/evolution`, `src/evolution-data-server` и `src/evolution-ews` — основная ветка. Новую работу вести отдельной веткой от неё. В `local-3.62` вливать только после подтверждения проверки, командой `git merge --no-ff`, чтобы остался коммит слияния. Затем вернуть в манифесте `"branch": "local-3.62"`.

Сборка: `bash docker/build.sh`. Нужен Docker, без sudo. Бандл: `org.gnome.Evolution.Local.flatpak`.

Сборщик берёт ветку из `packaging/org.gnome.Evolution.json`, не текущий `HEAD`. Незакоммиченные файлы в бандл не входят. На время проверки фичи поменять только `"branch"` нужного модуля. Коммит gitlink `src/<репозиторий>` в корне делать после вливания в `local-3.62`.

Не делать:

- источник типа `dir` и любые копии дерева исходников — у flatpak-builder 1.4.2 контрольная сумма `dir` случайная, кэш модуля сбрасывается;
- удаление `cache/`, `cache/flatpak-builder` или зеркал `cache/flatpak-builder/git/`;
- `chown -R` на весь `cache/` (там SDK).

Клоны submodule неглубокие (`--depth 1`). Ошибка `shallow roots are not allowed to be updated` и `pathspec '…' did not match` значит, что `git fetch -p` стёр ссылки в зеркале. Зеркало не пересоздавать. Вернуть существующий коммит:

```bash
git --git-dir=cache/flatpak-builder/git/_src_src_evolution \
  update-ref refs/heads/ИМЯ "$(git -C src/evolution rev-parse ИМЯ)"
```

Имена зеркал: `_src_src_evolution`, `_src_src_evolution-data-server`, `_src_src_evolution-ews`. Перед `update-ref` проверить `git --git-dir=… cat-file -t SHA` — ответ `commit`. Затем снова `bash docker/build.sh`.

Новый коммит пересобирает только свой модуль. Кэш EDS не сбрасывает кэш evolution и evolution-ews. `git fetch --unshallow` — только перед переносом на новый тег GNOME.
