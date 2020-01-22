-- Send newsletter messages
declare
  -- Имя проекта (если не задано, используется batchShortName)
  projectShortName varchar2(50) := pkg_Scheduler.getContextString(
    'ProjectShortName'
  );

begin
  pkg_NewsletterCore.sendMessage(
    projectShortName => projectShortName
  , batchShortName   =>
    case when
      projectShortName is null
    then
      batchShortName
    end
  );
end;
