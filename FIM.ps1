Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline-If-Already-Exists() {
    $baselineExists = Test-Path -Path .\FIM\baseline.txt

    if ($baselineExists) {
        #delete it
        Remove-Item -Path .\FIM\baseline.txt
        } 

}
Write-Host ""
Write-Host "Welcome! I am the File Integrity Monitor! What would you like to do?"
Write-Host ""
Write-Host "A) Collect a new baseline"
Write-Host "B) Begin monitoring files with previously saved baseline"
Write-Host ""

$response = Read-Host -Prompt "Please enter 'A' or 'B'"
Write-Host ""



if ($response -eq "A".ToUpper()) {
    #Delete baseline.txt if it already exists
    Erase-Baseline-If-Already-Exists

    #Calculate Hash from the target files and store in baseline.txt
    
    #Collect all files in the target folder
    $files = Get-ChildItem -Path .\FIM

    #For file, calculate hash and write to baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\FIM\baseline.txt -Append
    }

}

elseif ($response -eq "B".ToUpper()) {

    $fileHashDictionary = @{}

    #Load file|hash from baseline.txt and store them in a dictionary
    $filePathsandHashes = Get-Content -Path .\FIM\baseline.txt
    
    foreach ($f in $filePathsandHashes) {
         $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }


    #Begin monitoring files with saved baseline
    while ($true) {
        Start-Sleep -Seconds 1
        
        $files = Get-ChildItem -Path .\FIM

    #For file, calculate hash and write to baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        #"$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\FIM\baseline.txt -Append

        if ($fileHashDictionary[$hash.Path] -eq $null) {
        #A file has been created!! Notify the user
            Write-Host "$($hash.Path) has been created!" -ForegroundColor Cyan
        }
        else {

            #A file has been modified
            if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
            #file not changed
            }

            else {
            #file compromised
            Write-Host "$($hash.Path) has changed!!" -ForegroundColor Red
            Send-MailMessage
            }
        }
    }

        foreach ($key in $fileHashDictionary.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if (-Not $baselineFileStillExists) {
                # One of the baseline files must have been deleted, notify the user
                Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed -BackgroundColor Gray
            }
        }
    }
}