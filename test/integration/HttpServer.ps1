# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [string]
    $CloudEventsModulePath,

    [Parameter(
        Mandatory = $true,
        ValueFromPipeline = $false,
        ValueFromPipelineByPropertyName = $false)]
    [ValidateNotNull()]
    [string]
    $ServerUrl
)

. (Join-Path $PSScriptRoot 'ProtocolConstants.ps1')

# Import SDK Module
Import-Module $CloudEventsModulePath

function Start-HttpCloudEventListener {
    <#
   .DESCRIPTION
   Starts a HTTP CloudEvent Listener on specified Url
#>

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [ValidateNotNull()]
        [string]
        $Url,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [scriptblock]
        $Handler
    )

    $listener = New-Object -Type 'System.Net.HttpListener'
    $listener.AuthenticationSchemes = [System.Net.AuthenticationSchemes]::Anonymous
    $listener.Prefixes.Add($Url)

    try {
        $listener.Start()

        $context = $listener.GetContext()

        # Read Input Stream
        $buffer = New-Object 'byte[]' -ArgumentList 1024
        $ms = New-Object 'IO.MemoryStream'
        $read = 0
        while (($read = $context.Request.InputStream.Read($buffer, 0, 1024)) -gt 0) {
            $ms.Write($buffer, 0, $read);
        }
        $bodyData = $ms.ToArray()
        $ms.Dispose()

        # Read Headers
        $headers = @{}
        for ($i = 0; $i -lt $context.Request.Headers.Count; $i++) {
            $headers[$context.Request.Headers.GetKey($i)] = $context.Request.Headers.GetValues($i)
        }

        $cloudEvent = ConvertFrom-HttpMessage -Headers $headers -Body $bodyData

        if ( $cloudEvent -ne $null ) {
            $Handler.Invoke($cloudEvent, $context.Response)
            $context.Response.Close();
        }
        else {
            $context.Response.StatusCode = [int]([System.Net.HttpStatusCode]::BadRequest)
            $context.Response.Close();
        }

    }
    catch {
        Write-Error $_
        $context.Response.StatusCode = [int]([System.Net.HttpStatusCode]::InternalServerError)
        $context.Response.Close();
    }
    finally {
        $listener.Stop()
    }
}

$global:serverStopRequested = $false
while ( -not $global:serverStopRequested ) {
    try {
        Start-HttpCloudEventListener -Url $ServerUrl -Handler {
            $requestCloudEvent = $args[0]
            $response = $args[1]
    
            # When CloudEvent Type is 'echo-structured' or 'echo-binary' the Server responds
            # with CloudEvent in corresponding content mode
            if ( $requestCloudEvent.Type -eq $script:EchoBinaryType -or `
                    $requestCloudEvent.Type -eq $script:EchoStructuredType ) {
    
                # Create Cloud Event for the response
                $cloudEvent = New-CloudEvent `
                    -Type $requestCloudEvent.Type `
                    -Source $script:ServerSource `
                    -Time (Get-Date) `
                    -Id $requestCloudEvent.Id
    
                # Add Data to the new Cloud Event
                $requestCloudEventJsonData = $requestCloudEvent | Read-CloudEventJsonData
                $requestCloudEventXmlData = $requestCloudEvent | Read-CloudEventXmlData -ConvertMode 'SkipAttributes'
                if ($requestCloudEventJsonData) {
                    $cloudEvent = $cloudEvent | Set-CloudEventJsonData `
                        -Data $requestCloudEventJsonData
                }
                elseif ($requestCloudEventXmlData) {
                    $cloudEvent = $cloudEvent | Set-CloudEventXmlData `
                        -Data $requestCloudEventXmlData `
                        -AttributesKeysInElementAttributes $false
                }
                else {
                    $requestCloudEventData = $requestCloudEvent | Read-CloudEventData
                    $cloudEvent = $cloudEvent | Set-CloudEventData `
                        -Data $requestCloudEventData `
                        -DataContentType $requestCloudEvent.DataContentType
                }
    
                # Convert Cloud Event to HTTP Response
                $contentMode = $requestCloudEvent.Type.TrimStart('echo-')
                $httpMessage = $cloudEvent | ConvertTo-HttpMessage -ContentMode $contentMode
    
                $response.Headers = New-Object 'System.Net.WebHeaderCollection'
                foreach ($keyValue in $httpMessage.Headers.GetEnumerator()) {
                    $response.Headers.Add($keyValue.Key, $keyValue.Value)
                }
                $response.ContentLength64 = $httpMessage.Body.Length
                $response.OutputStream.Write($httpMessage.Body, 0, $httpMessage.Body.Length)
                $response.StatusCode = [int]([System.Net.HttpStatusCode]::OK)
    
            }
            else {
                # No Content in all other cases
                $response.StatusCode = [int]([System.Net.HttpStatusCode]::NoContent)
            }
    
            if ( $requestCloudEvent.Type -eq $script:ServerStopType ) {
                # Server Stop is requested
                $global:serverStopRequested = $true
            }
        }
    } catch {
        Write-Error $_
        break
    }   
}