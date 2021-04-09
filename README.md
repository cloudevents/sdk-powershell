# PowerShell 7.0 SDK for CloudEvents based on [.NET SDK for CloudEvents](https://github.com/cloudevents/sdk-csharp)

## Status

Supported CloudEvents versions:
- v1.0

Supported Protocols:
- HTTP

# **CloudEvents.Sdk** Module
The module contains functions to
- Create CloudEvent objects
- Add data to a CloudEvent object
- Read data from a CloudEvent object
- Convert a CloudEvent object to an HTTP Message
- Convert an HTTP Message to a CloudEvent object

## Producer
### Create a CloudEvent object
```powershell
$cloudEvent = New-CloudEvent -Type 'com.example.object.deleted.v2' -Source 'mailto:cncf-wg-serverless@lists.cncf.io' -Id '6e8bc430-9c3a-11d9-9669-0800200c9a66' -Time (Get-Date)
```

### Add **JSON Data** to a CloudEvent object
```powershell
$cloudEvent | Add-CloudEventJsonData -Data @{
   'key1' = 'value1'
   'key2' = @{
      'key3' = 'value3'
   }
}
```

### Add **XML Data** to a CloudEvent object
```powershell
$cloudEvent | Add-CloudEventXmlData -Data @{
   'key1' = @{
      'key2' = 'value'
   }
} `
-AttributesKeysInElementAttributes $true
```
`AttributesKeysInElementAttributes` specifies how to format the XML. If `true` and the input Data hashtable has pairs of 'Attributes', 'Value' keys creates XML element with attributes, otherwise each key is formatted as XML element.<br/>
If `true`
```powershell
   @{'root' = @{'Attributes' = @{'att1' = 'true'}; 'Value' = 'val-1'}}
```
is formatted as
```xml
<root att1="true">val-1</root>
```
If `false`
```powershell
@{'root' = @{'Attributes' = @{'att1' = 'true'}; 'Value' = 'val-1'}}
```
is formatted as
```xml
<root><Attributes><att1>true</att1></Attributes><Value>val-1</Value></root>
```

#### Add Custom Format Data to a CloudEvent object
```powershell
$cloudEvent | Add-CloudEventData -DataContentType 'application/text' -Data 'wow'
```

### Convert a CloudEvent object to an HTTP message in **Binary** or **Structured** content mode
```powershell
$cloudEventBinaryHttpMessage = $cloudEvent | ConvertTo-HttpMessage -ContentMode Binary
$cloudEventStructuredHttpMessage = $cloudEvent | ConvertTo-HttpMessage -ContentMode Structured
```

### Send CloudEvent object to HTTP server
```powershell
Invoke-WebRequest -Method POST -Uri 'http://my.cloudevents.server/' -Headers $cloudEventBinaryHttpMessage.Headers -Body $cloudEventBinaryHttpMessage.Body
```

## Consumer
### Convert an HTTP message to a CloudEvent object
```powershell
$cloudEvent = ConvertFrom-HttpMessage -Headers <headers> -Body <body>
```

### Read CloudEvent **JSON Data** as a **PowerShell Hashtable**
```powershell
$hashtableData = Read-CloudEventJsonData -CloudEvent $cloudEvent
```

### Read CloudEvent **XML Data** as a **PowerShell Hashtable**
```powershell
$hashtableData = Read-CloudEventXmlData -CloudEvent $cloudEvent -ConvertMode SkipAttributes
```
The `ConvertMode` parameter specifies how the XML to be represented in the result hashtable<br/>
`SkipAttributes` - Skips attributes of the XML elements. XmlElement is a Key-Value pair where Key is the Xml element name, and the value is the Xml element inner text<br/>
Example:
```xml
<key att='true'>value1</key>
```
is converted to
```powershell
@{'key' = 'value-1'}
```
`AlwaysAttrValue` - Each element is a HashTable with two keys<br/>
        'Attributes' - key-value pair of the Xml element attributes if any, otherwise null<br/>
        'Value' - string value represinting the xml element inner text<br/>
Example:
```xml
```
<key1 att='true'>value1</key1><key2>value2</key2>
is converted to
```powershell
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
```
`AttrValueWhenAttributes` - Uses `SkipAttributes` for xml elements without attributes and `AlwaysAttrValue` for xml elements with attributes<br/>
Example:
```xml
<key1 att='true'>value1</key1><key2>value2</key2>
```
is converted to
```powershell
@{
   'key1' = @{
      'Attributes' = @{
         'att' = 'true'
      }
      'Value' = 'value1'
   }
   'key2' = 'value2'
}
```

### Read CloudEvent Custom Format **Data** as a **byte[]**
```powershell
$bytes = Read-CloudEventData -CloudEvent $cloudEvent
```

# Build the **CloudEvents.Sdk** Module

The `build.ps1` script
- Creates the CloudEvents PowerShell Module in a `CloudEvents` directory.
- Runs functions unit tests
- Runs local integrations tests
- Creates a catalog file for the CloudEvents Module

### Prerequisites
- [PowerShell 7.0](https://github.com/PowerShell/PowerShell/releases/tag/v7.0.4)
- [Pester 5.1.1](https://www.powershellgallery.com/packages/Pester/5.1.1)
- [dotnet SDK](https://dotnet.microsoft.com/download/dotnet/5.0)

```powershell
> ./build.ps1
[9:52:42 AM] INFO: Publish CloudEvents.Sdk Module to 'C:\git-repos\cloudevents\cloudevents-sdk-powershell\CloudEvents.Sdk'
Microsoft (R) Build Engine version 16.8.3+39993bd9d for .NET
Copyright (C) Microsoft Corporation. All rights reserved.

  Determining projects to restore...
  All projects are up-to-date for restore.
  CloudEventsPowerShell -> C:\git-repos\cloudevents\cloudevents-sdk-powershell\src\CloudEventsPowerShell\bin\Release\netstandard2.0\CloudEventsPowerShell.dll
  CloudEventsPowerShell -> C:\git-repos\cloudevents\cloudevents-sdk-powershell\CloudEvents.Sdk\
