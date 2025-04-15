$fonts = @(
    @{
        name = "Poppins-Regular"
        url = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Regular.ttf"
    },
    @{
        name = "Poppins-Medium"
        url = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Medium.ttf"
    },
    @{
        name = "Poppins-SemiBold"
        url = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-SemiBold.ttf"
    },
    @{
        name = "Poppins-Bold"
        url = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Bold.ttf"
    },
    @{
        name = "Poppins-Black"
        url = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Black.ttf"
    }
)

foreach ($font in $fonts) {
    $outputPath = "assets/fonts/$($font.name).ttf"
    Write-Host "Downloading $($font.name)..."
    Invoke-WebRequest -Uri $font.url -OutFile $outputPath
}
