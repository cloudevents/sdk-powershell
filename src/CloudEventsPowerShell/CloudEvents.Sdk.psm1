$xmlDataSerilizationLibPath = Join-Path (Join-Path $PSScriptRoot 'dataserialization') 'xml.ps1'
. $xmlDataSerilizationLibPath

function New-CloudEvent {
<#
   .SYNOPSIS
   This function creates a new cloud event.


   .DESCRIPTION
   This function creates a new cloud event object with the provided parameters.
   The result cloud event object has no data. Use Add-CloudEvent* functions to
   add data to the cloud event object.

   .PARAMETER Type
   Specifies the 'type' attribute of the cloud event.

   .PARAMETER Source
   Specifies the 'source' attribute of the cloud event.

   .PARAMETER Id
   Specifies the 'id' attribute of the cloud event.

   .PARAMETER Time
   Specifies the 'time' attribute of the cloud event.

   .EXAMPLE
   New-CloudEvent -Type 'com.example.object.deleted.v2' -Source 'mailto:cncf-wg-serverless@lists.cncf.io' -Id '6e8bc430-9c3a-11d9-9669-0800200c9a66' -Time (Get-Date)

   Creates a cloud event with Type, Source, Id, and Time
#>

[CmdletBinding()]
param(
   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [string]
   $Type,

   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [System.Uri]
   $Source,

   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [string]
   $Id,

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [DateTime]
   $Time
)

PROCESS {
   $cloudEvent = New-Object `
      -TypeName 'CloudNative.CloudEvents.CloudEvent' `
      -ArgumentList @(
         $Type,
         $Source,
         $Id,
         $Time,
         @())

   Write-Output $cloudEvent
}
}

#region Add Data Functions
function Add-CloudEventData {
<#
   .SYNOPSIS
   This function adds data to a cloud event.

   .DESCRIPTION
   This function adds data to a cloud event object with the provided parameters.

   .PARAMETER CloudEvent
   Specifies the cloud event object to add data to.

   .PARAMETER Data
   Specifies the data object that is added to the cloud event 'data' attribute.

   .PARAMETER DataContentType
   Specifies the 'datacontenttype' attribute of the cloud event.


   .EXAMPLE
   $cloudEvent = New-CloudEvent -Type 'com.example.object.deleted.v2' -Source 'mailto:cncf-wg-serverless@lists.cncf.io' -Id '6e8bc430-9c3a-11d9-9669-0800200c9a66' -Time (Get-Date)
   $cloudEvent | Add-CloudEventData -Data '<much wow="xml"/>' -DataContentType 'application/xml'

   Adds xml data to the cloud event
#>

[CmdletBinding()]
param(
   [Parameter(Mandatory = $true,
              ValueFromPipeline = $true)]
   [ValidateNotNullOrEmpty()]
   [CloudNative.CloudEvents.CloudEvent]
   $CloudEvent,

   [Parameter(Mandatory = $true,
              ValueFromPipeline = $false)]
   [ValidateNotNullOrEmpty()]
   [object]
   $Data,

   # CloudEvent 'datacontenttype' attribute. Content type of the 'data' attribute value.
   # This attribute enables the data attribute to carry any type of content, whereby
   # format and encoding might differ from that of the chosen event format.
   [Parameter(Mandatory = $false,
              ValueFromPipeline = $false)]
   [string]
   $DataContentType)

PROCESS {

    # https://github.com/cloudevents/spec/blob/master/spec.md#datacontenttype
   $contentType = New-Object `
      -TypeName 'System.Net.Mime.ContentType' `
      -ArgumentList ($DataContentType)

   $cloudEvent.Data = $Data
   $cloudEvent.DataContentType = $dataContentType

   Write-Output $CloudEvent
}

}

