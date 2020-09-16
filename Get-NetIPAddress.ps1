Function Get-NetIPAddress {
	$Adapters = Get-WmiObject Win32_NetworkAdapter -Filter "NetEnabled='True'"
	$AllIpAddress = new-object collections.generic.list[object]
	ForEach ($Adapter in $Adapters) {
		$IFName = $Adapter.NetConnectionID
		$IFindex = $Adapter.Index
		$netsh = netsh int ipv4 show ipaddresses interface=$IFName
		$config = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "Index = $IFindex"
		
		$mask = ([IPAddress]$config.IPSubnet[0]).Address
		for ( $bitCount = 0; $mask -ne 0; $bitCount++ ) {
			$mask = $mask -band ($mask - 1)
		}
		
		ForEach ( $Address in $config.IPAddress ) {
			$strMatch = "Address {0} Parameters" -f $Address
			$index = [array]::IndexOf($netsh,$strMatch)
			$endIndex = $index + 10
			for ($i=$index;$i -lt $endIndex; $i++) {
				if ( $netsh[$i] -match "Skip as Source" ) {
					$SkipAsSource = $netsh[$i].Split(":")[1].Trim()
				}
				if ( $netsh[$i] -match "Address Type" ) {
					$AddressType = $netsh[$i].Split(":")[1].Trim()
				}
				if ( $netsh[$i] -match "DAD State" ) {
					$DadState = $netsh[$i].Split(":")[1].Trim()
				}
			}
			
			$Parse = [ipaddress]::Parse($Address)
			if ( $Parse.AddressFamily -eq "InterNetwork" ) {
				$Family = "IPv4"
			}
			else { $Family = "IPv6" }
			
			New-Object -Type PSCustomObject -Prop @{
				IPAddress = $Address
				InterfaceAlias = $IFName
				InterfaceIndex = $Adapter.InterfaceIndex
				MacAddress = $Adapter.MACAddress
				AddressFamily = $Family
				Type = ""
				PrefixLength = $bitCount
				PrefixOrigin = $AddressType
				SuffixOrigin = $AddressType
				AddressState =  $DadState
				ValidLifetime = ""
				PreferredLifetime = ""
				SkipAsSource = $SkipAsSource
				PolicyStore = ""
			}			
		}
	}
}
