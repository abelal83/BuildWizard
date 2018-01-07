([ADSI]('WinNT://' + $ENV:computername + '/administrators,group')).psbase.Invoke('Add',([ADSI]'WinNT://server.com/svc_dskrolemgt').path)


