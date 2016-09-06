Import-Module Pester
Import-Module $PSScriptRoot\PSPrompt.psm1 -Force

Describe "New-PromptItemCollection" {
    
    BeforeAll {
        Set-Location $PSScriptRoot
    }

    It "Contains the PWd" {
        (New-PromptItemCollection -Items Pwd,TestAdmin).InvokeReturnAsIs() | Should Be "[$PSScriptRoot]"
    }

    It "Contains the git marker" {
        (New-PromptItemCollection -Items git).InvokeReturnAsIs().StartSWith("[GIT:") | Should Be $true
    }

    
    It "Contains the <line> marker" {
        (New-PromptItemCollection -Items "<line>").InvokeReturnAsIs() | Should Be "<line>"
    }
}