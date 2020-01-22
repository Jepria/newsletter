-- script: Test/run.sql
-- Выполняет все тесты.
--
-- Используемые макромеременные:
-- loggingLevelCode           - уровень логирования ( по-умолчанию WARN)
--

@oms-default processName ""
@oms-default loggingLevelCode WARN

set feedback off

declare
  loggingLevelCode varchar2(10) := '&loggingLevelCode';
begin
  lg_logger_t.getRootLogger().setLevel(
    coalesce(loggingLevelCode, pkg_Logging.Warning_LevelCode)
  );
end;
/

@oms-run Test/AutoTest/basic.sql
@oms-run Test/AutoTest/file-template-test.sql
@oms-run Test/AutoTest/unsubscribe-test.sql
@oms-run Test/AutoTest/clear-old-data.sql


set feedback on
