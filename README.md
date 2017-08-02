
# react-native-apple-music

## Getting started

`$ npm install react-native-apple-music --save`

### Mostly automatic installation

`$ react-native link react-native-apple-music`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-apple-music` and add `RNAppleMusic.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNAppleMusic.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNAppleMusicPackage;` to the imports at the top of the file
  - Add `new RNAppleMusicPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-apple-music'
  	project(':react-native-apple-music').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-apple-music/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-apple-music')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNAppleMusic.sln` in `node_modules/react-native-apple-music/windows/RNAppleMusic.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Com.Reactlibrary.RNAppleMusic;` to the usings at the top of the file
  - Add `new RNAppleMusicPackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Usage
```javascript
import RNAppleMusic from 'react-native-apple-music';

// TODO: What to do with the module?
RNAppleMusic;
```
  