function Add-CloudEventJsonData {
<#
   .SYNOPSIS
   This function adds JSON format data to a cloud event.

   .DESCRIPTION
   This function converts a PowerShell hashtable to JSON format data and adds it to a cloud event.

   .PARAMETER CloudEvent
   Specifies the cloud event object to add data to.

   .PARAMETER Data
   Specifies the PowerShell hashtable object that is added as JSON to the cloud event 'data' attribute.
   The 'datacontenttype' attribute is set to 'applicaiton/json'


   .EXAMPLE
   $cloudEvent = New-CloudEvent -Type 'com.example.object.deleted.v2' -Source 'mailto:cncf-wg-serverless@lists.cncf.io' -Id '6e8bc430-9c3a-11d9-9669-0800200c9a66' -Time (Get-Date)
   $cloudEvent | Add-CloudEventJsonData -Data @{ 'key1' = 'value1'; 'key2' = 'value2'; }

   Adds JSON data to the cloud event
#>

[CmdletBinding()]
param(
   [Parameter(Mandatory = $true,
              ValueFromPipeline = $true)]
   [ValidateNotNullOrEmpty()]
   [CloudNative.CloudEvents.CloudEvent]
   $CloudEvent,

   [Parameter(Mandatory = $true,
              ValueFromPipeline = $false)]
   [ValidateNotNull()]
   [Hashtable]
   $Data,

   [Parameter(Mandatory = $false,
              ValueFromPipeline = $false)]
   [int]
   $Depth = 3)

PROCESS {

    # DataContentType is set to 'application/json'
    # https://github.com/cloudevents/spec/blob/master/spec.md#datacontenttype
   $dataContentType = New-Object `
      -TypeName 'System.Net.Mime.ContentType' `
      -ArgumentList ([System.Net.Mime.MediaTypeNames+Application]::Json)

   $cloudEvent.DataContentType = $dataContentType
   $cloudEvent.Data = ConvertTo-Json -InputObject $Data -Depth $Depth

   Write-Output $CloudEvent
}

}

function Add-CloudEventXmlData {
<#
   .SYNOPSIS
   This function adds XML format data to a cloud event.

   .DESCRIPTION
   This function converts a PowerShell hashtable to XML format data and adds it to a cloud event.

   .PARAMETER CloudEvent
   Specifies the cloud event object to add data to.

   .PARAMETER Data
   Specifies the PowerShell hashtable object that is added as XML to the cloud event 'data' attribute.
   The 'datacontenttype' attribute is set to 'applicaiton/xml'

   .PARAMETER AttributesKeysInElementAttributes
   Specifies how to format the XML. If specified and the input Data hashtable has pairs of 'Attributes', 'Value' keys
   creates XML element with attributes, otherwise each key is formatted as XML element.
   If true
   @{'root' = @{'Attributes' = @{'att1' = 'true'}; 'Value' = 'val-1'}} would be '<root att1="true">val-1</root>'
   Otherwise
   @{'root' = @{'Attributes' = @{'att1' = 'true'}; 'Value' = 'val-1'}} would be '<root><Attributes><att1>true</att1></Attributes><Value>val-1</Value></root>'


   .EXAMPLE
   $cloudEvent = New-CloudEvent -Type 'com.example.object.deleted.v2' -Source 'mailto:cncf-wg-serverless@lists.cncf.io' -Id '6e8bc430-9c3a-11d9-9669-0800200c9a66' -Time (Get-Date)
   $cloudEvent | Add-CloudEventXmlData -Data @{ 'key1' = 'value1'; 'key2' = 'value2'; } -AttributesKeysInElementAttributes $true

   Adds XML data to the cloud event
#>

[CmdletBinding()]
param(
   [Parameter(Mandatory = $true,
              ValueFromPipeline = $true)]
   [ValidateNotNullOrEmpty()]
   [CloudNative.CloudEvents.CloudEvent]
   $CloudEvent,

   [Parameter(Mandatory = $true,
              ValueFromPipeline = $false)]
   [ValidateNotNull()]
   [Hashtable]
   $Data,

   [Parameter(Mandatory = $true)]
   [bool]
   $AttributesKeysInElementAttributes)

PROCESS {

    # DataContentType is set to 'application/xml'
   $dataContentType = New-Object `
      -TypeName 'System.Net.Mime.ContentType' `
      -ArgumentList ([System.Net.Mime.MediaTypeNames+Application]::Xml)

   $cloudEvent.DataContentType = $dataContentType
   $cloudEvent.Data = ConvertTo-CEDataXml -InputObject $Data -AttributesKeysInElementAttributes $AttributesKeysInElementAttributes

   Write-Output $CloudEvent
}

}
#endregion Add Data Functions

