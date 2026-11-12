# Локальная сборка Evolution с EWS

Сборка Evolution 3.62.1 с плагином Exchange (EWS) в Flatpak. Пакет ставится рядом с Flathub-версией и с системным Evolution и не забирает у них D-Bus и учётные записи.

Машина разработки: Linux Mint 22.3 (база Ubuntu 24.04 noble). Системные пакеты здесь серии 3.52. Свой пакет — 3.62.1 на `org.gnome.Platform//50`. Deb для noble не делаем: 3.62 тянет более новые библиотеки и затронул бы системный EDS, которым пользуется GNOME Shell.

## Идентификаторы

| | |
|---|---|
| App id | `org.gnome.Evolution.Local` |
| Бандл | `org.gnome.Evolution.Local.flatpak` |
| Ветка исходников | `local-3.62` — своя основная ветка, от тега `3.62.1` |
| Runtime | `org.gnome.Platform//50`, SDK `org.gnome.Sdk//50` |
| Имя в меню | Evolution (local) |
| Версия в `--version` | `evolution 3.62.1 (local)` |

`org.gnome.Evolution` принадлежит пакету с Flathub. Свой id обязателен: песочница не может владеть чужим именем, и без него Evolution не стартует (`ServiceUnknown`).

В манифесте это держат три настройки, их нужно сохранять вместе:

- EDS: `-DDBUS_SERVICES_PREFIX=org.gnome.Evolution.Local`
- evolution: `-DOVERRIDE_APPLICATION_ID=org.gnome.Evolution.Local`
- evolution: `-DVERSION_SUBSTRING= (local)` и `-DWITH_WMCLASS_OVERRIDE=evolution.bin`

## Откуда код

Исходники — submodules, ветка `local-3.62`. В этом репозитории лежит только SHA коммита, не дерево файлов.

| Каталог | Форк | Upstream (`remote gnome`) |
|---|---|---|
| `src/evolution` | git@github.com:ctapmex/evolution.git | https://gitlab.gnome.org/GNOME/evolution |
| `src/evolution-data-server` | git@github.com:ctapmex/evolution-data-server.git | https://gitlab.gnome.org/GNOME/evolution-data-server |
| `src/evolution-ews` | git@github.com:ctapmex/evolution-ews.git | https://gitlab.gnome.org/GNOME/evolution-ews |

EDS, evolution и evolution-ews держать одной серии. Сейчас это 3.62.1.

Клоны неглубокие (`--depth 1` от тега). Перед переносом правок на новый тег GNOME: `git fetch --unshallow gnome` в нужном submodule.

## Как вносить правки

`local-3.62` в каждом submodule — своя основная ветка. Новая работа начинается от неё и попадает в неё только после проверки.

1. В нужном submodule создать ветку от `local-3.62` и коммитить только в неё. Незакоммиченные файлы в бандл не входят.
2. В `packaging/org.gnome.Evolution.json` у этого модуля временно поставить `"branch"` на имя ветки фичи. Остальные модули остаются на `local-3.62`.
3. `bash docker/build.sh`, затем поставить бандл и проверить.
4. После подтверждения влить ветку в `local-3.62` через `git merge --no-ff`, чтобы в истории остался коммит слияния. Вернуть в манифесте `"branch": "local-3.62"` и собрать ещё раз.
5. В корне этого репозитория зафиксировать новый SHA: `git add src/<репозиторий>` и коммит. Каталог `src/` целиком не добавлять — git хранит submodule как gitlink (`160000`). Пока фича не влита, gitlink корня не коммитить.

Сборщик выписывает ветку из манифеста, а не текущий `HEAD` рабочего дерева. Источник типа `dir` и копии дерева не делать: у flatpak-builder 1.4.2 для `dir` контрольная сумма случайная, кэш модуля пропадает и сборка идёт заново.

## Сборка

```bash
bash docker/build.sh
```

Скрипт собирает образ `evolution-builder` (`docker/Dockerfile`, ubuntu 24.04, flatpak-builder) и запускает контейнер. Пользователь в группе `docker`, sudo не нужен. Контейнеру нужны `--privileged` и `--device /dev/fuse`: bubblewrap внутри Docker иначе не стартует. Сборка идёт с `--disable-rofiles-fuse`, `--ccache` (`CCACHE_MAXSIZE=8G`) и `--force-clean`. `--force-clean` очищает только `/src/build`. Кэш модулей — `cache/flatpak-builder` (`--state-dir`).

