[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            RebootNodeIfNeeded =  $true
        }
    }
}
LCMConfig -OutputPath C:\LCMConfig
Set-DscLocalConfigurationManager -Path C:\LCMConfig