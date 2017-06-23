To be able to upload files through selenium, a configuration is necessary : http://cakebaker.wordpress.com/2006/03/29/file-upload-with-selenium/


a) The Mozilla must have the configuration option
"signed.applets.codebase_principal_support" set to the value "true".
This allows non-signed scripts to request higher privileges.

b) Selenium must request higher privileges which can be handled in
different places. To allow typing into file fields you can include this
call:

netscape.security.PrivilegeManager.enablePrivilege("UniversalFileRead");

in the file selenium-api.js in function Selenium.prototype.doType. This
enables uploading local files.




Also, it is necessary to disable all caching in Firefox :

about:config, search for cache, and set to false the network, memory and disk caching