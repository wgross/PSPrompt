function script:gitExe {
    <#
    .SYNOPSIS
        Retrieves the path to the dot net core cli.
        The value is cached.
    #>
    if($script:gitExePath) {
        return $script:gitExePath
    }            
    return ($script:gitExePath = (Get-Command -Name git.exe -ErrorAction SilentlyContinue).Path)
}

if(gitExe) {
    "Found git.exe at $(gitExe)" | Write-Host -ForegroundColor Green
}

function New-PromptItemFactory {
    param(
        [Parameter()]
        [ValidateSet("TestAdmin","LastCommandDuration","Pwd","VisualStudio","hg","git","Powershell","Time","LastExitCode","LINE")]
        [string[]]$Items
    )
    process {
       
        $global:promptItems = @()
         
        # Add script block to array of scriptblocks to add
        
        foreach($item in $Items) {
            switch($item) {

                "LINE" {
                    $global:promptItems += [scriptblock]{
                        "<line>"
                    }
                }

                "Pwd" {
                    $global:promptItems += [scriptblock]{
                        "[$($PWD.ProviderPath)]"
                    }
                }
                
                "TestAdmin" {
                    
                    if(!(Test-Path Variable:/TestAdminUserResult)) {
                        $global:TestAdminUserResult = Test-AdminUser
                    }

                    $global:promptItems += [scriptblock]{
                        if($global:TestAdminUserResult) { "[ADMIN]" }
                    }
                }
                
                "LastCommandDuration" {
                    $global:promptItems += [scriptblock]{
                        $lastCommandResult = $?
                        $lastCommandHistoryItem = Get-History -Count 1
                        if($lastCommandHistoryItem) {
                            $lastTs = $lastCommandHistoryItem.EndExecutionTime.Subtract($lastCommandHistoryItem.StartExecutionTime)
                        } else {
                            $lastTs = [timespan]::FromMilliseconds(0)
                        }
                        "[`$?:$lastCommandResult ms:$([int]($lastTs.TotalMilliseconds))]" 
                    }
                }

                "git" {
                    $global:promptItems += [scriptblock]{
                        if(gitExe) {
                            if((Get-ItemContainersToRoot -Path $PWD | ForEach-Object -Process { Test-Path -PathType Container -Path (Join-Path -Path $_.FullName -ChildPath ".git") }) -contains $true) { 
                                $currentBranch = & (gitExe) branch | Where-Object -FilterScript { $_.StartsWith("*") }
                                if(!$currentBranch) {
                                    "[GIT:]" | Write-Output
                                } else {
                                    $currentBranch = $currentBranch.TrimStart("* ")
                                    "[GIT:$currentBranch]" | Write-Output
                                }
                            }
                        }
                    }
                }
                
                "hg" {
                    $global:promptItems += [scriptblock]{
                        if((Get-ItemContainersToRoot $PWD | ForEach-Object { 
                            Test-Path -PathType Container -Path (Join-Path $_.FullName ".hg") 
                        }) -contains $true) { "[HG]" }
                    }
                }

                "VisualStudio" {
                    $global:promptItems += [scriptblock]{
                        if((Test-Path -Path *.sln) -or (Test-Path -Path *.csproj) -or (Test-Path -Path *.proj)) { "[VS]" }
                    }
                }

                "Powershell" {
                    $global:promptItems += [scriptblock]{
                        if(Test-Path *.ps*) { "[PS]" }
                    }
                }

                "Time" {
                    $global:promptItems += [scriptblock]{
                        "[$(Get-Date -Format 'HH:mm:ss')]"
                    }
                }

                "LastExitCode" {
                    $global:promptItems += [scriptblock]{
                        if($LASTEXITCODE) { 
                            "[W32:$LASTEXITCODE]" 
                        }
                    }
                }
            }
        }

        # Create a script block which invokes all prompt item script blocks

        return [scriptblock]{
            foreach($promptItem in $promptItems) {
                $promptItem.InvokeReturnAsIs()
            }
        }
    }
}

function Format-PromptItemFactory  {
    <#
    .SYNOPSIS
        Formats the prompt items as line of the length of the terminals width
    .DESCRIPTION
        The prompt item '<line>' is substiturted with as many '_' to fill the gap in the middle and
        pushes to folling propet items till they reach the right side if the terminal
    #>
    param(
        [Parameter(ValueFromPipeline)]
        [scriptblock]$PromptItemFactory
    )
    process {
    
        $line = [string]::Join(" ",$PromptItemFactory.InvokeReturnAsIs())
        $line = $line.Replace("<line>",$('_' * [System.Math]::Max(0,($host.ui.RawUI.WindowSize.Width-($line.Length-5)))))
        $line | Write-Host -ForegroundColor DarkGray
    }
}