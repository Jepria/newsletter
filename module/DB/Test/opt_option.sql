declare

  optionList opt_option_list_t := opt_option_list_t(
    moduleName => pkg_NewsletterCore.Module_Name
  );

begin
  optionList.addString(
    optionShortName => pkg_NewsletterCoreTest.TemplatePath_OptionSName
    , optionName => 'Полное путь к файлу тестового шаблона'
  );
end;
/
commit;

