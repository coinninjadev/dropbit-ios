fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios config_tooling
```
fastlane ios config_tooling
```
Change toolset per supplied Xcode version in `xcversion.config` file.
### ios bootstrap_carthage
```
fastlane ios bootstrap_carthage
```
Bootstrap Carthage dependencies
### ios update_carthage
```
fastlane ios update_carthage
```
Update Carthage dependencies
### ios autogen
```
fastlane ios autogen
```
Autogenerate Swift code with Sourcery. Current working dir for Fastlane's context is ./fastlane
### ios increment_build
```
fastlane ios increment_build
```
Set build number to current CI Job Number, no commit
### ios register
```
fastlane ios register
```
Register new devices
### ios local_test
```
fastlane ios local_test
```
Local testing, without resetting simulators or cleaning.
### ios unit_tests
```
fastlane ios unit_tests
```
Local testing (unit tests only), without resetting simulators or cleaning.
### ios local_ui_tests
```
fastlane ios local_ui_tests
```
Local testing (UI tests only), without resetting simulators or cleaning.
### ios quick_test
```
fastlane ios quick_test
```
Local testing, without the before_all lane
### ios test
```
fastlane ios test
```
Runs full test suite with clean simulator installations.
### ios ui_tests
```
fastlane ios ui_tests
```
Runs UI tests
### ios beta
```
fastlane ios beta
```
Deploy to TestFlight for beta testing
### ios deploy
```
fastlane ios deploy
```
Deploy to AppStoreConnect for release

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