#region Read Data Functions
function Read-CloudEventData {
<#
   .SYNOPSIS
   This function gets the data from a cloud event.

   .DESCRIPTION
   This function gets the data as-is from a cloud event. It is equiualent of accessing the Data property of a CloudEvent object

   .PARAMETER CloudEvent
   Specifies the cloud event object to get data from.

   .EXAMPLE
   $cloudEvent = ConvertFrom-HttpMessage -Headers $httpResponse.Headers -Body $httpResponse.Content
   $cloudEvent | Read-CloudEventData

   Reads data from a cloud event received on the http response
#>

[CmdletBinding()]
param(
   [Parameter(Mandatory = $true,
              ValueFromPipeline = $true)]
   [ValidateNotNullOrEmpty()]
   [CloudNative.CloudEvents.CloudEvent]
   $CloudEvent
)

PROCESS {
   Write-Output $CloudEvent.Data
}

}

function Read-CloudEventJsonData {
<#
   .SYNOPSIS
   This function gets JSON fromat data from a cloud event as a PowerShell hashtable.

   .DESCRIPTION
   This function gets the data from a cloud event and converts it to a PowerShell hashtable.
   If the cloud event datacontenttype is not 'application/json' nothing is returned.

   .PARAMETER CloudEvent
   Specifies the cloud event object to get data from.

   .PARAMETER Depth
   Specifies how many levels of contained objects are included in the JSON representation. The default value is 3.

   .EXAMPLE
   $cloudEvent = ConvertFrom-HttpMessage -Headers $httpResponse.Headers -Body $httpResponse.Content
   $hashtable = $cloudEvent | Read-CloudEventJsonData

   Reads JSON data as a hashtable from a cloud event received on the http response
#>


<#
   .DESCRIPTION
   Returns PowerShell hashtable that represents the CloudEvent Json Data
   if the data content type is 'application/json', otherwise otherwise non-terminating error and no result
#>

[CmdletBinding()]
param(
   [Parameter(Mandatory = $true,
              ValueFromPipeline = $true)]
   [ValidateNotNullOrEmpty()]
   [CloudNative.CloudEvents.CloudEvent]
   $CloudEvent,

   [Parameter(Mandatory = $false,
              ValueFromPipeline = $false)]
   [int]
   $Depth = 3
)

PROCESS {

    # DataContentType is expected to be 'application/json'
    # https://github.com/cloudevents/spec/blob/master/spec.md#datacontenttype
   $dataContentType = New-Object `
      -TypeName 'System.Net.Mime.ContentType' `
      -ArgumentList ([System.Net.Mime.MediaTypeNames+Application]::Json)

   if ($CloudEvent.DataContentType -eq $dataContentType -or `
       ($CloudEvent.DataContentType -eq $null -and ` # Datacontent Type is Optional, if it is not specified we assume it is JSON as per https://github.com/cloudevents/spec/blob/v1.0.1/spec.md#datacontenttype
        $cloudEvent.Data -is [Newtonsoft.Json.Linq.JObject])) {

      $data = $cloudEvent.Data

      if ($cloudEvent.Data -is [byte[]]) {
         $data = [System.Text.Encoding]::UTF8.GetString($data)
      }

      $result = $data.ToString() | ConvertFrom-Json -AsHashtable -Depth $Depth

      Write-Output $result
   } else {
      Write-Error "Cloud Event '$($cloudEvent.Id)' has no json data"
   }
}

}

