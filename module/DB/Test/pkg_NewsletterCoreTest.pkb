create or replace package body pkg_NewsletterCoreTest is
/* package body: pkg_NewsletterCoreTest::body */


/* const: Test_BatchShortName
  Короткое наименование батча "Тестовый батч NewsLetter".
*/
Test_BatchShortName constant varchar2(50) := 'NewsletterCoreTest';

/* const: Test_Subject
  Тестовая тема сообщения.
*/
Test_Subject constant varchar2(100) := 'pkg_NewsletterCoreTest';




/* group: Переменные */

/* ivar: logger
  Логер пакета.
*/
logger lg_logger_t := lg_logger_t.getLogger(
  moduleName    => pkg_NewsletterCore.Module_Name
  , objectName  => 'pkg_NewsletterCoreTest'
);



/* group: Functions */



/* group: Вспомогательные функции */

/* ifunc: getMessageTemplatePath
  Получение полного пути к тестовому шаблону файла сообщения.
*/
function getMessageTemplatePath
return varchar2
is
  templatePath varchar2(1000);
-- getMessageTemplatePath
begin
  templatePath :=
    opt_option_list_t(pkg_NewsletterCore.Module_Name).getString(
       TemplatePath_OptionSName
    );
  if templatePath is null then
    raise_application_error(
      pkg_Error.IllegalArgument
      , 'Значение опции не найдено'
    );
  end if;
  return templatePath;
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка получения полного пути к тестовому шаблону'
      || ' для задания воспользуйтесь процедурой setMessageTemplatePath'
      )
    , true
  );
end getMessageTemplatePath;

/* proc: setMessageTemplatePath
  Установка полного пути к тестовому шаблону файла сообщения.

  templatePath                - задание полного пути шаблона
*/
procedure setMessageTemplatePath(
  templatePath varchar2
)
is
-- setMessageTemplatePath
begin
  opt_option_list_t(pkg_NewsletterCore.Module_Name).setString(
    TemplatePath_OptionSName
  , templatePath
  );
end setMessageTemplatePath;

/* proc: simpleNewsletter
  Добавление двух записей во временной таблице.
*/
procedure simpleNewsletter
is
-- simpleNewsletter
begin
  logger.trace('simpleNewsletter: begin');
  delete from nsc_message_tmp;
  insert into nsc_message_tmp(
    recipient
  , sender
  , message_text
  , macro_data
  , is_html
  )
  select
    'fakeemail1@oramake.com' as recipient
  , null as sender
  , null as message_text
, 'macro1=macro_1_value
macro2=macro_2_value' as macro_data
  , null as is_html
  from
    dual
  union all
  select
    'fakeemail2@oramake.com' as recipient
  , null as sender
  , 'fake_body_2' as message_text
  , null as macro_data
  , 1 as is_html
  from
    dual
  ;
  logger.info('simpleNewsletter: ' || to_char(sql%rowcount));
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка добавления записей для временной таблицы'
      )
    , true
  );
end simpleNewsletter;

/* iproc: loadTestBatch
  Загружает тестовый батч.
*/
procedure loadTestBatch
is
  pragma autonomous_transaction;
  xmlText clob;
-- loadTestBatch
begin
  pkg_SchedulerLoad.loadJob(
    moduleName     => pkg_NewsletterCore.Module_Name
  , jobShortName   => 'simple_newsletter_test'
  , fileText       =>
'-- Тестовый job для загрузки писем
begin
  pkg_NewsletterCoreTest.simpleNewsletter();
end;'
  , batchShortName  => Test_BatchShortName
  );
  xmlText :=
'<?xml version="1.0" encoding="Windows-1251"?>
<batch short_name="' || Test_BatchShortName || '">
  <name>Тестовый батч NewsLetter </name>
  <content id="1" job="initialization" module="Scheduler"/>
  <!-- В job вызывается процедура pkg_NewsletterCoreTest.simpleNewsletter() -->
  <content id="2" job="simple_newsletter_test">
    <condition id="1">true</condition>
  </content>
  <content id="3" job="send_message" module="NewsletterCore">
    <condition id="2">true</condition>
  </content>
  <content id="4" job="commit" module="Scheduler">
    <condition id="3">true</condition>
  </content>
</batch>'
  ;
  logger.trace(xmlText);
  pkg_SchedulerLoad.loadBatch(
    moduleName      => pkg_NewsletterCore.Module_Name
  , batchShortName  => Test_BatchShortName
  , xmlText         => xmlText
  );
  commit;
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка загрузки тестового батча'
      )
    , true
  );
end loadTestBatch;

/* proc: deleteProject
  Удаление проекта.

  Параметры:
  projectShortName            - короткое наимеование проекта
*/
procedure deleteProject(
  projectShortName varchar2
)
is
-- deleteProject
begin
  delete from
    nsc_project
  where
    project_short_name = projectShortName
  ;
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка удаления проекта ('
      || ' projectShortName="' || projectShortName || '"'
      || ')'
      )
    , true
  );
