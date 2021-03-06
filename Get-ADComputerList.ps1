function Get-ADComputerList {
	[CmdletBinding()]
    param(
		[Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		 [string]$Server=($Env:LOGONSERVER),
		[System.Management.Automation.CredentialAttribute()]$Credential,
		[Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		 [string]$SearchBase=1
	)
	
	begin {}
	
	process {
		$Server = $Server -Replace '^[^\\\\]*\\\\',''
		$PSSession = New-PSSession -Computer ($Server) -Credential $Credential
		if ($SearchBase = 1){
			$OrgUnitSelection = Invoke-command -Session $PSSession `
			 -ArgumentList $Server,$Credential `
			 -ScriptBlock {
				 param ($Server,$Credential)
				 import-module activedirectory
				 $RemOrgUnitList = Get-ADObject `
				  -Server $Server `
				  -Credential $Credential `
				  -Filter { ObjectClass -eq 'organizationalunit' } `
				  -Properties DistinguishedName |`
				  Select-Object -exp DistinguishedName
				 $RemOrgUnitList
			 } | Out-Gridview -Passthru
		} else {
			$OrgUnitSelection = $SearchBase
		}
		
		$FQDNList = Invoke-command -Session $PSSession `
		 -ArgumentList $Server,$Credential,$OrgUnitSelection `
		 -ScriptBlock {
			 param($Server,$Credential,$OrgUnitSelection)
			 $DomainRoot = ((get-addomain -Server $Server -Credential $Credential).DNSRoot)
			 $ComputerNameList = `
			  foreach ($OrgUnit in $OrgUnitSelection) {
				 Get-ADObject `
				   -Filter { ObjectClass -eq "computer" } `
				   -SearchBase $OrgUnit
			 }
			 $ComputerNameList | select-object @{name="Name"; expression={$_.Name+".$DomainRoot"}}
		}
	}
	
	end {
		Write-Output $FQDNList.Name
	}
}

