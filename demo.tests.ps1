Describe "az role assignment list is invoked" {
    BeforeAll {
        $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) ".github\actions\templates\powershell\storage-containers\1-tgt-st-containers-get.ps1"

        $env:GITHUB_OUTPUT = "test-github-output.txt"
        $env:TGT_SUB_ID = "test-sub"
        $env:TGT_RG_NAME = "test-rg"
        $env:TGT_ST_NAME = "test-sa"
        $env:SRC_FOLDER_PATH = ".\testconfig\innovation\teststorage"

        # Mock all az commands that the script might call
        Mock az {
            if (($args -join " ") -like "*storage account keys list*") {
                Write-Host "MOCK HIT: storage account keys"
                return '"mock-storage-key-123"'
            }
            elseif (($args -join " ") -like "*storage container list*") {
                Write-Host "MOCK HIT: storage container list"
                return '[{"name": "container1"}, {"name": "container2"}]'
            }
            elseif (($args -join " ") -like "*role assignment list*") {
                Write-Host "MOCK HIT: az role assignment list"
                return '[{"roleDefinitionName": "Storage Blob Data Reader", "scope": "/subscriptions/test-sub/resourceGroups/test-rg"}]'
            }
            else {
                Write-Host "MOCK HIT: unknown az command: $($args -join ' ')"
                return '[]'
            }
        }

        # Support mocks
        Mock Test-Path { return $true }
        Mock Get-Item { return @{ FullName = "testconfig/innovation/teststorage/file1.yaml" } }
        Mock Get-ChildItem { return @(@{ FullName = "testconfig/innovation/teststorage/file1.yaml" }) }
        Mock Write-Output { }
        Mock Out-File { }
        Mock Get-ChildItem {
            return @(@{ FullName = "testconfig/innovation/teststorage/file1.txt" })
        }
        Mock Get-Item { return @{ FullName = "testconfig/innovation/teststorage/file1.txt" } }   
 
    }

    It "Should call az role assignment list once" {
        & $scriptPath
        Assert-MockCalled az -ParameterFilter {
            ($args -join " ") -like "*role assignment list*"
        } -Times 1
    }
    It "Should call az storage account keys list once" {
        & $scriptPath
        Assert-MockCalled az -ParameterFilter {
            ($args -join " ") -like "*storage account keys list*"
        } -Times 1
    }
    It "Should throw when .txt file is returned by Get-ChildItem" {  
        { & $scriptPath } | Should -Throw "Unsupported file type: .txt"
    }
    It "Should not throw when .yaml file is returned by Get-ChildItem" {  
        { & $scriptPath } | Should -Not -Throw
    }
}
