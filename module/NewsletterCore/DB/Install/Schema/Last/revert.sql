-- script: Install/Schema/Last/revert.sql
-- Отменяет установку модуля, удаляя созданные объекты схемы.


-- Пакеты

drop package pkg_NewsLetterCore
/


-- Внешние ключи

@oms-drop-foreign-key nsc_message
@oms-drop-foreign-key nsc_message_tmp
@oms-drop-foreign-key nsc_project
@oms-drop-foreign-key nsc_unsubscribe


-- Таблицы

drop table nsc_message
/
drop table nsc_message_tmp
/
drop table nsc_project
/
drop table nsc_unsubscribe
/


-- Последовательности

drop sequence nsc_message_seq
/
drop sequence nsc_project_seq
/
drop sequence nsc_unsubscribe_seq
/
