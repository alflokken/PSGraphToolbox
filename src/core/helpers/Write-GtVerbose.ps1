function Write-GtVerbose {
    param ([string]$Message )
    Write-Verbose "$(get-date -UFormat %H:%M:%S): $Message"
}