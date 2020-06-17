#!/bin/bash
################################################################################
##  File:  dotnetcore-sdk.sh
##  Team:  CI-Platform
##  Desc:  Installs .NET Core SDK
################################################################################

source $HELPER_SCRIPTS/apt.sh
source $HELPER_SCRIPTS/document.sh

mksamples()
{
    sdk=$1
    sample=$2
    mkdir "$sdk"
    cd "$sdk" || exit
    set -e
    dotnet help
    dotnet new globaljson --sdk-version "$sdk"
    dotnet new "$sample"
    dotnet restore
    dotnet build
    set +e
    cd .. || exit
    rm -rf "$sdk"
}

set -e

# Install the current release versions for 2 and 3
apt-get install dotnet-runtime-2.1 dotnet-sdk-2.1
apt-get install dotnet-runtime-2.2 dotnet-sdk-2.2
apt-get install dotnet-runtime.3.0 dotnet-sdk-3.0
apt-get install dotnet-runtime.3.1 dotnet-sdk-3.1

#
# Uncomment the following lines to get a bigger list, dynamically;
#
releaseNotesUrl="https://raw.githubusercontent.com/dotnet/core/master/release-notes/releases-index.json"

printf 'Retrieving Release Notes from: %s\n' "$releaseNotesUrl"
releaseNotes=$(curl -s "${releaseNotesUrl}")
releaseNotesDetails=$(echo "${releaseNotes}" | jq 'try ."releases-index"[] | select(."channel-version" >= "2.0" and (."support-phase" == "lts")) | { version: ."channel-version", runtime: ."latest-runtime", sdk: ."latest-sdk", releaseUrl: ."releases.json", eolDate: ."eol-date" }' -c)
#jq '.releases[] | select(."release-version" | contains("preview") | not) | { version: ."release-version", runtime: .runtime.version, runtimeUrl: .runtime.files[].url, sdk: .sdk.version, sdkUrl: .sdk.files[].url } | select((.runtimeUrl | contains("linux-x64")) and (.sdkUrl | contains("linux-x64")))'

platform="linux-x64"
for k in $releaseNotesDetails; do
    version=$(jq -r ".version" <<< "$k" | xargs)
    # runtime=$(jq -r ".runtime" <<< "$k" | xargs)
    # sdk=$(jq -r ".sdk" <<< "$k" | xargs)
    releaseUrl=$(jq -r ".releaseUrl" <<< "$k" | xargs)
    eolDate=$(jq -r ".eolDate" <<< "$k" | xargs)

    printf '    Retrieving Release Details for %s (EOL: %s) from: %s\n' "$version" "$eolDate" "$releaseUrl"
    releaseInfo=$(curl -s "${releaseUrl}")

    releaseInfoDetails=$(echo "${releaseInfo}" | jq 'try .releases[] | select(."release-version" | contains("preview") | not) | { version: ."release-version", runtime: .runtime.version, runtimeUrl: .runtime.files[].url, sdk: .sdk.version, sdkUrl: .sdk.files[].url } | select((.runtimeUrl | contains("'${platform}'")) and (.sdkUrl | contains("'${platform}'")))' -c)

    printf '%s\n' "----------------------------------------"
    printf '%s\n' "$releaseInfoDetails"
    printf '%s\n' "----------------------------------------"

    for r in $releaseInfoDetails; do
        runtimeVersion=$(jq -r ".runtime" <<< "$r" | xargs)
        runtimeDownloadUrl=$(jq -r ".runtimeUrl" <<< "$r" | xargs)
        sdkVersion=$(jq -r ".sdk" <<< "$r" | xargs)
        sdkDownloadUrl=$(jq -r ".sdkUrl" <<< "$r" | xargs)

        # printf '        RUN: %s  %s\n' "$runtimeVersion" "$runtimeDownloadUrl"
        # printf '        SDK: %s  %s\n' "$sdkVersion" "$sdkDownloadUrl"

        #if ! apt-get install -y --no-install-recommends "dotnet-runtime-$version=$runtimeVersion"; then
            # Install manually if not in package repo
            echo "$runtimeDownloadUrl" >> urls
            printf '      Adding runtime v%s to list to download later\n' "$runtimeVersion"
        #fi

        #if ! apt-get install -y --no-install-recommends "dotnet-sdk-$version=$sdkVersion"; then
            # Install manually if not in package repo
            echo "$sdkDownloadUrl" >> urls
            printf '      Adding sdk v%s to list to download later\n' "$sdkVersion"
        #fi

        DocumentInstalledItem ".NET Core Runtime $runtimeVersion"
        DocumentInstalledItem ".NET Core SDK $sdkVersion"

    done | column -t -s$'\t'
done | column -t -s$'\t'

# Download additional SDKs
if test -f "urls"; then
    echo "Downloading release tarballs..."
    sort -u urls | xargs -n 1 -P 16 -I_url -- sh -c 'echo _url && wget -q _url'
    for tarball in *.tar.gz; do
        dest="./tmp-$(basename -s .tar.gz $tarball)"
        echo "Extracting $tarball to $dest"
        mkdir "$dest" && tar -C "$dest" -xzf "$tarball"
        [ -d "$dest/shared" ] && rsync -qav "$dest/shared/" /usr/share/dotnet/shared/ || echo "Directory does not exist: $dest/shared. Skipping..."
        [ -d "$dest/host" ] && rsync -qav "$dest/host/" /usr/share/dotnet/host/ || echo "Directory does not exist: $dest/host. Skipping..."
        [ -d "$dest/sdk" ] && rsync -qav "$dest/sdk/" /usr/share/dotnet/sdk/ || echo "Directory does not exist: $dest/sdk. Skipping..."
        rm -rf "$dest"
        rm "$tarball"
    done
    rm urls
fi

# NB: uncomment the following lines, to smoke test all installed sdks
# for sdk in $sdks; do
#     # mksamples "$sdk" "console"
#     # mksamples "$sdk" "mstest"
#     # mksamples "$sdk" "xunit"
#     # mksamples "$sdk" "web"
#     # mksamples "$sdk" "mvc"
#     # mksamples "$sdk" "webapi"
#     DocumentInstalledItem ".NET Core SDK $sdk"
# done

# NuGetFallbackFolder at /usr/share/dotnet/sdk/NuGetFallbackFolder is warmed up by smoke test
# Additional FTE will just copy to ~/.dotnet/NuGet which provides no benefit on a fungible machine
echo "DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1" | tee -a /etc/environment
echo "PATH=\"/home/vsts/.dotnet/tools:$PATH\"" | tee -a /etc/environment

