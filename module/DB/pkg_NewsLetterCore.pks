create or replace package pkg_NewsletterCore is
/* package: pkg_NewsletterCore
  Интерфейсный пакет модуля NewsLetterCore.

  SVN root: p/javaenterpriseplatform/svn/Module/NewsletterCore
*/

/* const: Module_Name
  Название модуля, к которому относится пакет.
*/
Module_Name constant varchar2(30) := 'NewsLetterCore';



/* group: Functions */

/* pproc: mergeProject
  Добавление или обновление проекта рассылки.

  Параметры:
  projectShortName            - уникальное короткое уникальное наименование
                                проекта
  projectName                 - наименование проекта на языке по-умолчанию
  subject                     - тема письма
  projectNameEn               - наименование проекта на английском языке
  batchShortName              - короткое уникальное наименование батча
  description                 - описание проекта
  messageTemplateText         - текст шаблона сообщений, который может
                                содержать макросы
  messageTemplatePath         - Файловый путь к тексту шаблона сообщения (
                                параметр, взаимноисключаемый с
                                messageTemplatePath)
  isHtmlMessage               - флаг HTML-сообщения
  unsubscribeSuccessUrl       - URL страницы при успешной отписке
  unsubscribeFailUrl          - URL страницы при неуспешной отписке
  sender                      - отправитель сообщения
  operatorId                  - id оператора, меняющего запись. По-умолчанию
                                текущий.

  ( <body::mergeProject>)
*/
procedure mergeProject(
  projectShortName       varchar2
, projectName            varchar2
, subject                varchar2
, projectNameEn          varchar2 := null
, batchShortName         varchar2 := null
, description            varchar2 := null
, messageTemplateText    clob := null
, messageTemplatePath    varchar2 := null
, isHtmlMessage          integer  := null
, unsubscribeSuccessUrl  varchar2 := null
, unsubscribeFailUrl     varchar2 := null
, sender                 varchar2 := null
, operatorId             integer  := null
);

/* pproc: replaceMacro
  Подмена макропеременных.

  Параметры:
  messageText                 - текст сообщения
  macroData                   - данные макропеременных в формате
                                <переменная>=<значение>;<переменная>=<значение>.

  ( <body::replaceMacro>)
*/
procedure replaceMacro(
  messageText in out clob
, macroData   in varchar2
);

/* pproc: sendMessage
  Отправка сообщений.

  Параметры:
  projectShortName            - короткое наименование проекта
  batchShortName              - короткое наименование батча
                                (взаимноисключающее с projectShortName)

  ( <body::sendMessage>)
*/
procedure sendMessage(
  projectShortName varchar2 := null
, batchShortName   varchar2 := null
);

/* pfunc: unsubscribe
  Отписаться от получения сообщений.

  Параметры:
  messageKey                  - уникальный ключ сообщения
  resultUrl                   - результирующий URL

  ( <body::unsubscribe>)
*/
function unsubscribe(
  resultUrl  out varchar
, messageKey varchar2
)
return boolean;

/* pproc: clearUnsubscribe
  Удаляет данные отписки для данного получателя.

  recipient                   - получатель сообщения для отписки

  ( <body::clearUnsubscribe>)
*/
procedure clearUnsubscribe(
  recipient varchar
);

/* pproc: clearOldData
  Удаление данных устаревших сообщений.

  dateBefore                  - дата, до которой удалять сообщения

  ( <body::clearOldData>)
*/
procedure clearOldData(
  dateBefore date
);

end pkg_NewsletterCore;
/

