# How to create a Release

We use `tags` to drive the creation of the releases. This is handled by the
Github Actions release workflow in
[`ps-ce-sdk-release.yaml`](.github/workflows/ps-ce-sdk-release.yaml).

A new release will upload the `PowerShell` module artifacts to the `PowerShell`
[gallery](https://www.powershellgallery.com/packages/CloudEvents.Sdk).

## Step 1 - Bump Module Version

Bump the `ModuleVersion` in
[`src/CloudEventsPowerShell/CloudEvents.Sdk.psd1`](./src/CloudEventsPowerShell/CloudEvents.Sdk.psd1)
to the next semantic release version (without `"v"` prefix).

```powershell
# Version number of this module.
ModuleVersion = '0.3.0'
```

Create a pull request with this change, review and approve it **after** all checks
have passed.


## Step 2 - Update local `main` branch

Pull in the latest changes, incl. the merged PR above, into your local `main`
branch of this repository **before** creating a `tag` via the `git` CLI.

```console
git checkout main
git fetch -avp
git pull upstream main
```

**Note:** the above commands assume `upstream` pointing to the remote
`https://github.com/cloudevents/sdk-powershell.git`

## Step 3 - Create and push a Tag


```console
RELEASE=v0.3.0
git tag -a $RELEASE -m "Release ${RELEASE}"
git push upstream refs/tags/${RELEASE}
```


This will trigger the release
[workflow](https://github.com/cloudevents/sdk-powershell/actions/workflows/ps-ce-sdk-release.yaml).
**Verify** that it executed successfully and that a new Github
[release](https://github.com/cloudevents/sdk-powershell/releases) was created.

The release workflow also creates a pull request with the updated
[`CHANGELOG.md`](CHANGELOG.md). **Verify**, approve and merge accordingly.

If you need to make changes to the Github release notes, you can edit them on the [release](https://github.com/cloudevents/sdk-powershell/releases) page.