function Read-CloudEventXmlData {
<#
   .SYNOPSIS
   This function gets XML fromat data from a cloud event as a PowerShell hashtable.

   .DESCRIPTION
   This function gets the data from a cloud event and converts it to a PowerShell hashtable.
   If the cloud event datacontenttype is not 'application/xml' nothing is returned.

   .PARAMETER CloudEvent
   Specifies the cloud event object to get data from.

   .PARAMETER ConvertMode
   Specifies the how to convert the xml data to a hashtable
      'SkipAttributes' - Skips attributes of the XML elements. XmlElement is represented as a
         Key-Value pair where key is the xml element name, and the value is the xml element inner text

         Example:
            "<key att='true'>value1</key>" is converted to
            @{'key' = 'value-1'}

      'AlwaysAttrValue' - Each element is represented as a hashtable with two keys
         'Attributes' - key-value pair of the cml element attributes if any, otherwise null
         'Value' - string value represinting the xml element inner text

         Example:
            "<key1 att='true'>value1</key1><key2>value2</key2>" is converted to
            @{
               'key1' = @{
                  'Attributes' = @{
                     'att' = 'true'
                  }
                  'Value' = 'value1'
               }
               'key2' = @{
                  'Attributes' = $null
                  'Value' = 'value2'
               }

             }
      'AttrValueWhenAttributes' - Uses 'SkipAttributes' for xml elements without attributes and
         'AlwaysAttrValue' for xml elements with attributes
         Example:
            "<key1 att='true'>value1</key1><key2>value2</key2>" is converted to
            @{
               'key1' = @{
                  'Attributes' = @{
                     'att' = 'true'
                  }
                  'Value' = 'value1'
               }
               'key2' = 'value2'
             }

   .EXAMPLE
   $cloudEvent = ConvertFrom-HttpMessage -Headers $httpResponse.Headers -Body $httpResponse.Content
   $hashtable = $cloudEvent | Read-CloudEventXmlData -ConvertMode AttrValueWhenAttributes

   Reads XML data as a hashtable from a cloud event received on the http response
#>


<#
   .DESCRIPTION
   Returns PowerShell hashtable that represents the CloudEvent Xml Data
   if the data content type is 'application/xml', otherwise non-terminating error and no result
#>

[CmdletBinding()]
param(
   [Parameter(Mandatory = $true,
              ValueFromPipeline = $true)]
   [ValidateNotNullOrEmpty()]
   [CloudNative.CloudEvents.CloudEvent]
   $CloudEvent,

   [Parameter(Mandatory = $true)]
   [ValidateSet("SkipAttributes", "AlwaysAttrValue", "AttrValueWhenAttributes")]
   [string]
   $ConvertMode
)

PROCESS {

    # DataContentType is expected to be 'application/xml'
   $dataContentType = New-Object `
      -TypeName 'System.Net.Mime.ContentType' `
      -ArgumentList ([System.Net.Mime.MediaTypeNames+Application]::Xml)

   if ($CloudEvent.DataContentType -eq $dataContentType) {

      $data = $cloudEvent.Data

      if ($cloudEvent.Data -is [byte[]]) {
         $data = [System.Text.Encoding]::UTF8.GetString($data)
      }

      $result = $data.ToString() | ConvertFrom-CEDataXml -ConvertMode $ConvertMode

      Write-Output $result
   } else {
      Write-Error "Cloud Event '$($cloudEvent.Id)' has no xml data"
   }
}

}
#endregion Read Data Functions

