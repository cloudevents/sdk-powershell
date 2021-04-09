# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

$SKIPATTR = "SkipAttributes"
$ALWAYSATTRVALUE = "AlwaysAttrValue"
$ATTRVALUEFORELEMENTSWITHATTR = "AttrValueWhenAttributes"
function ConvertFrom-XmlPropertyValue {
param(
   [Parameter(Mandatory = $true,
              ValueFromPipeline = $false)]
   $InputObject,

   [Parameter(Mandatory = $true)]
   [ValidateSet("SkipAttributes", "AlwaysAttrValue", "AttrValueWhenAttributes")]
   [string]
   $ConvertMode
)

   $value = $InputObject
   $Attributes = $null

   if ($InputObject -is [Xml.XmlElement]) {
      $hasAttributes = (($InputObject | Get-Member -MemberType Properties) | Where-Object {$_.Name -eq '#text'}) -ne $null
      if ($hasAttributes) {
         $Attributes = @{}
         $arrProperties = $InputObject | Get-Member -MemberType Properties
         foreach ($p in $arrProperties) {
            if ($p.Name -eq '#text') {
               $value = $InputObject.'#text'
            } else {
               $Attributes[$p.Name] = $InputObject.$($p.Name)
            }
         }

      } else {
         $value = ConvertFrom-CEDataXml -InputXmlElement $InputObject -ConvertMode $ConvertMode
      }
   }

   if ($InputObject -is [array]) {
      $value = @()
      foreach ($obj in $InputObject) {
         $value += ConvertFrom-XmlPropertyValue -InputObject $obj -ConvertMode $ConvertMode
      }
   }

   if (($ConvertMode -eq $SKIPATTR) -or
       ($Attributes -eq $null -and $ConvertMode -eq $ATTRVALUEFORELEMENTSWITHATTR)) {

      $value
   }

   if (($ConvertMode -eq $ALWAYSATTRVALUE) -or
       ($Attributes -ne $null -and $ConvertMode -eq $ATTRVALUEFORELEMENTSWITHATTR)) {
      @{
         "Attributes" = $Attributes
         "Value" = $value
       }
   }
}

function ConvertFrom-CEDataXml {
param(
   [Parameter(Mandatory = $true,
              ValueFromPipeline = $true,
              ParameterSetName="Text")]
   [ValidateNotNull()]
   [string]
   $InputString,

   [Parameter(Mandatory = $true,
              ValueFromPipeline = $false,
              ParameterSetName="XmlElement")]
   [ValidateNotNull()]
   [Xml.XmlElement]
   $InputXmlElement,

   [Parameter(Mandatory = $true)]
   [ValidateSet("SkipAttributes", "AlwaysAttrValue", "AttrValueWhenAttributes")]
   [string]
   $ConvertMode
)
   $result = $null
   if ($InputString -ne $null) {
      $xmlDocument = [xml]$InputString
   }
   if ($InputXmlElement -ne $null) {
      $xmlDocument = $InputXmlElement
   }

   if ($xmlDocument -ne $null) {
      $xmlProperties = $xmlDocument | Get-Member -MemberType Properties

      $result = @{}


      foreach ($property in  $xmlProperties) {
         $propertyName = $property.Name
         $value = ConvertFrom-XmlPropertyValue -InputObject $xmlDocument.$propertyName -ConvertMode $ConvertMode
         $result[$propertyName] = $value
      }
   }

   $result
}

function New-XmlElement {
param(
   [Parameter(Mandatory = $true,
              ValueFromPipeline = $false)]
   [ValidateNotNull()]
   $DictionaryEntry,

   [Parameter(Mandatory = $true,
              ValueFromPipeline = $false)]
   $XmlDocument,

   [Parameter(Mandatory = $false)]
   [Switch]
   $AttributesKeysInElementAttributes

)
   $result = $XmlDocument.CreateElement($DictionaryEntry.Name)

   $value = ""

   if ($DictionaryEntry.Value -is [hashtable]) {
      if($DictionaryEntry.Value.Keys.Count -eq 2 -and `
         $DictionaryEntry.Value['Attributes'] -is [hashtable] -and `
         $DictionaryEntry.Value['Value'] -ne $null -and `
         $AttributesKeysInElementAttributes) {
         foreach ($attKv in $DictionaryEntry.Value['Attributes'].GetEnumerator()) {
            $result.SetAttribute($attKv.Name, $attKv.Value)
         }
         $result.InnerText = $DictionaryEntry.Value['Value'].ToString()

      } else {
         foreach ($nameValue in $DictionaryEntry.Value.GetEnumerator())  {
            $xmlElement = New-XmlElement -DictionaryEntry $nameValue -XmlDocument $XmlDocument -AttributesKeysInElementAttributes:$AttributesKeysInElementAttributes
            $xmlElement | Foreach-Object {
               $result.AppendChild($_) | Out-Null
            }
         }
      }
   } elseif ($DictionaryEntry.Value -is [array]) {
      $result = @()
      foreach ($item in $DictionaryEntry.Value) {
         $result += (New-XmlElement `
                        -DictionaryEntry `
                           (New-Object System.Collections.DictionaryEntry `
                                 -ArgumentList @($DictionaryEntry.Name, $item)) `
                        -XmlDocument $XmlDocument `
                        -AttributesKeysInElementAttributes:$AttributesKeysInElementAttributes)
      }
   } else {
      $value = $DictionaryEntry.Value.ToString()
      $result.InnerText = $value
   }

   $result
}

function ConvertTo-CEDataXml {
param(
   [Parameter(Mandatory = $true,
              ValueFromPipeline = $true)]
   [ValidateNotNull()]
   [Hashtable]
   $InputObject,

   [Parameter(Mandatory = $true)]
   [bool]
   $AttributesKeysInElementAttributes
)
   if ($InputObject.Keys.Count -ne 1) {
      throw "Input Hashtable must have single root key"
   }

   [xml]$resultDocument = New-Object System.Xml.XmlDocument

   foreach ($nameValue in $InputObject.GetEnumerator()) {
      $element = New-XmlElement -DictionaryEntry $nameValue -XmlDocument $resultDocument -AttributesKeysInElementAttributes:$AttributesKeysInElementAttributes

      $element | Foreach-Object {
         $resultDocument.AppendChild($_) | Out-Null
      }
   }

   $resultDocument.OuterXml
}