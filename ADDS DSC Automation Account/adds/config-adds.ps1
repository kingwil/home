Configuration config-adds
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc

    $Credential = Get-AutomationPSCredential 'Credential'
    $SafeModePassword = Get-AutomationPSCredential 'Credential'
    
    node 'localhost'
    {
        WindowsFeature 'ADDS'
        {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature 'RSAT'
        {
            Name   = 'RSAT-AD-PowerShell'
            Ensure = 'Present'
        }

        ADDomain 'contoso.com'
        {
            DomainName                    = 'contoso.com'
            Credential                    = $Credential
            SafemodeAdministratorPassword = $SafeModePassword
            ForestMode                    = 'WinThreshold'
        }

        WaitForADDomain 'contoso.com'
        {
            DomainName           = 'contoso.com'
            RestartCount         = 2

        }

        ADOrganizationalUnit 'ADSyncOU'
        {
            DependsOn                       = '[WaitForADDomain]contoso.com'
            Name                            = 'AAD Sync Users'
            Path                            = 'DC=contoso,DC=com'
            Ensure                          = 'Present'
        }

        ADUser 'Contoso\DeliaCec'
        {
            DependsOn           = '[ADOrganizationalUnit]ADSyncOU'
            Ensure              = 'Present'
            UserName            = 'DeliaCec'
            GivenName           = 'Cecila'
            Surname             = 'Delia'
            CommonName          = 'Cecila Delia'
            EmailAddress        = 'DeliaCec@contoso.com'
            UserPrincipalName   = 'DeliaCec@contoso.com'
            Password            = $Credential
            PasswordNeverResets = $true
            DomainName          = 'contoso.com'
            Path                = 'OU=AAD Sync Users,DC=contoso,DC=com'
        }

        ADUser 'Contoso\CopenAnn' 
        {
            DependsOn           = '[ADOrganizationalUnit]ADSyncOU'
            Ensure              = 'Present'
            UserName            = 'CopenAnn'
            GivenName           = 'Anna'
            Surname             = 'Copenhaver'
            CommonName          = 'Anna Copenhaver'
            EmailAddress        = 'CopenAnn@contoso.com'
            UserPrincipalName   = 'CopenAnn@contoso.com'
            Password            = $Credential
            PasswordNeverResets = $true
            DomainName          = 'contoso.com'
            Path                = 'OU=AAD Sync Users,DC=contoso,DC=com'
        }

        ADUser 'Contoso\LivseAug' 
        {
            DependsOn           = '[ADOrganizationalUnit]ADSyncOU'
            Ensure              = 'Present'
            UserName            = 'LivseAug'
            GivenName           = 'Augusta'
            Surname             = 'Livsey'
            CommonName          = 'Augusta Livsey'
            EmailAddress        = 'LivseAug@contoso.com'
            UserPrincipalName   = 'LivseAug@contoso.com'
            Password            = $Credential
            PasswordNeverResets = $true
            DomainName          = 'contoso.com'
            Path                = 'OU=AAD Sync Users,DC=contoso,DC=com'
        }

        ADUser 'Contoso\CardoJer'
        {
            DependsOn           = '[ADOrganizationalUnit]ADSyncOU'
            Ensure              = 'Present'
            UserName            = 'CardoJer'
            GivenName           = 'Jeremiah'
            Surname             = 'Cardoso'
            CommonName          = 'Jeremiah Cardoso'
            EmailAddress        = 'CardoJer@contoso.com'
            UserPrincipalName   = 'CardoJer@contoso.com'
            Password            = $Credential
            PasswordNeverResets = $true
            DomainName          = 'contoso.com'
            Path                = 'OU=AAD Sync Users,DC=contoso,DC=com'
        }

        ADUser 'Contoso\EdlinSop' 
        {
            DependsOn           = '[ADOrganizationalUnit]ADSyncOU'
            Ensure              = 'Present'
            UserName            = 'EdlinSop'
            GivenName           = 'Sophie'
            Surname             = 'Edlin'
            CommonName          = 'Sophie Edlin'
            EmailAddress        = 'EdlinSop@contoso.com'
            UserPrincipalName   = 'EdlinSop@contoso.com'
            Password            = $Credential
            PasswordNeverResets = $true
            DomainName          = 'contoso.com'
            Path                = 'OU=AAD Sync Users,DC=contoso,DC=com'
        }

        ADUser 'Contoso\MaderKei' 
        {
            DependsOn           = '[ADOrganizationalUnit]ADSyncOU'
            Ensure              = 'Present'
            UserName            = 'MaderKei'
            GivenName           = 'Keitha'
            Surname             = 'Madero'
            CommonName          = 'Keitha Madero'
            EmailAddress        = 'MaderKei@contoso.com'
            UserPrincipalName   = 'MaderKei@contoso.com'
            Password            = $Credential
            PasswordNeverResets = $true
            DomainName          = 'contoso.com'
            Path                = 'OU=AAD Sync Users,DC=contoso,DC=com'
        }

        ADUser 'Contoso\FullaSue' 
        {
            DependsOn           = '[ADOrganizationalUnit]ADSyncOU'
            Ensure              = 'Present'
            UserName            = 'FullaSue'
            GivenName           = 'Sue'
            Surname             = 'Fullam'
            CommonName          = 'Sue Fullam'
            EmailAddress        = 'FullaSue@contoso.com'
            UserPrincipalName   = 'FullaSue@contoso.com'
            Password            = $Credential
            PasswordNeverResets = $true
            DomainName          = 'contoso.com'
            Path                = 'OU=AAD Sync Users,DC=contoso,DC=com'
        }

        ADUser 'Contoso\WinkeAni' 
        {
            DependsOn           = '[ADOrganizationalUnit]ADSyncOU'
            Ensure              = 'Present'
            UserName            = 'WinkeAni'
            GivenName           = 'Anisa'
            Surname             = 'Winkel'
            CommonName          = 'Anisa Winkel'
            EmailAddress        = 'WinkeAni@contoso.com'
            UserPrincipalName   = 'WinkeAni@contoso.com'
            Password            = $Credential
            PasswordNeverResets = $true
            DomainName          = 'contoso.com'
            Path                = 'OU=AAD Sync Users,DC=contoso,DC=com'
        }

        ADUser 'Contoso\RodarRic' 
        {
            DependsOn           = '[ADOrganizationalUnit]ADSyncOU'
            Ensure              = 'Present'
            UserName            = 'RodarRic'
            GivenName           = 'Richard'
            Surname             = 'Rodarte'
            CommonName          = 'Richard Rodarte'
            EmailAddress        = 'RodarRic@contoso.com'
            UserPrincipalName   = 'RodarRic@contoso.com'
            Password            = $Credential
            PasswordNeverResets = $true
            DomainName          = 'contoso.com'
            Path                = 'OU=AAD Sync Users,DC=contoso,DC=com'
        }

        ADUser 'Contoso\DemarMeg' 
        {
            DependsOn           = '[ADOrganizationalUnit]ADSyncOU'
            Ensure              = 'Present'
            UserName            = 'DemarMeg'
            GivenName           = 'Meg'
            Surname             = 'Demaris'
            CommonName          = 'Meg Demaris'
            EmailAddress        = 'DemarMeg@contoso.com'
            UserPrincipalName   = 'DemarMeg@contoso.com'
            Password            = $Credential
            PasswordNeverResets = $true
            DomainName          = 'contoso.com'
            Path                = 'OU=AAD Sync Users,DC=contoso,DC=com'
        }

    }
}