[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$Url
)

try {
    # Use -UseBasicParsing to avoid issues with IE engine dependency
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing
    # Write the raw content to the standard output stream
    Write-Output $response.Content
}
catch {
    # Write detailed error information to the error stream
    Write-Error "Failed to fetch URL '$_'. Exception: $($_.Exception.Message)"
    # Exit with a non-zero status code to indicate failure
    exit 1
}
