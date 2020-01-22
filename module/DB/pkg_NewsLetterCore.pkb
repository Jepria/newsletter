create or replace package body pkg_NewsletterCore is
/* package body: pkg_NewsletterCore::body */



/* group: Переменные */

/* ivar: logger
  Логер пакета.
*/
logger lg_logger_t := lg_logger_t.getLogger(
  moduleName    => pkg_NewsletterCore.Module_Name
  , objectName  => 'pkg_NewsletterCore'
);



/* group: Functions */

/* proc: mergeProject
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
)
is

  usedOperatorId integer;
  projectId      integer;

  /*
    Проверка существования батча.
  */
  procedure checkBatch
  is
    dummy v_sch_batch.batch_short_name%type;
  begin
    select
      batch_short_name
    into
      dummy
    from
      v_sch_batch
    where
      batch_short_name = batchShortName
    ;
  exception when others then
    raise_application_error(
      pkg_Error.ErrorStackInfo
      , logger.errorStack(
          'Ошибка проверки существования батча'
        )
      , true
    );
  end checkBatch;

-- mergeProject
begin
  usedOperatorId := coalesce(operatorId, pkg_Operator.getCurrentUserId());
  if batchShortName is not null then
    checkBatch();
  end if;
  select
    max(project_id)
  into
    projectId
  from
    nsc_project
  where
    project_short_name = projectShortName
  ;
  if projectId is null then
    -- Не удалось получить работающий с CLOB merge
    insert into
      nsc_project
    (
      project_id
    , project_short_name
    , project_name
    , subject
    , project_name_en
    , description
    , batch_short_name
    , message_template_path
    , message_template_text
    , is_html
    , unsubscribe_success_url
    , unsubscribe_fail_url
    , sender
    , operator_id
    )
    values(
      nsc_project_seq.nextval
    , projectShortName
    , projectName
    , subject
    , projectNameEn
    , batchShortName
    , description
    , messageTemplatePath
    , messageTemplateText
    , isHtmlMessage
    , unsubscribeSuccessUrl
    , unsubscribeFailUrl
    , sender
    , usedOperatorId
    )
    ;
  else
    update
      nsc_project
    set
      project_name                   = projectName
    , subject                        = subject
    , project_name_en                = projectNameEn
    , description                    = batchShortName
    , batch_short_name               = description
    , message_template_path          = messageTemplatePath
    , message_template_text          = messageTemplateText
    , is_html                        = isHtmlMessage
    , unsubscribe_success_url        = unsubscribeSuccessUrl
    , unsubscribe_fail_url           = unsubscribeFailUrl
    , sender                         = sender
    where
      project_id = projectId
    ;
  end if;
  logger.info('Добавлено/изменено проектов: ' || to_char(sql%rowcount));
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка добавления/изменения проекта ('
      || ' messageTemplateText="' || substr(messageTemplateText, 1, 1000) || '"'
      || ',messageTemplatePath="' || messageTemplatePath || '"'
      )
    , true
  );
end mergeProject;

/* proc: replaceMacro
  Подмена макропеременных.

  Параметры:
  messageText                 - текст сообщения
  macroData                   - данные макропеременных в формате
                                <переменная>=<значение>;<переменная>=<значение>.
*/
procedure replaceMacro(
  messageText in out clob
, macroData   in varchar2
)
is
  usedMacroData varchar2(4000):=
    replace(
    replace(
    replace(
      macroData
    , chr(10), ';'
    )
    , chr(13), ';'
    )
    , ';;', ';'
    )
    || ';'
    ;

  macroName varchar2(100);
  macroValue varchar2(1000);

  -- Служебные переменные
  currentPairPos integer := 1;
  macroNameLength integer;
  valuePos integer;
  valueLength integer;
  valueEndPos integer;
