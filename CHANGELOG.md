# Changelog

Локальные изменения поверх Evolution 3.62.1. Ветка исходников — `local-3.62` в `src/evolution`. `evolution-data-server` и `evolution-ews` остаются на теге 3.62.1.

Local changes on top of Evolution 3.62.1. The source branch is `local-3.62` in `src/evolution`. `evolution-data-server` and `evolution-ews` stay on the 3.62.1 tag.

## 2026-11-12

Коммиты / commits: `5565952` «Add an option to keep message headers visible while scrolling», слияние `7750103` в `local-3.62`.

### Русский

При чтении длинного письма блок с отправителем, получателями и датой остаётся вверху области просмотра и не уезжает вместе с телом. Если заголовков много, блок занимает не больше 40% высоты окна и прокручивается внутри себя.

Настройка: Правка → Параметры → Почта → Заголовки, флажок «Keep message headers visible while scrolling». По умолчанию он включён.

Ключ GSettings: `org.gnome.evolution.mail` / `pin-message-headers`.

Закрепляется только шапка самого письма. Печать, просмотр исходника и заголовки вложенных писем прокручиваются как раньше.

### English

While reading a long message, the block with the sender, recipients and date stays at the top of the preview and does not scroll away with the body. When there are many headers, the block is limited to 40% of the window height and scrolls inside itself.

Mail preferences (Edit → Preferences → Mail Preferences → Headers) gain the checkbox “Keep message headers visible while scrolling”. It is on by default.

GSettings key: `org.gnome.evolution.mail` / `pin-message-headers`.

Only the outer message header is pinned. Printing, source view and headers of nested messages keep scrolling with the content.

## 2026-11-12

Коммиты / commits: `471c13f` «Add an option to order flat threads like Outlook», слияние `fa6deb5` в `local-3.62`.

### Русский

В настройках почты (Правка → Параметры → Почта → Общие) под пунктом «Группировать сообщения в плоские цепочки» добавлен флажок «Упорядочивать плоские цепочки как в Outlook». По умолчанию он выключен и доступен только когда включены плоские цепочки.

Ключ GSettings: `org.gnome.evolution.mail` / `thread-flat-outlook`.

Когда оба флажка включены, каждая плоская цепочка перестраивается так:

- Самое новое письмо становится корнем цепочки — его видно, когда цепочка свёрнута. Более старые письма идут под ним, самое раннее — внизу.
- Дата берётся из столбца основной сортировки: «Получено» или «Отправлено». Если этой даты нет, используется вторая.
- Если основной столбец — дата по возрастанию, порядок обратный: корнем становится самое старое письмо, более новые идут ниже.
- Письма без пригодной даты сохраняют взаимный порядок и встают после писем с датой.
- Список перестраивается сразу. Если он заморожен, перестроение откладывается до разморозки.
- При сортировке столбца даты по убыванию ответы не уезжают вниз из‑за настройки «дети цепочки всегда по возрастанию»: ключ сортировки дочерних строк инвертируется, и самое новое письмо остаётся рядом с корнем.

### English

Mail preferences (Edit → Preferences → Mail Preferences → General) gain a checkbox under “Group messages to flat threads”: “Order flat threads like Outlook”. It is off by default and is sensitive only while flat threads are enabled.

GSettings key: `org.gnome.evolution.mail` / `thread-flat-outlook`.

With both options on, each flat thread is rebuilt as follows:

- The newest message becomes the thread root, so it is the row shown when the thread is collapsed. Older messages are listed under it, with the earliest at the bottom.
- The date comes from the primary sort column, Received or Sent. If that date is missing, the other date is used.
- An ascending date column reverses the order: the oldest message is the root and later messages follow below it.
- Messages with no usable date keep their relative order and are placed after dated messages.
- The message list is regenerated immediately. A frozen list is regenerated on thaw.
- When a date column is sorted descending, replies are not pushed to the bottom by “sort thread children always ascending”: the child sort key is negated, so the newest message stays next to the root.
