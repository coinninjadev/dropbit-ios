# DropBit

iOS Bitcoin client app, powered by [Coin Ninja](https://coinninja.com).  

Currently, Coin Ninja does not support any non-Coin-Ninja build process. We are providing this software as open source for transparency purposes, but not to be externally buildable.  

## Getting Started
Ensure you have the prerequisites listed below, then go to the "Installing, Testing, and Running" section.

### Prerequisites

* Xcode >= 9.2
* Xcode command line tools (`xcode-select --install`)
* macOS >= 10.13
* ruby >= 2.5.0 (2.6.5 currently used)
* Bundler (`gem install bundler`)
* [HomeBrew](https://brew.sh)

### Installing, Testing, and Running
* Clone the project
* Ensure you have access to the [CNBitcoinKit](https://github.com/coinninjadev/CNBitcoinKit) repo
* From your preferred Terminal app, in the project root, execute `bundle install`

If not running/testing the app via Fastlane (i.e., you'll be using Xcode), execute the following before running/testing:
* `brew bundle`
* `carthage update --platform iOS` (assumes you have valid SSH access to the CNBitcoinKit repo)
* Open Xcode
* To test, select a device from the CoinKeeper scheme, then press Cmd + U. UI Integration Tests will likely fail outside of the Coin Ninja organization.
* To run, select a device from the CoinKeeper scheme, then press Cmd + R

To run the tests without Xcode, execute the following:
* `bundle exec fastlane test`
This will install all necessary dependencies, and remove and reinstall all available simulators.

If adding new dependencies via Carthage, update the `Cartfile` as needed, then simply run the following:
* `bundle exec fastlane update_carthage`
...or if you only want to install the one dependency without possibly updating others...
* `carthage update <name_of_new_dependency> --platform iOS`

To run the project, open the .xcodeproj file in Xcode, select a device to run on from the Scheme drop-down, then press Cmd + R.

## Overall Architecture, Conventions, and Style
This app is built using the [Coordinator Pattern](http://khanlou.com/2015/10/coordinators-redux/), allowing for smaller View Controllers, better testability, and better separation of concerns.  

The app uses Storyboards for building out the visual elements, and Xibs for commonly reused views. Convenience methods exist to easily instantiate them, such as `makeFromStoryboard()` or `xibSetup()`.  

### Storyboards
Storyboards only have one requirement in this application; to keep naming consistent. This requires that for a View Controller named FooViewController:

* The Storyboard filename is FooViewController.storyboard
* The Storyboard Identifier is FooViewController
* The ViewController itself is FooViewController.swift
* FooViewController is marked as a `final class`, and conforms to `StoryboardInitializable` with no extra implementation

Better, more generic implementations may exist, but that refactoring can be handled at a later time.

### Xibs
Look at existing Xib files to identify how they are instantiated. An extension on `UIView` defines a method called `xibSetup` which loads the nib.

### Coordinator
The AppCoordinator class is the main coordinator for the app. It manages injecting dependencies to objects, instantiating those dependencies, and app flow.  

The interaction that a View Controller has with the AppCoordinator is that of delegation. The View Controller has no idea that it is called `AppCoordinator`, it only knows of it as a delegate that conforms to a certain list of things.  

To keep this flow consistent, any new View Controllers created should contain a `weak` reference to a variable of the delegate type, and the AppCoordinator will assign itself as the delegate.  
This allows for testing to easily identify that a View Controller asks the proper questions or tells the proper commands to its delegate, and then testing that the coordinator follows through on those questions/commands.  

The AppCoordinator maintains a Navigation Controller and manages all the navigation there in. Segues are not used, unless if for a container view, for example.  

### Conventions
There is a `.swiftlint.yml` file in the root of the project. Please review it for knowledge, but also if things should be added/removed.  

There is also a Build Phase for SwiftLint so you will see build warnings in Xcode right away when building.  

To easily check for violations without building, at the command line you can enter:
`swiftlint lint`

To easily fix auto-correctable issues, run:
`swiftlint autocorrect`

**Please do not** submit merge requests without first linting your code. Keeping warnings in Xcode to a minimum is preferred; i.e., for known temporary issues, and/or bugs in iOS/CocoaTouch/Xcode/etc that are out of our control (like some Biometric warnings).  

## Built With

* [Fastlane](http://fastlane.tools/) - Automation
* [Carthage](https://github.com/Carthage/Carthage/) - Dependency Management
* [CocoaPods](https://cocoapods.org) - Dependency Management

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

### Git Remote Structure
We currently use a forking structure, wherein you fork the repository you would like to contribute to, and then submit merge requests when done working on a feature.

It is wise to keep remote references to both your fork and the main repository in your list of remotes, for example the suggested flow:

* Clone this repository locally
* Fork this repository
* Add your fork's URL as a new remote in your cloned copy (`git remote add <your-remote-name> <remote-url>`), where `<your-remote-name>` is just some identifier for you other than `origin`
* When pushing your new branch to a remote, push it to your fork, such as: `git push -u <your-remote-name> <branch-name>`
* When submitting a merge request, submit it to the `develop` branch of the main repository (unless it makes sense to merge into another branch)
* The `develop` branch is the default branch in the main repository

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **BJ Miller** - *Initial work* - [Coin Ninja](https://coinninja.com)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