end deleteProject;

/* proc: runTestBatch
  Выполнение тестового батча.

  Параметры:
  skipDeletionFlag            - пропустить удаление батча.
*/
procedure runTestBatch(
  skipDeletionFlag integer := null
)
is
  batchId integer;
  execResultId integer;
-- runTestBatch
begin
  pkg_NewsletterCore.clearUnsubscribe('fakeemail1@newsletter.oramake.com');
  pkg_NewsletterCore.clearUnsubscribe('fakeemail2@newsletter.oramake.com');
  execResultId := pkg_Scheduler.execBatch(batchShortName => Test_BatchShortName);
  if execResultId <> pkg_Scheduler.True_ResultId then
    pkg_TestUtility.failTest('Batch execution was not successful');
  end if;
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка выполнения тестового батча'
      )
    , true
  );
end runTestBatch;

/* ifunc: getLastMessageId
  Получение максимального id сообщения.
*/
function getLastMessageId
return integer
is
  messageId integer;
-- getLastMessageId
begin
  select
    max(message_id)
  into
    messageId
  from
    ml_message
  ;
  return messageId;
end getLastMessageId;

/* proc: mergeProject
  Добавление тестового проекта.

  Параметры:
  messageTemplateText         - текст шаблона сообщений, который может
                                содержать макросы
  messageTemplatePath         - Файловый путь к тексту шаблона сообщения (
                                параметр, взаимноисключаемый с
                                messageTemplatePath)
*/
procedure mergeProject(
  messageTemplateText    clob := null
, messageTemplatePath    varchar2 := null
)
is
  pragma autonomous_transaction;
-- mergeProject
begin
  pkg_NewsletterCore.mergeProject(
    projectShortName    => 'TestProjectShortName'
  , projectName         => 'Тестовый проект'
  , subject             => Test_Subject
  , projectNameEn       => 'Test project'
  , batchShortName      => Test_BatchShortName
  , messageTemplateText => messageTemplateText
  , messageTemplatePath => messageTemplatePath
  , sender              => 'fakesender@oramake.com'
  );
  commit;
exception when others then
  rollback;
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка добавления тестового проекта'
      )
    , true
  );
end mergeProject;



/* group: Тесты */

/* iproc: checkMessage
  Проверка сообщения.
*/
procedure checkMessage(
  messageIdMin integer
, messageIdMax integer
)
is
  messageCount integer;
begin
  select
    count(1)
  into
    messageCount
  from
    ml_message
  where
    message_id between messageIdMin and messageIdMax
    and (
       to_char(message_text) like 'fake_body_1 macro_1_value macro_2_value TestProjectShortName fakeemail1@oramake.com http://www.create_your_newsletter.com/NewsletterCore/Unsubscribe?messageKey=%
recipient=fakeemail1@oramake.com
sender=fakesender@oramake.com'
       and recipient = 'fakeemail1@oramake.com'
       and sender = 'fakesender@oramake.com'
       or
       to_char(message_text) = 'fake_body_2'
       and recipient = 'fakeemail2@oramake.com'
       and sender = 'fakesender@oramake.com'
     )
  ;
  pkg_TestUtility.compareChar(
    actualString    => to_char(messageCount)
  , expectedString  => '2'
  , failMessageText => 'message count'
  );
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка проверки сообщения'
      )
    , true
  );
end checkMessage;

/* proc: basicTest
  Тест создания рассылки.
*/
procedure basicTest
is
  messageId1 integer;
  messageId2 integer;
-- basicTest
begin
  pkg_NewsletterCore.clearUnsubscribe(
    recipient => 'fakeemail1@oramake.com'
  );
  pkg_TestUtility.beginTest('basicTest');
  loadTestBatch();
  mergeProject(
    messageTemplateText =>
    'fake_body_1 $(macro1) $(macro2) $(projectShortName) $(email)'
  || ' http://www.create_your_newsletter.com/NewsletterCore/Unsubscribe?messageKey=$(messageKey)
recipient=$(email)
sender=$(sender)'
  );
  messageId1 := getLastMessageId();
  runTestBatch();
  messageId2 := getLastMessageId();
  checkMessage(messageIdMin => messageId1 + 1, messageIdMax => messageId2);
  pkg_TestUtility.endTest();
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка теста создания рассылки'
      )
    , true
  );
end basicTest;

/* proc: fileTemplateTest
  Тестирование рассылки из шаблона из файла.
*/
procedure fileTemplateTest
is

  messageId1 integer;
  messageId2 integer;

  /*
    Создание шаблона файла.
  */
  procedure prepareTemplateFile
  is
    templateText clob := 'fake_body_1 $(macro1) $(macro2) $(projectShortName) $(email)'
