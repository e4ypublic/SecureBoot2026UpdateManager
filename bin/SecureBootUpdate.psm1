#get public and private function definition files
$public  = @( get-childitem -path $psscriptroot\public\*.ps1 -erroraction silentlycontinue )
$private = @( get-childitem -path $psscriptroot\private\*.ps1 -erroraction silentlycontinue )

# Dot source the files
foreach($import in @($public + $private)) {
    try {
        # Lightweight alternative to dotsourcing a function script
        . ([ScriptBlock]::Create([System.Io.File]::ReadAllText($import)))
    } catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $public.basename