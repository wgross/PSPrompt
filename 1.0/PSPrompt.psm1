
function New-PromptItemFactory {
    param(
        [Parameter()]
        [ValidateSet("TestAdmin","LastCommandDuration","Pwd","VisualStudio","hg","git","Powershell","Time","LastExitCode","LINE")]
        [string[]]$Items
    )
    process {
        function getItemContainersToRoot {
            param(
                [string]$Path
            )
            $parentItem = Get-Item $Path
            while($parentItem) { 

                $parentItem
                $parentItem = (Get-Item $parentItem.FullName).Parent

            }
        }

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
                        "[$PWD]"
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
                        $last = $?
                        $global:lastCommand = Get-History -Count 1
                        if($lastCommand) {
                            $lastTs = $lastCommand.EndExecutionTime.Subtract($lastCommand.StartExecutionTime)
                        } else {
                            $lastTs = [timespan]::FromMilliseconds(0)
                        }
                        if($global:lastCommand) { 
                            "[`$?:$last ms:$([int]($lastTs.TotalMilliseconds))]" 
                        }
                    }
                }

                "git" {
                    $global:promptItems += [scriptblock]{
                        if((getItemContainersToRoot $PWD | ForEach-Object { Test-Path -PathType Container -Path (Join-Path $_.FullName ".git") }) -contains $true) { 
                            $currentBranch = git branch | Where-Object { $_.StartsWith("*") }
                            $currentBranch = $currentBranch.TrimStart("* ")
                            "[GIT:$currentBranch]" 
                        }
                    }
                }

                
                "hg" {
                    $global:promptItems += [scriptblock]{
                        if((getItemContainersToRoot $PWD | ForEach-Object { 
                            Test-Path -PathType Container -Path (Join-Path $_.FullName ".hg") 
                        }) -contains $true) { "[HG]" }
                    }
                }

                "VisualStudio" {
                    $global:promptItems += [scriptblock]{
                        if((Test-Path *.sln) -or (Test-Path *.csproj) -or (Test-Path *.proj)) { "[VS]" }
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
        [string]::Join(" ",$PromptItemFactory.InvokeReturnAsIs()).Replace("<line>",[string]::Empty) | Write-Host -ForegroundColor DarkGray
    }
}