|| ' http://www.create_your_newsletter.com/NewsletterCore/Unsubscribe?messageKey=$(messageKey)
recipient=$(email)
sender=$(sender)'
    ;
  begin
    pkg_File.unloadClobToFile(
      fileText  => templateText
    , toPath    => getMessageTemplatePath()
    , writeMode => pkg_File.Mode_Rewrite
    );
  exception when others then
    raise_application_error(
      pkg_Error.ErrorStackInfo
      , logger.errorStack(
          'Ошибка создания шаблона файла'
        )
      , true
    );
  end prepareTemplateFile;

-- fileTemplateTest
begin
  pkg_NewsletterCore.clearUnsubscribe(
    recipient => 'fakeemail1@oramake.com'
  );
  pkg_TestUtility.beginTest('fileTemplateTest');
  prepareTemplateFile();
  loadTestBatch();
  mergeProject(
    messageTemplatePath => getMessageTemplatePath()
  );
  messageId1 := getLastMessageId();
  runTestBatch();
  messageId2 := getLastMessageId();
  checkMessage(messageIdMin => messageId1 + 1, messageIdMax => messageId2);
  pkg_TestUtility.endTest();
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка теста создания рассылки на основе шаблона'
      )
    , true
  );
end fileTemplateTest;

/* proc: unsubscribeTest
  Тест отписки.
*/
procedure unsubscribeTest
is

  messageId1 integer;
  messageId2 integer;
  resultUrl  varchar(1000);

  /*
    Получение ключа для отписки.
  */
  function getMessageKey
  return nsc_message.message_key%type
  is
    messageKey varchar(100);
  begin
    select
      to_char(message_text)
    into
      messageKey
    from
      ml_message
    where
      message_id > messageId1
      and recipient = 'fakeemail1@oramake.com'
    ;
    return
      messageKey;
  exception when others then
    raise_application_error(
      pkg_Error.ErrorStackInfo
      , logger.errorStack(
          'Ошибка получения ключа сообщения для описки (убедитесь что не'
          || ' запущены другие рассылки)'
        )
      , true
    );
  end getMessageKey;

  /*
    Проверка сообщения.
  */
  procedure checkMessage
  is
    messageCount integer;
  begin
    select
      count(1)
    into
      messageCount
    from
      ml_message
    where
      message_id between messageId1 + 1 and messageId2
      and sender = 'fakesender@oramake.com'
    ;
    pkg_TestUtility.compareChar(
      actualString    => to_char(messageCount)
    , expectedString  => '3'
    , failMessageText => 'message count'
    );
  end checkMessage;

-- unsubscribeTest
begin
  pkg_NewsletterCore.clearUnsubscribe(
    recipient => 'fakeemail1@oramake.com'
  );
  pkg_TestUtility.beginTest('unsubscribeTest');
  loadTestBatch();
  mergeProject(
    messageTemplateText => '$(messageKey)'
  );
  messageId1 := getLastMessageId();
  runTestBatch(skipDeletionFlag => 1);
  if not pkg_NewsletterCore.unsubscribe(
    messageKey => getMessageKey()
  , resultUrl  => resultUrl
  ) then
    pkg_TestUtility.failTest('unsubscribe returned false');
  end if;
  runTestBatch(skipDeletionFlag => 0);
  messageId2 := getLastMessageId();
  checkMessage();
  pkg_TestUtility.endTest();
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка теста отписки'
      )
    , true
  );
end unsubscribeTest;

/* proc: clearOldDataTest
  Тест очистки устаревших сообщений.
*/
procedure clearOldDataTest
is
  messageKey nsc_message.message_key%type;
  projectId integer;
  messageCount integer;
-- clearOldDataTest
begin
  pkg_TestUtility.beginTest('unsubscribeTest');
  select
    project_id
  into
    projectId
  from
    nsc_project
  where
    project_short_name = 'TestProjectShortName'
  ;
  select
    message_key
  into
    messageKey
  from
    nsc_message
  where
    project_id = projectId
    and rownum <= 1
  ;
  update
    nsc_message
  set
    date_ins = date '1900-01-01'
  where
    message_key = messageKey
  ;
  if sql%rowcount <> 1 then
    raise_application_error(
      pkg_Error.IllegalArgument
      , 'Нет данных для тестирования'
    );
  end if;
  pkg_NewsletterCore.clearOldData(dateBefore => date '1900-01-01' + 1/24/60/60);
  select
    count(1)
  into
    messageCount
  from
    nsc_message
  where
    message_key = messageKey
  ;
  pkg_TestUtility.compareChar(
    expectedString   => '0'
  , actualString     => messageCount
  , failMessageText  => 'message count'
  );
  pkg_TestUtility.endTest();
exception when others then
  raise_application_error(
    pkg_Error.ErrorStackInfo
    , logger.errorStack(
        'Ошибка очистки устаревших сообщений'
      )
    , true
  );
end clearOldDataTest;

end pkg_NewsletterCoreTest;
/