-- replaceMacro
begin
  loop
    exit when currentPairPos >= coalesce(length(usedMacroData), 0);
    macroNameLength :=
      instr(substr(usedMacroData, currentPairPos), '=') - 1
    ;
    macroName := substr(usedMacroData, currentPairPos, macroNameLength);
    valuePos := currentPairPos + macroNameLength + 1;
    -- Если кавычка
    if substr(macroData, valuePos) = '"' then
      valueLength := instr(substr(usedMacroData, valuePos), '"');
      valueEndPos := valuePos + valueLength;
      loop
        exit when substr(usedMacroData, valueEndPos + 1, 1) <> '"';
        valueEndPos := valueEndPos + 2 +
          instr(substr(macroData, valueEndPos + 2), '"');
      end loop;
      macroValue := substr(usedMacroData, valuePos, valueEndPos - valuePos + 1);
    else
      valueEndPos := instr(substr(usedMacroData, valuePos), ';') + valuePos - 2;
      macroValue := substr(usedMacroData, valuePos, valueEndPos - valuePos + 1);
    end if;
    messageText := replace(messageText, '$(' || macroName || ')', macroValue);
    exit when valueEndPos + 2 <= currentPairPos;
    currentPairPos := valueEndPos + 2;
  end loop;
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка подстановки макро ('
      || 'macroData="' || macroData || '"'
      || ')'
      )
    , true
  );
end replaceMacro;

/* proc: sendMessage
  Отправка сообщений.

  Параметры:
  projectShortName            - короткое наименование проекта
  batchShortName              - короткое наименование батча
                                (взаимноисключающее с projectShortName)
*/
procedure sendMessage(
  projectShortName varchar2 := null
, batchShortName   varchar2 := null
)
is
  project nsc_project%rowtype;
  usedOperatorId integer;
  usedTemplateText clob;

  /*
    Получение данных проекта.
  */
  procedure getProject
  is
  begin
    if batchShortName is not null and projectShortName is not null then
      raise_application_error(
        pkg_Error.IllegalArgument
        , 'Параметры batchShortName и projectShortName не могут быть заданы'
        || 'одновременно'
      );
    end if;
    select
      p.*
    into
      project
    from
      nsc_project p
    where
      project_short_name = projectShortName
      or batch_short_name = batchShortName
    ;
  exception when others then
    raise_application_error(
      pkg_Error.ErrorStackInfo
      , logger.errorStack(
          'Ошибка получения данных проекта'
        )
      , true
    );
  end getProject;

  /*
    Добавление сообщений.
  */
  procedure addMessage
  is

    /*
      Создание сообщения.
    */
    procedure createMessage(sourceMessage nsc_message_tmp%rowtype)
    is
      message nsc_message%rowtype;
      usedMessageText clob;
    begin
      message.message_key :=
        dbms_obfuscation_toolkit.md5(input_string => nsc_message_seq.nextval)
      ;
      message.project_id  := project.project_id;
      message.recipient   := sourceMessage.recipient;
      usedMessageText     :=
        replace(
        replace(
        replace(
        replace(
          coalesce(sourceMessage.message_text, usedTemplateText)
        , '$(email)'
        , sourceMessage.recipient
        )
        , '$(sender)'
        , coalesce(sourceMessage.sender, project.sender)
        )
        , '$(projectShortName)'
        , project.project_short_name
        )
        , '$(messageKey)'
        , message.message_key
        )
      ;
      replaceMacro(
        macroData   => sourceMessage.macro_data
      , messageText => usedMessageText
      );
      if coalesce(sourceMessage.is_html, project.is_html) = 1 then
        message.message_id  :=
          pkg_Mail.sendHtmlMessage(
            sender        => coalesce(sourceMessage.sender, project.sender)
          , recipient     => sourceMessage.recipient
          , subject       => coalesce(sourceMessage.subject, project.subject)
          , htmlText      => usedMessageText
          );
      else
        message.message_id  :=
          pkg_Mail.sendMessage(
            sender        => coalesce(sourceMessage.sender, project.sender)
          , recipient     => sourceMessage.recipient
          , subject       => coalesce(sourceMessage.subject, project.subject)
          , messageText   => usedMessageText
          );
      end if;
      message.date_ins    := sysdate;
      message.operator_id := usedOperatorId;
      insert into
        nsc_message
      values
        message
      ;
    exception when others then
      raise_application_error(
        pkg_Error.ErrorStackInfo
        , logger.errorStack(
            'Ошибка создания сообщения'
          )
        , true
      );
    end createMessage;

  begin
    for sourceMessage in
    (
    select
      *
    from
      nsc_message_tmp t
    where not exists
      (
      select
        1
      from
        nsc_unsubscribe u
      where
        u.recipient = replace(lower(t.recipient), ' ', '')
        and u.project_id = project.project_id
      )
    )
    loop
      createMessage(
        sourceMessage => sourceMessage
      );
    end loop;
  exception when others then
    raise_application_error(
      pkg_Error.ErrorStackInfo
      , logger.errorStack(
          'Ошибка добавления сообщений'
        )
      , true
    );
  end addMessage;

