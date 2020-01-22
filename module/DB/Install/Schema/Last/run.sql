-- script: Install/Schema/Last/run.sql
-- Выполняет установку последней версии объектов схемы.


-- Определяем табличное пространство для индексов
@oms-set-indexTablespace.sql


-- Таблицы

@oms-run nsc_message.tab
@oms-run nsc_message_tmp.tab
@oms-run nsc_project.tab
@oms-run nsc_unsubscribe.tab


-- Outline-ограничения целостности

@oms-run nsc_message.con
@oms-run nsc_unsubscribe.con


-- Последовательности

@oms-run nsc_message_seq.sqs
@oms-run nsc_project_seq.sqs
@oms-run nsc_unsubscribe_seq.sqs