[9:52:44 AM] INFO: Run unit tests

Starting discovery in 9 files.
Discovery finished in 294ms.
[+] C:\git-repos\cloudevents\cloudevents-sdk-powershell\test\unit\Add-CloudEventData.Tests.ps1 1.01s (184ms|656ms)
[+] C:\git-repos\cloudevents\cloudevents-sdk-powershell\test\unit\Add-CloudEventJsonData.Tests.ps1 329ms (39ms|279ms)   [+] C:\git-repos\cloudevents\cloudevents-sdk-powershell\test\unit\Add-CloudEventXmlData.Tests.ps1 336ms (58ms|267ms)    [+] C:\git-repos\cloudevents\cloudevents-sdk-powershell\test\unit\ConvertFrom-HttpMessage.Tests.ps1 557ms (203ms|337ms) [+] C:\git-repos\cloudevents\cloudevents-sdk-powershell\test\unit\ConvertTo-HttpMessage.Tests.ps1 508ms (132ms|361ms)   [+] C:\git-repos\cloudevents\cloudevents-sdk-powershell\test\unit\New-CloudEvent.Tests.ps1 275ms (22ms|243ms)
[+] C:\git-repos\cloudevents\cloudevents-sdk-powershell\test\unit\Read-CloudEventData.Tests.ps1 257ms (10ms|236ms)
[+] C:\git-repos\cloudevents\cloudevents-sdk-powershell\test\unit\Read-CloudEventJsonData.Tests.ps1 308ms (40ms|257ms)
[+] C:\git-repos\cloudevents\cloudevents-sdk-powershell\test\unit\Read-CloudEventXmlData.Tests.ps1 310ms (53ms|246ms)
Tests completed in 3.94s
Tests Passed: 28, Failed: 0, Skipped: 0 NotRun: 0
[9:52:49 AM] INFO: Run integration tests

Starting discovery in 1 files.
Discovery finished in 176ms.
[+] C:\git-repos\cloudevents\cloudevents-sdk-powershell\test\integration\HttpIntegration.Tests.ps1 2.54s (1.77s|617ms)
Tests completed in 2.56s
Tests Passed: 5, Failed: 0, Skipped: 0 NotRun: 0
```