#region HTTP Protocol Binding Conversion Functions
function ConvertTo-HttpMessage {
<#
   .SYNOPSIS
   This function converts a cloud event object to a Http Message.

   .DESCRIPTION
   This function converts a cloud event object to a PSObject with Headers and Body properties.
   The 'Headers' propery is a hashtable that can pe provided to the 'Headers' parameter of the Inveok-WebRequest cmdlet.
   The 'Body' propery is byte[] that can pe provided to the 'Body' parameter of the Inveok-WebRequest cmdlet.

   .PARAMETER CloudEvent
   Specifies the cloud event object to convert.

   .PARAMETER ContentMode
   Specifies the cloud event content mode. Structured and Binary content modes are supporterd.

   .EXAMPLE
   $cloudEvent = New-CloudEvent -Type 'com.example.object.deleted.v2' -Source 'mailto:cncf-wg-serverless@lists.cncf.io' -Id '6e8bc430-9c3a-11d9-9669-0800200c9a66' -Time (Get-Date)
   $cloudEvent | Add-CloudEventJsonData -Data @{ 'key1' = 'value1'; 'key2' = 'value2'; }

   $cloudEvent | ConvertTo-HttpMessage -ContentMode Binary

   Converts a cloud event object to Headers and Body formatted in Binary content mode.

   .EXAMPLE
   $cloudEvent = New-CloudEvent -Type 'com.example.object.deleted.v2' -Source 'mailto:cncf-wg-serverless@lists.cncf.io' -Id '6e8bc430-9c3a-11d9-9669-0800200c9a66' -Time (Get-Date)
   $cloudEvent | Add-CloudEventJsonData -Data @{ 'key1' = 'value1'; 'key2' = 'value2'; }

   $cloudEvent | ConvertTo-HttpMessage -ContentMode Structured

   Converts a cloud event object to Headers and Body formatted in Structured content mode.

   .EXAMPLE
   $httpMessage = New-CloudEvent -Type 'com.example.object.deleted.v2' -Source 'mailto:cncf-wg-serverless@lists.cncf.io' -Id '6e8bc430-9c3a-11d9-9669-0800200c9a66' -Time (Get-Date) | `
                  Add-CloudEventJsonData -Data @{ 'key1' = 'value1'; 'key2' = 'value2'; } | `
                  ConvertTo-HttpMessage -ContentMode Structured

   Invoke-WebRequest -Uri 'http://localhost:52673/' -Headers $httpMessage.Headers -Body $httpMessage.Body

   Sends a cloud event http requests to a server
#>

[CmdletBinding()]
param(
   [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $false)]
   [ValidateNotNull()]
   [CloudNative.CloudEvents.CloudEvent]
   $CloudEvent,

   [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $false,
      ValueFromPipelineByPropertyName = $false)]
   [CloudNative.CloudEvents.ContentMode]
   $ContentMode)

