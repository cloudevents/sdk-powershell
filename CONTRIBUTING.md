# Contributing to CloudEvents sdk-powershell

We welcome and appreciate contributions from the community. Please read this document for different ways of getting involved with the sdk-powershell.

## Contributing to Issues

- Ensure that the issue you are about to file is not already open. If someone has already opened a similar issue, please leave a comment or add a GitHub reaction to the top comment to express your interest.
- If you can't find your issue already, [open a new issue](https://github.com/cloudevents/sdk-powershell/issues/new).

## Contributing to Code
CloudEvents.SDK PowerShell consists of a .NET project that resolves the [CloudEvents sdk-csharp](https://github.com/cloudevents/sdk-csharp) dependency, PowerShell script module with the sdk advanced functions, and Pester tests. 

### Required Toolchain
- [.NET 5.0](https://dotnet.microsoft.com/download/dotnet/5.0) SDK
- [PowerShell 7.0](https://github.com/PowerShell/PowerShell#get-powershell) or higher
- [Pester 5.1.1](https://www.powershellgallery.com/packages/Pester/5.1.1) or higher

### Building and testing
The CloudEvents.Sdk module source code is in the `src` directory. We have unit tests and localhost integration tests available in the `test` directory.<br/>
<br/>
The `build.ps1` script is the entry point to build the module and run the tests. It has two parameters<br/>
&nbsp;&nbsp;&nbsp;1. `OutputDir` - The destination directory for the `CloudEvents.Sdk` module<br/>
&nbsp;&nbsp;&nbsp;2. `TestsType` - Specifies which tests (`none` | `unit` | `integration` | `all`) to run on successful module build.<br/><br/>
Running the `build.ps1` without specifying parameters produce the module in a `CloudEvents.Sdk` directory under the repository root directory, and runs all tests.

### Forks and Pull Requests

Anyone can [fork](https://docs.github.com/en/github/getting-started-with-github/fork-a-repo) the repository into their own user account, where they can make private changes. To contribute your changes back create a [pull request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests). A pull request should relate to an existing issue.<br/>
<br/>
Adding new features or fixing bugs might require adding or updating tests. Before creating a pull request make sure all tests pass locally.