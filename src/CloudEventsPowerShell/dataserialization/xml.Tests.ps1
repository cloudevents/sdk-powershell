# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}

Describe "CloudEvent Xml Serializers Unit Tests" {
   Context "ConvertFrom-CEDataXml" {
      It "Should convert single element XML text to a hashtable" {
         # Arrange
         $inputXml = "<key>value</key>"
         $expected = @{'key' = 'value'}

         # Act
         $actual = ConvertFrom-CEDataXml -InputString $inputXml -ConvertMode SkipAttributes

         # Assert
         $actual | Should -Not -Be $null
         $actual -is [hashtable] | Should -Be $true
         $actual.Keys.Count | Should -Be $expected.Keys.Count
         $actual.key | Should -Be $expected.key
      }

      It "Should convert XML with array of nodes to a hashtable" {
         # Arrange
         $inputXml = "<keys><key>value1</key><key>value2</key><key>value3</key></keys>"
         $expected = @{'keys' = @{'key' = @('value1', 'value2', 'value3')}}

         # Act
         $actual = ConvertFrom-CEDataXml -InputString $inputXml -ConvertMode SkipAttributes

         # Assert
         $actual | Should -Not -Be $null
         $actual -is [hashtable] | Should -Be $true
         $actual.keys.key[0] | Should -Be $expected.keys.key[0]
         $actual.keys.key[1] | Should -Be $expected.keys.key[1]
         $actual.keys.key[2] | Should -Be $expected.keys.key[2]
      }

      It "Should convert XML with array of nodes to a hashtable and ConvertMode 'AlwaysAttrValue'" {
         # Arrange
         $inputXml = "<keys><key>value1</key><key>value2</key><key>value3</key></keys>"
         $expected = @{
            'keys' = @{
               'Attributes' = $null
               'Value' = @{
                  'key' = @{
                     'Attributes' = $null
                     'Value' = @(
                       @{
                           'Attributes' = $null
                           'Value' = 'value1'
                        },
                        @{
                           'Attributes' = $null
                           'Value' = 'value2'
                        },
                        @{
                           'Attributes' = $null
                           'Value' = 'value3'
                        }
                     )
                  }
               }
            }

         }

         # Act
         $actual = ConvertFrom-CEDataXml -InputString $inputXml -ConvertMode AlwaysAttrValue

         # Assert
         $actual | Should -Not -Be $null
         $actual -is [hashtable] | Should -Be $true
         $actual.keys.Attributes | Should -Be $null
         $actual.keys.Value.key.Value[0].Value | Should -Be $expected.keys.Value.key.Value[0].Value
         $actual.keys.Value.key.Attributes | Should -Be $null
         $actual.keys.Value.key.Value[0].Attributes | Should -Be $null
         $actual.keys.Value.key.Value[1].Value | Should -Be $expected.keys.Value.key.Value[1].Value
         $actual.keys.Value.key.Value[2].Value | Should -Be $expected.keys.Value.key.Value[2].Value
      }

      It "Should convert single element XML with ConvertMode = 'AlwaysAttrValue'" {
         # Arrange
         $inputXml = "<root><key1 att1='true'>value-1</key1><key2>value-2</key2></root>"
         $expected = @{
            'root' = @{
               'Attributes' = $null
               'Value' = @{
                  'key1' = @{
                     'Attributes' = @{
                        'att1' = 'true'
                     }
                     'Value' = 'value-1'
                  }
                  'key2' = @{
                     'Attributes' = $null
                     'Value' = 'value-2'
                  }
               }
            }
         }

         # Act
         $actual = ConvertFrom-CEDataXml -InputString $inputXml -ConvertMode AlwaysAttrValue

         # Assert
         $actual | Should -Not -Be $null
         $actual -is [hashtable] | Should -Be $true
         $actual.root.Value.key1.Attributes.att1 | Should -Be $expected.root.Value.key1.Attributes.att1
         $actual.root.Value.key1.Value | Should -Be $expected.root.Value.key1.Value
         $actual.root.Value.key2.Attributes | Should -Be $expected.root.Value.key2.Attributes
         $actual.root.Value.key2.Value | Should -Be $expected.root.Value.key2.Value
      }

      It "Should convert elements with attributes with ConvertMode = 'AttrValueWhenAttributes'" {
         # Arrange
         $inputXml = "<root><key>value</key><withattr att1='true' att2='false'>value-1</withattr></root>"
         $expected = @{
            'root' = @{
               'key' = 'value'
               'withattr' = @{
                  'Attributes' = @{
                     'att1' = 'true'
                     'att2' = 'false'
                  }
                  'Value' = 'value-1'
               }
            }
         }

         # Act
         $actual = ConvertFrom-CEDataXml -InputString $inputXml -ConvertMode AttrValueWhenAttributes

         # Assert
         $actual | Should -Not -Be $null
         $actual -is [hashtable] | Should -Be $true
         $actual.root.key | Should -Be $expected.root.key
         $actual.root.withattr.Attributes.att1 | Should -Be $expected.root.withattr.Attributes.att1
         $actual.root.withattr.Attributes.att2 | Should -Be $expected.root.withattr.Attributes.att2
         $actual.root.withattr.Value | Should -Be $expected.root.withattr.Value
      }

      It "Should convert XML with nested elements to a hashtable skipping attribute properties" {
         # Arrange
         $inputXml = '<UserLoginSessionEvent><key>8570</key><chainId>8570</chainId><createdTime>2021-02-04T08:51:53.723999Z</createdTime><userName>dcui</userName><datacenter><name>vcqaDC</name><datacenter type="Datacenter">datacenter-2</datacenter></datacenter><computeResource><name>cls</name><computeResource type="ClusterComputeResource">domain-c7</computeResource></computeResource><host><name>10.161.140.163</name><host type="HostSystem">host-21</host></host><fullFormattedMessage>User dcui@127.0.0.1 logged in as VMware-client/6.5.0</fullFormattedMessage><ipAddress>127.0.0.1</ipAddress><userAgent>VMware-client/6.4.0</userAgent><locale>en</locale><sessionId>52b910cf-661f-f72d-9f86-fb82113404b7</sessionId></UserLoginSessionEvent>'
         $expected = @{
            'UserLoginSessionEvent' = @{
               'key' = '8570'
               'createdTime' = '2021-02-04T08:51:53.723999Z'
               'userName' = 'dcui'
               'datacenter' = @{
                  'name' = 'vcqaDC'
                  'datacenter' = 'datacenter-2'
               }
               'computeResource' = @{
                  'name' = 'cls'
                  'computeResource' = 'domain-c7'
               }
               'host' = @{
                  'name' = '10.161.140.163'
                  'host' = 'host-21'
               }
               'fullFormattedMessage' = 'User dcui@127.0.0.1 logged in as VMware-client/6.5.0'
               'ipAddress' = '127.0.0.1'
               'userAgent' = 'VMware-client/6.4.0'
               'locale' = 'en'
               'sessionId' = '52b910cf-661f-f72d-9f86-fb82113404b7'
            }
         }

         # Act
         $actual = ConvertFrom-CEDataXml -InputString $inputXml -ConvertMode SkipAttributes

         # Assert
         $actual | Should -Not -Be $null
         $actual -is [hashtable] | Should -Be $true
         $actual.UserLoginSessionEvent -is [hashtable] | Should -Be $true
         $actual.UserLoginSessionEvent.key | Should -Be $expected.UserLoginSessionEvent.key
         $actual.UserLoginSessionEvent.createdTime | Should -Be $expected.UserLoginSessionEvent.createdTime
         $actual.UserLoginSessionEvent.userName | Should -Be $expected.UserLoginSessionEvent.userName
         $actual.UserLoginSessionEvent.datacenter -is [hashtable] | Should -Be $true
         $actual.UserLoginSessionEvent.datacenter.name | Should -Be $expected.UserLoginSessionEvent.datacenter.name
         $actual.UserLoginSessionEvent.datacenter.datacenter | Should -Be $expected.UserLoginSessionEvent.datacenter.datacenter
         $actual.UserLoginSessionEvent.host -is [hashtable] | Should -Be $true
         $actual.UserLoginSessionEvent.host.name | Should -Be $expected.UserLoginSessionEvent.host.name
         $actual.UserLoginSessionEvent.host.host | Should -Be $expected.UserLoginSessionEvent.host.host
         $actual.UserLoginSessionEvent.fullFormattedMessage | Should -Be $expected.UserLoginSessionEvent.fullFormattedMessage
      }

      It "Should convert XML with nested elements to a hashtable with ConvertMode = 'AttrValueWhenAttributes'" {
         # Arrange
         $inputXml = '<UserLoginSessionEvent><key>8570</key><chainId>8570</chainId><createdTime>2021-02-04T08:51:53.723999Z</createdTime><userName>dcui</userName><datacenter><name>vcqaDC</name><datacenter type="Datacenter">datacenter-2</datacenter></datacenter><computeResource><name>cls</name><computeResource type="ClusterComputeResource">domain-c7</computeResource></computeResource><host><name>10.161.140.163</name><host type="HostSystem">host-21</host></host><fullFormattedMessage>User dcui@127.0.0.1 logged in as VMware-client/6.5.0</fullFormattedMessage><ipAddress>127.0.0.1</ipAddress><userAgent>VMware-client/6.4.0</userAgent><locale>en</locale><sessionId>52b910cf-661f-f72d-9f86-fb82113404b7</sessionId></UserLoginSessionEvent>'
         $expected = @{
            'UserLoginSessionEvent' = @{
               'key' = '8570'
               'createdTime' = '2021-02-04T08:51:53.723999Z'
               'userName' = 'dcui'
               'datacenter' = @{
                  'name' = 'vcqaDC'
                  'datacenter' = @{
                     'Attributes' = @{
                        'type' = 'Datacenter'
                     }
                     'Value' = 'datacenter-2'
                  }
               }
               'computeResource' = @{
                  'name' = 'cls'
                  'computeResource' = @{
                     'Attributes' = @{
                        'type' = 'ClusterComputeResource'
                     }
                     'Value' = 'domain-c7'
                  }
               }
               'host' = @{
                  'name' = '10.161.140.163'
                  'host' = @{
                     'Attributes' = @{
                        'type' = 'HostSystem'
                     }
                     'Value' = 'host-21'
                  }
               }
               'fullFormattedMessage' = 'User dcui@127.0.0.1 logged in as VMware-client/6.5.0'
               'ipAddress' = '127.0.0.1'
               'userAgent' = 'VMware-client/6.4.0'
               'locale' = 'en'
               'sessionId' = '52b910cf-661f-f72d-9f86-fb82113404b7'
            }
         }

         # Act
         $actual = ConvertFrom-CEDataXml -InputString $inputXml -ConvertMode AttrValueWhenAttributes

         # Assert
         $actual | Should -Not -Be $null
         $actual -is [hashtable] | Should -Be $true
         $actual.UserLoginSessionEvent -is [hashtable] | Should -Be $true
         $actual.UserLoginSessionEvent.key | Should -Be $expected.UserLoginSessionEvent.key
         $actual.UserLoginSessionEvent.createdTime | Should -Be $expected.UserLoginSessionEvent.createdTime
         $actual.UserLoginSessionEvent.userName | Should -Be $expected.UserLoginSessionEvent.userName
         $actual.UserLoginSessionEvent.datacenter -is [hashtable] | Should -Be $true
         $actual.UserLoginSessionEvent.datacenter.name | Should -Be $expected.UserLoginSessionEvent.datacenter.name
         $actual.UserLoginSessionEvent.datacenter.datacenter.Attributes.type | Should -Be $expected.UserLoginSessionEvent.datacenter.datacenter.Attributes.type
         $actual.UserLoginSessionEvent.datacenter.datacenter.Value | Should -Be $expected.UserLoginSessionEvent.datacenter.datacenter.Value
         $actual.UserLoginSessionEvent.computeResource.computeResource.Attributes.type | Should -Be $expected.UserLoginSessionEvent.computeResource.computeResource.Attributes.type
         $actual.UserLoginSessionEvent.computeResource.computeResource.Value | Should -Be $expected.UserLoginSessionEvent.computeResource.computeResource.Value
         $actual.UserLoginSessionEvent.host.host.Attributes.type | Should -Be $expected.UserLoginSessionEvent.host.host.Attributes.type
         $actual.UserLoginSessionEvent.host.host.Value | Should -Be $expected.UserLoginSessionEvent.host.host.Value
      }
   }

   Context "ConvertTo-CEDataXml" {
      It "Should convert single hashtable to XML" {
         # Arrange
         $inputHashtable = @{'key' = 'value'}
         $expected = "<key>value</key>"

         # Act
         $actual = ConvertTo-CEDataXml -InputObject $inputHashtable -AttributesKeysInElementAttributes $false

         # Assert
         $actual | Should -Be $expected
      }

      It "Should convert hashtable with array values to XML " {
         # Arrange
         $inputHashtable = @{'keys' = @{'key' = @('value1', 'value2', 'value3')}}
         $expected = "<keys><key>value1</key><key>value2</key><key>value3</key></keys>"

         # Act
         $actual = ConvertTo-CEDataXml -InputObject $inputHashtable -AttributesKeysInElementAttributes $false

         # Assert
         $actual | Should -Be $expected
      }

      It "Should convert hashtable with hashtable values to XML " {
         # Arrange
         $inputHashtable = @{
            'UserLoginSessionEvent' = @{
               'datacenter' = @{
                  'datacenter' = 'datacenter-2'
               }
            }
         }
         $expected = '<UserLoginSessionEvent><datacenter><datacenter>datacenter-2</datacenter></datacenter></UserLoginSessionEvent>'

         # Act
         $actual = ConvertTo-CEDataXml -InputObject $inputHashtable -AttributesKeysInElementAttributes $false

         # Assert
         $actual | Should -Be $expected
      }

      It "Should convert hashtable with Attributes keys to XML elements without attributes" {
         # Arrange
         $inputHashtable = @{
            'UserLoginSessionEvent' = @{
               'computeResource' = @{
                  'name' = 'cls'
                  'computeResource' = @{
                     'Attributes' = @{
                        'type' = 'ClusterComputeResource'
                     }
                     'Value' = 'domain-c7'
                  }
               }
            }
         }
         $expected = '<UserLoginSessionEvent><computeResource><computeResource><Attributes><type>ClusterComputeResource</type></Attributes><Value>domain-c7</Value></computeResource><name>cls</name></computeResource></UserLoginSessionEvent>'

         # Act
         $actual = ConvertTo-CEDataXml -InputObject $inputHashtable -AttributesKeysInElementAttributes $false

         # Assert
         ## We can not expected the xml elements to be ordered as in the expected string,
         ## so test Xml ignoring the elements order
         $actual.Contains('<Attributes><type>ClusterComputeResource</type>') | Should -Be $true
         $actual.Contains('<Value>domain-c7</Value>') | Should -Be $true
         $actual.Contains('<name>cls</name>') | Should -Be $true
         $actual.IndexOf('<Attributes>') | Should -BeGreaterThan $actual.IndexOf('<computeResource><computeResource>')
         $actual.IndexOf('<Value>') | Should -BeLessThan $actual.IndexOf('</computeResource>')
      }


      It "Should convert hashtable with Attributes keys to XML elements with attributes" {
         # Arrange
         $inputHashtable = @{
            'UserLoginSessionEvent' = @{
               'computeResource' = @{
                  'name' = 'cls'
                  'computeResource' = @{
                     'Attributes' = @{
                        'type' = 'ClusterComputeResource'
                     }
                     'Value' = 'domain-c7'
                  }
               }
            }
         }
         $expected = '<UserLoginSessionEvent><computeResource><computeResource type="ClusterComputeResource">domain-c7</computeResource><name>cls</name></computeResource></UserLoginSessionEvent>'

         # Act
         $actual = ConvertTo-CEDataXml -InputObject $inputHashtable -AttributesKeysInElementAttributes $true

         # Assert
          ## We can not expected the xml elements to be ordered as in the expected string,
         ## so test Xml ignoring the elements order
         $actual.StartsWith('<UserLoginSessionEvent>') | Should -Be $true
         $actual.Contains('<computeResource type="ClusterComputeResource">domain-c7</computeResource>') | Should -Be $true
         $actual.Contains('<name>cls</name>') | Should -Be $true
      }

      It "Should throw when input hashtable has more than one root" {
         # Arrange
         $inputHashtable = @{'key1' = 'val1'; 'key2' = 'val2'}

         # Act & Assert
         { ConvertTo-CEDataXml -InputObject $inputHashtable -AttributesKeysInElementAttributes $false } | Should -Throw 'Input Hashtable must have single root key'
      }
   }
}