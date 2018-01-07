# BuildWizard
A powershell based SCCM build wizard.

The MDT build wixard provided by Microsoft is not very good in my opinion, especially if it needs extending.

This wizard is essentially a replacement for the one provided by MS but can be heavily modified. 

Requirements are MDT database with some small modifications to a table and injecting ADSI driver (https://deploymentresearch.com/Research/Post/508/Adding-ADSI-Support-for-WinPE-10). It means no webserver etc.. you talk directly to AD, though not supported by MS how often have you called MS for support on a boot image...?

Happy building!
