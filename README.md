This is a sample project for [SCNRecorder](https://github.com/gorastudio-ceo/SCNRecorder), which is an iOS library that allows you to record videos and to capture images from ARSCNView, SCNView and ARView (RealityKit). 

This sample project is based on the standard iOS game template and can be used as as a start point for an iOS app that's using SCNView and wants to include video recording capabilities of the scene.
 
In addition to the standard iOS game template that shows an animation of a space ship, I have added a recording button and a timer to allow a basic usage of the SCNRecorder library.

Additionally, I've integrated a feature that enables automatic termination of video recording after a user-defined time interval. You can tune the amount of seconds by modifying the constant `kSecondsToAutostop`.

When the user hits stop button or the coded amount of seconds are elapsed, the video is saved on the Apple Photos library.

KNOWN ISSUE: When you set the amount of seconds to autostop the video recording, in some cases there's an imprecision of some milliseconds in the final video duration. As an example, running the app on an iPhone X, if I set 60 s, I get a video of 01:00:01 duration (i.e. 1 minute and 0.01 seconds).
