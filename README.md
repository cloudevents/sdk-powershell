# PowerShell 7.0 SDK for CloudEvents based on [.NET SDK for CloudEvents](https://github.com/cloudevents/sdk-csharp)

Official CloudEvents SDK to integrate your application with CloudEvents.

## Status

Supported CloudEvents versions:
- v1.0

Supported Protocols:
- HTTP

## **`CloudEvents.Sdk`** Module
The module contains functions to
- Create CloudEvent objects
- Add data to a CloudEvent object
- Read data from a CloudEvent object
- Convert a CloudEvent object to an HTTP Message
- Convert an HTTP Message to a CloudEvent object

## Install **`CloudEvents.Sdk`** Module

### Prerequisites
- [PowerShell 7.0](https://github.com/PowerShell/PowerShell/releases/tag/v7.0.4)

```powershell
Install-Module CloudEvents.Sdk
Import-Module CloudEvents.Sdk
Get-Command -Module CloudEvents.Sdk

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        ConvertFrom-HttpMessage                            0.3.0      CloudEvents.Sdk
Function        ConvertTo-HttpMessage                              0.3.0      CloudEvents.Sdk
Function        New-CloudEvent                                     0.3.0      CloudEvents.Sdk
Function        Read-CloudEventData                                0.3.0      CloudEvents.Sdk
Function        Read-CloudEventJsonData                            0.3.0      CloudEvents.Sdk
Function        Read-CloudEventXmlData                             0.3.0      CloudEvents.Sdk
Function        Set-CloudEventData                                 0.3.0      CloudEvents.Sdk
Function        Set-CloudEventJsonData                             0.3.0      CloudEvents.Sdk
Function        Set-CloudEventXmlData                              0.3.0      CloudEvents.Sdk
```

## Using **`CloudEvents.Sdk`** Module
## 1. Event Producer
### Create a CloudEvent object
```powershell
$cloudEvent = New-CloudEvent -Type 'com.example.object.deleted.v2' -Source 'mailto:cncf-wg-serverless@lists.cncf.io' -Id (New-Guid).Guid -Time (Get-Date)
```

### Set **JSON Data** to a CloudEvent object
```powershell
$cloudEvent | Set-CloudEventJsonData -Data @{
    'Foo' = 'Hello'
    'Bar' = 'World'
}


DataContentType : application/json
Data            : {
                    "Bar": "World",
                    "Foo": "Hello"
                  }
Id              : ac9b12d9-ae45-4654-a4d7-42bbf0d9816d
DataSchema      :
Source          : mailto:cncf-wg-serverless@lists.cncf.io
SpecVersion     : V1_0
Subject         :
Time            : 4/26/2021 9:00:45 AM
Type            : com.example.object.deleted.v2
```

### Set **XML Data** to a CloudEvent object
```powershell
$cloudEvent | Set-CloudEventXmlData -Data @{
    'xml' = @{
        'Foo' = 'Hello'
        'Bar' = 'World'
    }
} `
-AttributesKeysInElementAttributes $true


DataContentType : application/xml
Data            : <xml><Bar>World</Bar><Foo>Hello</Foo></xml>
Id              : ac9b12d9-ae45-4654-a4d7-42bbf0d9816d
DataSchema      :
Source          : mailto:cncf-wg-serverless@lists.cncf.io
SpecVersion     : V1_0
Subject         :
Time            : 4/26/2021 9:00:45 AM
Type            : com.example.object.deleted.v2
```
### Set Custom Format Data to a CloudEvent object
```powershell
$cloudEvent | Set-CloudEventData -DataContentType 'application/text' -Data 'Hello World!'

DataContentType : application/text
Data            : Hello World!
Id              : b1b748cd-e98d-4f5f-80ea-76dea71a53a5
DataSchema      :
Source          : mailto:cncf-wg-serverless@lists.cncf.io
SpecVersion     : V1_0
Subject         :
Time            : 4/27/2021 7:00:44 PM
Type            : com.example.object.deleted.v2
```

### Convert a CloudEvent object to an HTTP message in **Binary** or **Structured** content mode
```powershell
# Format structured cloud event HTTP message
$cloudEventStructuredHttpMessage = $cloudEvent | ConvertTo-HttpMessage -ContentMode Structured
```

### Send CloudEvent object to HTTP server
```powershell
Invoke-WebRequest -Method POST -Uri 'http://my.cloudevents.server/' -Headers $cloudEventStructuredHttpMessage.Headers -Body $cloudEventStructuredHttpMessage.Body
```

## 2. Event Consumer
### Convert an HTTP message to a CloudEvent object
```powershell
$cloudEvent = ConvertFrom-HttpMessage -Headers <headers> -Body <body>
```

### Read CloudEvent **JSON Data** as a **PowerShell Hashtable**
```powershell
Read-CloudEventJsonData -CloudEvent $cloudEvent


Name                           Value
----                           -----
Foo                            Hello
Bar                            World
```

### Read CloudEvent **XML Data** as a **PowerShell Hashtable**
```powershell
Read-CloudEventXmlData -CloudEvent $cloudEvent -ConvertMode SkipAttributes

Name                           Value
----                           -----
xml                            {Bar, Foo}
```

The `ConvertMode` parameter specifies how the xml should be converted to a PowerShell Hashtable. `SkipAttributes` mode skips reading the xml attributes. There are three different modes of conversion. For more details check the help of the `Read-CloudEventXmlData` cmdlet.

### Read CloudEvent Custom Format **Data** as a **byte[]**
```powershell
Read-CloudEventData -CloudEvent $cloudEvent

72
101
108
108
111
32
87
111
114
108
100
33
```

## Community

- There are bi-weekly calls immediately following the
  [Serverless/CloudEvents call](https://github.com/cloudevents/spec#meeting-time)
  at 9am PT (US Pacific). Which means they will typically start at 10am PT, but
  if the other call ends early then the SDK call will start early as well. See
  the
  [CloudEvents meeting minutes](https://docs.google.com/document/d/1OVF68rpuPK5shIHILK9JOqlZBbfe91RNzQ7u_P7YCDE/edit#)
  to determine which week will have the call.
- Slack: #cloudeventssdk channel under
  [CNCF's Slack workspace](https://slack.cncf.io/).
- Email: https://lists.cncf.io/g/cncf-cloudevents-sdk
- Contact for additional information: Michael Gasch (`@Michael Gasch`
  on slack).

Each SDK may have its own unique processes, tooling and guidelines, common
governance related material can be found in the
[CloudEvents `community`](https://github.com/cloudevents/spec/tree/master/community)
directory. In particular, in there you will find information concerning
how SDK projects are
[managed](https://github.com/cloudevents/spec/blob/master/community/SDK-GOVERNANCE.md),
[guidelines](https://github.com/cloudevents/spec/blob/master/community/SDK-maintainer-guidelines.md)
for how PR reviews and approval, and our
[Code of Conduct](https://github.com/cloudevents/spec/blob/master/community/GOVERNANCE.md#additional-information)
information.

## Additional SDK Resources

- [List of current active maintainers](MAINTAINERS.md)
- [How to contribute to the project](CONTRIBUTING.md)
- [SDK's License](LICENSE)
- [SDK's Release process](RELEASING.md)
