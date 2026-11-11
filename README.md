# Локальная сборка Evolution с EWS

Сборка Evolution 3.62.1 с плагином Exchange (EWS) в Flatpak. Пакет ставится рядом с Flathub-версией и с системным Evolution и не забирает у них D-Bus и учётные записи.

Машина разработки: Linux Mint 22.3 (база Ubuntu 24.04 noble). Системные пакеты здесь серии 3.52. Свой пакет — 3.62.1 на `org.gnome.Platform//50`. Deb для noble не делаем: 3.62 тянет более новые библиотеки и затронул бы системный EDS, которым пользуется GNOME Shell.

## Идентификаторы

| | |
|---|---|
| App id | `org.gnome.Evolution.Local` |
| Бандл | `org.gnome.Evolution.Local.flatpak` |
| Ветка исходников | `local-3.62` (тег `3.62.1`) |
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
| `src/evolution` | https://github.com/ctapmex/evolution | https://gitlab.gnome.org/GNOME/evolution |
| `src/evolution-data-server` | https://github.com/ctapmex/evolution-data-server | https://gitlab.gnome.org/GNOME/evolution-data-server |
| `src/evolution-ews` | https://github.com/ctapmex/evolution-ews | https://gitlab.gnome.org/GNOME/evolution-ews |

EDS, evolution и evolution-ews держать одной серии. Сейчас это 3.62.1.

Клоны неглубокие (`--depth 1` от тега). Перед переносом правок на новый тег GNOME: `git fetch --unshallow gnome` в нужном submodule.

Ветка `local-3.62` создана локально от тега. На GitHub её ещё нужно отправить с машины, где есть логин:

```bash
git -C src/evolution push -u origin local-3.62
git -C src/evolution-data-server push -u origin local-3.62
git -C src/evolution-ews push -u origin local-3.62
```

Пока push не сделан, `git status` в submodule показывает `origin/local-3.62 [gone]`. Коммит тега на форке уже есть.

## Как вносить правки

1. Править файлы в `src/evolution`, `src/evolution-data-server` или `src/evolution-ews`.
2. Коммит в этом submodule, на ветке `local-3.62`.
3. `bash docker/build.sh`.
4. В корне этого репозитория зафиксировать новый SHA: `git add src/<репозиторий>` и коммит. Так другая копия проекта соберёт ту же правку.

Сборка читает коммит ветки `local-3.62`. Незакоммиченные файлы в бандл не входят: `docker/build-inside.sh` печатает предупреждение и всё равно берёт ветку. Каталог `src/` в коммит этого репозитория не добавлять — git хранит submodule как gitlink (`160000`).

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

Повторный запуск без изменений в `local-3.62` попадает в кэш модулей (порядка минуты). Правка в evolution пересобирает модуль evolution. Смена коммита EDS сама кэш evolution и evolution-ews не сбрасывает: контрольная сумма у каждого модуля своя. После несовместимого изменения EDS эти кэши нужно удалить вручную.

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