PROCESS {
   # Output Object
   $result = New-Object -TypeName PSCustomObject

   $cloudEventFormatter = New-Object 'CloudNative.CloudEvents.JsonEventFormatter'

   $HttpHeaderPrefix = "ce-";
   $SpecVersionHttpHeader1 = $HttpHeaderPrefix + "cloudEventsVersion";
   $SpecVersionHttpHeader2 = $HttpHeaderPrefix + "specversion";

   $headers = @{}

   # Build HTTP headers
   foreach ($attribute in $cloudEvent.GetAttributes()) {
       if (-not $attribute.Key.Equals([CloudNative.CloudEvents.CloudEventAttributes]::DataAttributeName($cloudEvent.SpecVersion)) -and `
           -not $attribute.Key.Equals([CloudNative.CloudEvents.CloudEventAttributes]::DataContentTypeAttributeName($cloudEvent.SpecVersion))) {
           if ($attribute.Value -is [string]) {
               $headers.Add(($HttpHeaderPrefix + $attribute.Key), $attribute.Value.ToString())
           }
           elseif ($attribute.Value -is [DateTime]) {
               $headers.Add(($HttpHeaderPrefix + $attribute.Key), $attribute.Value.ToString("u"))
           }
           elseif ($attribute.Value -is [Uri] -or $attribute.Value -is [int]) {
               $headers.Add(($HttpHeaderPrefix + $attribute.Key), $attribute.Value.ToString())
           }
           else
           {
               $headers.Add(($HttpHeaderPrefix + $attribute.Key),
                   [System.Text.Encoding]::UTF8.GetString($cloudEventFormatter.EncodeAttribute($cloudEvent.SpecVersion, $attribute.Key,
                       $attribute.Value,
                       $cloudEvent.Extensions.Values)));
           }
       }
   }

   # Add Headers property to the output object
   $result | Add-Member -MemberType NoteProperty -Name 'Headers' -Value $headers

   # Process Structured Mode
   # Structured Mode supports non-batching JSON format only
   # https://github.com/cloudevents/spec/blob/v1.0.1/http-protocol-binding.md#14-event-formats
   if ($ContentMode -eq [CloudNative.CloudEvents.ContentMode]::Structured) {
      # Format Body as byte[]
      $contentType = $null

      # CloudEventFormatter is instance of 'CloudNative.CloudEvents.JsonEventFormatter' from the
      # .NET CloudEvents SDK for the purpose of fomatting structured mode
      $buffer = $cloudEventFormatter.EncodeStructuredEvent($cloudEvent, [ref] $contentType)
      $result | Add-Member -MemberType NoteProperty -Name 'Body' -Value $buffer
      $result.Headers.Add('Content-Type', $contentType)
   }

   # Process Binary Mode
   if ($ContentMode -eq [CloudNative.CloudEvents.ContentMode]::Binary) {
      $bodyData = $null

      if ($cloudEvent.DataContentType -ne $null) {
         $result.Headers.Add('Content-Type', $cloudEvent.DataContentType)
      }

      if ($cloudEvent.Data -is [byte[]]) {
         $bodyData = $cloudEvent.Data
      }
      elseif ($cloudEvent.Data -is [string]) {
         $bodyData = [System.Text.Encoding]::UTF8.GetBytes($cloudEvent.Data.ToString())
      }
      elseif ($cloudEvent.Data -is [IO.Stream]) {
         $buffer = New-Object 'byte[]' -ArgumentList 1024

         $ms = New-Object 'IO.MemoryStream'

         try {
            $read = 0
            while (($read = $cloudEvent.Data.Read($buffer, 0, 1024)) -gt 0)
            {
               $ms.Write($buffer, 0, $read);
            }
            $bodyData = $ms.ToArray()
         } finally {
            $ms.Dispose()
         }

      } else {
         $bodyData = $cloudEventFormatter.EncodeAttribute($cloudEvent.SpecVersion,
            [CloudNative.CloudEvents.CloudEventAttributes]::DataAttributeName($cloudEvent.SpecVersion),
            $cloudEvent.Data, $cloudEvent.Extensions.Values)
      }

      # Add Body property to the output object
      $result | Add-Member -MemberType NoteProperty -Name 'Body' -Value $bodyData
   }

   Write-Output $result
}
}

function ConvertFrom-HttpMessage {
<#
   .SYNOPSIS
   This function converts a Http Message to a cloud event object

   .DESCRIPTION
   This function converts a Http Message (Headers and Body) to a cloud event object.
   Result of Invoke-WebRequest that contains a cloud event can be passed as input to this
   function binding the the 'Headers' and 'Content' properties to the 'Headers' and 'Body' paramters.

   .PARAMETER Headers
   Specifies the Http Headers as a PowerShell hashtable.

   .PARAMETER Body
   Specifies the Http body as string or byte[].

   .EXAMPLE
   $httpReponse = Invoke-WebRequest -Uri 'http://localhost:52673/' -Headers $httpMessage.Headers -Body $httpMessage.Body
   $cloudEvent = ConvertFrom-HttpMessage -Headers $httpResponse.Headers -Body $httpResponse.Content

   Converts a http response to a cloud event object
#>

[CmdletBinding()]
param(
   [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $false,
      ValueFromPipelineByPropertyName = $false)]
   [ValidateNotNull()]
   [hashtable]
   $Headers,

   [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $false,
      ValueFromPipelineByPropertyName = $false)]
   [ValidateNotNull()]
   $Body)

PROCESS {
   $HttpHeaderPrefix = "ce-";
   $SpecVersionHttpHeader1 = $HttpHeaderPrefix + "cloudEventsVersion";
   $SpecVersionHttpHeader2 = $HttpHeaderPrefix + "specversion";

   $result = $null

   # Always Convert Body to byte[]
   # Conversion works with byte[] while
   # body can be string in HTTP responses
   # for text content type
   if ($Body -is [string]) {
      $Body = [System.Text.Encoding]::UTF8.GetBytes($Body)
   }

   if ($Headers['Content-Type'] -ne $null) {
      $ContentType = $Headers['Content-Type']
      if ($ContentType -is [array]) {
         # Get the first content-type value
         $ContentType = $ContentType[0]
      }

      if ($ContentType.StartsWith([CloudNative.CloudEvents.CloudEvent]::MediaType,
                       [StringComparison]::InvariantCultureIgnoreCase)) {

         # Handle Structured Mode
         $ctParts = $ContentType.Split(';')
         if ($ctParts[0].Trim().StartsWith(([CloudNative.CloudEvents.CloudEvent]::MediaType) + ([CloudNative.CloudEvents.JsonEventFormatter]::MediaTypeSuffix),
            [StringComparison]::InvariantCultureIgnoreCase)) {

            # Structured Mode supports non-batching JSON format only
            # https://github.com/cloudevents/spec/blob/v1.0.1/http-protocol-binding.md#14-event-formats

            # .NET SDK 'CloudNative.CloudEvents.JsonEventFormatter' type is used
            # to decode the Structured Mode CloudEvents

            $json = [System.Text.Encoding]::UTF8.GetString($Body)
            $jObject = [Newtonsoft.Json.Linq.JObject]::Parse($json)
            $formatter = New-Object 'CloudNative.CloudEvents.JsonEventFormatter'
            $result = $formatter.DecodeJObject($jObject, $null)

            $result.Data = $result.Data
         } else {
            # Throw error for unsupported encoding
            throw "Unsupported CloudEvents encoding"
         }
      } else {
         # Handle  Binary Mode
         $version = [CloudNative.CloudEvents.CloudEventsSpecVersion]::Default
         if ($Headers.Contains($SpecVersionHttpHeader1)) {
            $version = [CloudNative.CloudEvents.CloudEventsSpecVersion]::V0_1
         }

         if ($Headers.Contains($SpecVersionHttpHeader2)) {
            if ($Headers[$SpecVersionHttpHeader2][0] -eq "0.2") {
               $version = [CloudNative.CloudEvents.CloudEventsSpecVersion]::V0_2
            } elseif ($Headers[$SpecVersionHttpHeader2][0] -eq "0.3") {
               $version = [CloudNative.CloudEvents.CloudEventsSpecVersion]::V0_3
            }
         }

         $cloudEvent = New-Object `
                        -TypeName 'CloudNative.CloudEvents.CloudEvent' `
                        -ArgumentList @($version, $null);

         $attributes = $cloudEvent.GetAttributes();

         # Get attributes from HTTP Headers
         foreach ($httpHeader in $Headers.GetEnumerator()) {
           if ($httpHeader.Key.Equals($SpecVersionHttpHeader1, [StringComparison]::InvariantCultureIgnoreCase) -or `
               $httpHeader.Key.Equals($SpecVersionHttpHeader2, [StringComparison]::InvariantCultureIgnoreCase)) {
               continue
           }

           if ($httpHeader.Key.StartsWith($HttpHeaderPrefix, [StringComparison]::InvariantCultureIgnoreCase)) {
               $headerValue = $httpHeader.Value
               if ($headerValue -is [array]) {
                  # Get the first object
                  $headerValue = $headerValue[0]
               }
               $name = $httpHeader.Key.Substring(3);

               # Abolished structures in headers in 1.0
               if ($version -ne [CloudNative.CloudEvents.CloudEventsSpecVersion]::V0_1 -and `
                   $headerValue -ne $null -and `
                   $headerValue.StartsWith('"') -and `
                   $headerValue.EndsWith('"') -or `
                   $headerValue.StartsWith("'") -and $headerValue.EndsWith("'") -or `
                   $headerValue.StartsWith("{") -and $headerValue.EndsWith("}") -or `
                   $headerValue.StartsWith("[") -and $headerValue.EndsWith("]")) {

                  $jsonFormatter = New-Object 'CloudNative.CloudEvents.JsonEventFormatter'

                  $attributes[$name] = $jsonFormatter.DecodeAttribute($version, $name,
                       [System.Text.Encoding]::UTF8.GetBytes($headerValue), $null);
               } else {
                  $attributes[$name] = $headerValue
               }
           }
         }

         if ($Headers['Content-Type'] -ne $null -and $Headers['Content-Type'][0] -is [string]) {
            $cloudEvent.DataContentType = New-Object 'System.Net.Mime.ContentType' -ArgumentList @($Headers['Content-Type'][0])
         }

         # Get Data from HTTP Body
         $cloudEvent.Data = $Body

         $result = $cloudEvent
      }
   }

   Write-Output $result
}
}
#endregion HTTP Protocol Binding Conversion Functions