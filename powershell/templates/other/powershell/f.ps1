function New-F {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (

    )

    begin {

    }

    process {
        if ($PSCmdlet.ShouldProcess('placeholder', 'Run placeholder action')) {
            Write-Verbose 'Placeholder function executed.'
        }
    }

    end {

    }
}
