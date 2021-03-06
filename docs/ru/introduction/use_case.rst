Использование в Яндекс.Метрике и других отделах Яндекса
------------------------------------------

В Яндекс.Метрике ClickHouse используется для нескольких задач.
Основная задача - построение отчётов в режиме онлайн по неагрегированным данным. Для решения этой задачи используется кластер из 374 серверов, хранящий более 20,3 триллионов строк в базе данных. Объём сжатых данных, без учёта дублирования и репликации, составляет около 2 ПБ. Объём несжатых данных (в формате tsv) составил бы, приблизительно, 17 ПБ.

Также ClickHouse используется:
 * для хранения данных Вебвизора;
 * для обработки промежуточных данных;
 * для построения глобальных отчётов Аналитиками;
 * для выполнения запросов в целях отладки движка Метрики;
 * для анализа логов работы API и пользовательского интерфейса.

ClickHouse имеет более десятка инсталляций в других отделах Яндекса: в Вертикальных сервисах, Маркете, Директе, БК, Бизнес аналитике, Мобильной разработке, AdFox, Персональных сервисах и т п.