Каталоги:

| Путь | Содержимое |
|---|---|
| `cache/flatpak` | GNOME SDK и Platform, в контейнере смонтирован как `/var/lib/flatpak` |
| `cache/flatpak-builder` | кэш flatpak-builder и ccache |
| `build/` | дерево текущей сборки |
| `repo/` | ostree-репозиторий |
| `org.gnome.Evolution.Local.flatpak` | готовый бандл |

`cache/`, `build/`, `repo/` и `*.flatpak` в git не входят. Весь `cache/` через `chown -R` не прогонять: там многогигабайтный SDK. Контейнер работает от root и в конце возвращает владельцу только `repo/`, `build/`, `cache/flatpak-builder`, gitlink-каталоги submodule и бандл.

Повторный запуск без нового коммита на ветке из манифеста попадает в кэш модулей (порядка минуты). Новый коммит пересобирает только свой модуль; ccache остаётся. Смена коммита EDS сама кэш evolution и evolution-ews не сбрасывает: контрольная сумма у каждого модуля своя. После несовместимого изменения EDS эти кэши нужно удалить вручную.

Клоны submodule неглубокие. Если сборка падает с `shallow roots are not allowed to be updated` и `pathspec 'local-3.62' did not match`, `git fetch -p` внутри flatpak-builder стёр ссылки в зеркале `cache/flatpak-builder/git/`. Зеркало и `cache/` не удалять. Вернуть ссылку на коммит, который в зеркале уже есть:

```bash
git --git-dir=cache/flatpak-builder/git/_src_src_evolution \
  update-ref refs/heads/local-3.62 "$(git -C src/evolution rev-parse local-3.62)"
```

То же для `evolution-data-server` и `evolution-ews`, и для ветки фичи, если собирается она. `cat-file -t` по этому коммиту в зеркале должен отвечать `commit`. После этого снова `bash docker/build.sh`.

## Манифест

`packaging/org.gnome.Evolution.json`. Основа — манифест Flathub `org.gnome.Evolution`, app id и источники заменены.

Источники трёх модулей GNOME:

```json
{
  "type": "git",
  "path": "../src/evolution",
  "branch": "local-3.62",
  "disable-fsckobjects": true,
  "disable-submodules": true
}
```

`disable-fsckobjects` оставлен из-за неглубоких клонов. Источник типа `dir` не использовать: flatpak-builder 1.4.2 считает для него случайную контрольную сумму, и модуль пересобирается каждый раз.

`libdir` в `build-options` — абсолютный путь `/app/lib`. У meson из GNOME SDK иначе получается `lib64`, а относительное `lib` отвергает autotools.

`appstream-compose` выключен. `appstreamcli` из Ubuntu 24.04 не принимает SVG Evolution. Символическая иконка удаляется модулем `drop-symbolic-icon` до экспорта. В образе стоит `librsvg2-common`, чтобы основная SVG экспортировалась.

OpenLDAP качается с `https://mirror.koddos.net/OpenLDAP/openldap-release/openldap-2.6.15.tgz`. Официальный хост обрывает загрузку.

`packaging/modules/libcanberra` и `packaging/modules/intltool` — копии двух модулей Flathub, они в git. Каталог `packaging/shared-modules/` — полный checkout того же репозитория со своим `.git`, в git этого проекта не входит.

Модуль EWS ставит `libcamelews.so` (`camel-providers`) и `module-ews-configuration.so` (`evolution/modules`), плюс бэкенды адресной книги и календаря.

## Установка и проверка

Рядом может стоять Flathub `org.gnome.Evolution`. Его не удалять и не подменять.

```bash
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub org.gnome.Platform//50
flatpak install --user -y ./org.gnome.Evolution.Local.flatpak
flatpak run --user org.gnome.Evolution.Local --version
```

Ожидается `evolution 3.62.1 (local)`. Повторная установка того же бандла: `flatpak install --user --reinstall -y ./org.gnome.Evolution.Local.flatpak`.

Проверка EWS без входа в Exchange — файлы в установленной песочнице:

- `/app/lib/evolution-data-server/camel-providers/libcamelews.so`
- `/app/lib/evolution/modules/module-ews-configuration.so`

Проверять `--version` на сессионной шине пользователя. Отдельный `dbus-run-session` зависает на порталах и FUSE.