-- sendMessage
begin
  usedOperatorId := pkg_Operator.getCurrentUserId();
  getProject();
  if project.message_template_path is not null then
    pkg_File.loadClobFromFile(
      usedTemplateText
    , project.message_template_path
    );
  else
    usedTemplateText := project.message_template_text;
  end if;
  addMessage();
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка отправки сообщений ('
      || 'projectShortName="' || projectShortName || '"'
      || ', batchShortName="' || batchShortName || '"'
      || ')'
      )
    , true
  );
end sendMessage;

/* func: unsubscribe
  Отписаться от получения сообщений.

  Параметры:
  messageKey                  - уникальный ключ сообщения
  resultUrl                   - результирующий URL
*/
function unsubscribe(
  resultUrl  out varchar
, messageKey varchar2
)
return boolean
is
  projectId        nsc_project.project_id%type;
  recipient        nsc_message.recipient%type;
  usedOperatorId integer;
-- unsubscribe
begin
  select
    max(m.project_id)
  , max(m.recipient)
  into
    projectId
  , recipient
  from
    nsc_message m
  where
    message_key = messageKey
  ;
  if projectId is null then
    return false;
  else
    usedOperatorId := pkg_Operator.getCurrentUserId();
    insert into
      nsc_unsubscribe
    (
      unsubscribe_id
    , project_id
    , recipient
    , operator_id
    )
    select
      nsc_unsubscribe_seq.nextval
    , project_id
    , recipient
    , usedOperatorId
    from
      (
      select
        projectId as project_id
      , lower(replace(recipient, ' ', ''))
        as recipient
      from
        dual
      ) t
    where not exists (
      select
        1
      from
        nsc_unsubscribe u
      where
        u.recipient = t.recipient
        and u.project_id = t.project_id
    );
    return true;
  end if;
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка отписки от получения сообщений ('
      || 'messageKey="' || messageKey || '"'
      || ')'
      )
    , true
  );
end unsubscribe;

/* proc: clearUnsubscribe
  Удаляет данные отписки для данного получателя.

  recipient                   - получатель сообщения для отписки
*/
procedure clearUnsubscribe(
  recipient varchar
)
is
-- clearUnsubscribe
begin
  delete from
    nsc_unsubscribe s
  where
    s.recipient = replace(lower(clearUnsubscribe.recipient), ' ', '')
  ;
  logger.info('Удалено записей по отписке: ' || to_char(sql%rowcount));
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка удаления данных отписки сообщения ('
      || 'recipient="' || recipient || '"'
      || ')'
      )
    , true
  );
end clearUnsubscribe;

/* proc: clearOldData
  Удаление данных устаревших сообщений.

  dateBefore                  - дата, до которой удалять сообщения
*/
procedure clearOldData(
  dateBefore date
)
is
-- clearOldData
begin
  delete from
    nsc_message
  where
    date_ins < dateBefore
  ;
  logger.info('Удалено сообщений: ' || to_char(sql%rowcount));
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка удаления сообщений'
      )
    , true
  );
end clearOldData;

end pkg_NewsletterCore;
/
