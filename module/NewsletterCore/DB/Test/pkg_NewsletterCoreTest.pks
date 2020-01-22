create or replace package pkg_NewsletterCoreTest is
/* package: pkg_NewsletterCoreTest
  Пакет для тестирования модуля.

  SVN root: p/javaenterpriseplatform/svn/Module/NewsletterCore
*/


/* const: TemplatePath_OptionSName
  Имя опции для пути к шаблону
*/
TemplatePath_OptionSName constant varchar2(50) := 'TestTemplatePath';



/* group: Functions */



/* group: Вспомогательные функции */

/* pproc: setMessageTemplatePath
  Установка полного пути к тестовому шаблону файла сообщения.

  templatePath                - задание полного пути шаблона

  ( <body::setMessageTemplatePath>)
*/
procedure setMessageTemplatePath(
  templatePath varchar2
);

/* pproc: simpleNewsletter
  Добавление двух записей во временной таблице.

  ( <body::simpleNewsletter>)
*/
procedure simpleNewsletter;

/* pproc: deleteProject
  Удаление проекта.

  Параметры:
  projectShortName            - короткое наимеование проекта

  ( <body::deleteProject>)
*/
procedure deleteProject(
  projectShortName varchar2
);

/* pproc: runTestBatch
  Выполнение тестового батча.

  Параметры:
  skipDeletionFlag            - пропустить удаление батча.

  ( <body::runTestBatch>)
*/
procedure runTestBatch(
  skipDeletionFlag integer := null
);



/* group: Тесты */

/* pproc: basicTest
  Тест создания рассылки.

  ( <body::basicTest>)
*/
procedure basicTest;

/* pproc: fileTemplateTest
  Тестирование рассылки из шаблона из файла.

  ( <body::fileTemplateTest>)
*/
procedure fileTemplateTest;

/* pproc: unsubscribeTest
  Тест отписки.

  ( <body::unsubscribeTest>)
*/
procedure unsubscribeTest;

/* pproc: clearOldDataTest
  Тест очистки устаревших сообщений.

  ( <body::clearOldDataTest>)
*/
procedure clearOldDataTest;

end pkg_NewsletterCoreTest;
/
