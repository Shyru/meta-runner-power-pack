###
. "$(Join-Path $PSScriptRoot '_TestContext.ps1')"
###

function Add-NuSpecVersion {
	param(
		[String]$Version,
		[String]$FileName
	)
	
	$nuspec_template = $(Get-Content $(Join-Path $PSScriptRoot template.nuspec)) -as [Xml]
	$nuspec_template.package.metadata.version = $Version
	Setup -File -Path $FileName -Content $nuspec_template.OuterXml
	$mr.NuSpecFilePath = $FileName
}

Fixture "Get-SemVer" {
	$mr.IgnoreBuildMetaData = "$false"
	Mock Get-BuildMetaData {return $build_counter }
	$mr.ManualVersion = ""
	
	Given "that a nuspec filepath has been set" {
		Add-NuSpecVersion "1.4.0" "test.nuspec"		
		$expected = Get-NuSpecVersion
		
		Then "'MAJOR.MINOR.PATCH' should be read from the nuspec version" {
			Get-SemVer | Should Be $("$expected+$build_counter")
		}
	}
	
	Given "that a manual version has been set and a nuspec file has also been set" {
		Add-NuSpecVersion "1.4.5" "nuget.nuspec"
		$mr.ManualVersion = "1.4.4"
		
		Then "'MAJOR.MINOR.PATCH' should always come from the manual version no matter what" {
			Get-SemVer | Should Be $("1.4.4+$build_counter")			
		}
	}
	
	Given "that all attempts to get a valid version fails" {
		$mr.ManualVersion = ""
		$mr.NuSpecFilePath = ""
		Mock Write-Error {}
		
		Then "an error should be shown" {
			Get-SemVer
			
			Assert-MockCalled Write-Error 1
		}
	}
	
	Given "that no build metadata is requested" {
		$mr.IgnoreBuildMetaData = "$true"
		$mr.ManualVersion = "1.4.4"
		
		Then "the semver should not include the build metadata part" {
			Get-SemVer | Should Be "1.4.4"
			
			Assert-MockCalled Get-BuildMetaData -Exactly 0	
		}
	}
}

Fixture "Get-BuildMetaData" {
	$mr.BuildCounter = $build_counter
	
	# dropdown with values?
	
	Given "that the Revision Type is SHA" {
		$mr.RevisionType = "SHA"
		$git_hash = "4112e01dabedb68fc66006085ae68df697b5ad9d"
		$git_short_hash = $git_hash.SubString(0,7)
		$mr.BuildVCSNumber = $git_hash
		
		Then "the build metadata should include the short git hash style revision" {
			Get-BuildMetaData | Should Be $("{0}.{1}" -f $build_counter, $git_short_hash)
		}
	}
	
	Given "that the Revision Type is 'Standard'" {
		$mr.RevisionType = "STD"
		$mr.BuildVCSNumber = "33"
		
		Then "the build metadata should not process the revision" {
			Get-BuildMetaData | Should Be $("{0}.{1}" -f $build_counter, "33")
		}
	}
	
	Given "that no Revision Type is set" {
		$mr.RevisionType = ""
		
		Then "the build metadata should not include the VCS revision" {
			Get-BuildMetaData | Should Be $build_counter
		}
	}
	

}

Fixture "Get-NuSpecVersion" {
	
	Given "that the nuspec file is not a valid nuspec file" {
		Setup -File notvalid.nuspec #no xml
		$mr.NuSpecFilePath = "notvalid.nuspec"
		Mock Write-Error {}
		
		Then "an error should be displayed" {
			Get-NuSpecVersion
			
			Assert-MockCalled Write-Error 1
		}
	}
	
	Given "that the nuspec file has no valid version" {
		Add-NuSpecVersion "$version$" "nuget.nuspec"
		Mock Write-Error {}
		
		Then "an error should be displayed" {
			Get-NuSpecVersion
			
			Assert-MockCalled Write-Error 1
		}
	}
}



