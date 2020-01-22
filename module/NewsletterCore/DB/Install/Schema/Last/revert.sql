-- script: Install/Schema/Last/revert.sql
-- �������� ��������� ������, ������ ��������� ������� �����.


-- ������

drop package pkg_NewsLetterCore
/


-- ������� �����

@oms-drop-foreign-key nsc_message
@oms-drop-foreign-key nsc_message_tmp
@oms-drop-foreign-key nsc_project
@oms-drop-foreign-key nsc_unsubscribe


-- �������

drop table nsc_message
/
drop table nsc_message_tmp
/
drop table nsc_project
/
drop table nsc_unsubscribe
/


-- ������������������

drop sequence nsc_message_seq
/
drop sequence nsc_project_seq
/
drop sequence nsc_unsubscribe_seq
/
