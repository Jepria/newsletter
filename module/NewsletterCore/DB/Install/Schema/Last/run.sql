-- script: Install/Schema/Last/run.sql
-- ��������� ��������� ��������� ������ �������� �����.


-- ���������� ��������� ������������ ��� ��������
@oms-set-indexTablespace.sql


-- �������

@oms-run nsc_message.tab
@oms-run nsc_message_tmp.tab
@oms-run nsc_project.tab
@oms-run nsc_unsubscribe.tab


-- Outline-����������� �����������

@oms-run nsc_message.con
@oms-run nsc_unsubscribe.con


-- ������������������

@oms-run nsc_message_seq.sqs
@oms-run nsc_project_seq.sqs
@oms-run nsc_unsubscribe_seq.sqs
