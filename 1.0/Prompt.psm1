
function New-PromptItemCollection {
    param(
        [Parameter()]
        [ValidateSet("TestAdmin","LastCommandDuration","Pwd","VisualStudio","hg","git","<line>")]
        [string[]]$Items
    )
    process {
        $global:promptItems = [System.Collections.ArrayList]::New()
         
        # Accumulate alll partials script in an scriptblock array.
        foreach($item in $Items) {
            switch($item) {       
                "TestAdmin" {
                    $promptItems.Add([scriptblock]{
                        if(!(Test-Path Variable:/TestAdminUserResult)) {
                            $global:TestAdminUserResult = Test-AdminUser
                        }
                        if($global:TestAdminUserResult) { "[ADMIN]" }
                    }) | Out-Null
                }
                
                "LastCommandDuration" {
                    $promptItems.Add([scriptblock]{
                        $lastResultCode = $?
                        $lastCommand = Get-History -Count 1
                        if($lastCommand) {
                            $lastTs = $lastCommand.EndExecutionTime.Subtract($lastCommand.StartExecutionTime)
                        } else {
                            $lastTs = [timespan]::FromMilliseconds(0)
                        }
                        if($lastCommand) { "[`$?:$lastResultCode ms:$([int]($lastTs.TotalMilliseconds))]" }
                    })| Out-Null
                }
                
                "Pwd" {
                    $promptItems.Add([scriptblock]{
                        "[$($executionContext.SessionState.Path.CurrentLocation.Path.Replace('Microsoft.PowerShell.Core\FileSystem::',''))]"
                    })| Out-Null
                }
                
                "VisualStudio" {
                    $promptItems.Add([scriptblock]{
                         if((Test-Path *.sln) -or (Test-Path *.csproj) -or (Test-Path *.proj)) { "[VS]" }
                    })| Out-Null
                }

                "hg" {
                    $promptItems.Add([scriptblock]{
                        if((Get-ItemContainersToRoot $PWD | ForEach-Object { Test-Path -PathType Container -Path (Join-Path $_.FullName ".hg") }) -contains $true) { "[HG]" }
                    })| Out-Null
                }

                "git" {
                    $promptItems.Add([scriptblock]{
                         if((Get-ItemContainersToRoot $PWD | ForEach-Object { Test-Path -PathType Container -Path (Join-Path $_.FullName ".git") }) -contains $true) { 
                            $currentBranch = (git branch | Where-Object { $_.StartsWith("*") }).TrimStart("* ")
                            "[GIT:$currentBranch]" 
                        }
                    })| Out-Null
                }
                "<line>" {
                    $promptItems += ([scriptblock]{
                        "<line>" # substituted lateron
                    })| Out-Null
                }

                "PS" {
                     $promptItems += ([scriptblock]{
                         if(Test-Path *.ps*) { "[PS]" }
                    })| Out-Null
                }

                "LastExitCode" {
                    $promptItems.Add([scriptblock]{
                        "[W32:$LASTEXITCODE]"
                    })| Out-Null
                }
                "Time" {
                    $promptItems.Add([scriptblock]{
                        "[$(Get-Date -Format 'HH:mm:ss')]"
                    })| Out-Null
                }
            }
        }

        # Create a script block which invokes all prompt item script blocks

        return ([scriptblock]{
            foreach($promptItem in $global:promptItems) {
                $promptItem.InvokeReturnAsIs()
            }
        })
    }
}
