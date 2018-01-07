# this is required in order to allow access to com objects whilst in OSD mode
REG EXPORT HKLM\SOFTWARE\Microsoft\COM3 $ENV:temp\SccmCom3.reg /u
REG ADD HKLM\SOFTWARE\Microsoft\COM3 /v REGDBVersion /t REG_BINARY /d 010000 /f