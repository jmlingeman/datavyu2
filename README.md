# Datavyu 2.0

## Installion

Not yet released.

## Requirements

- MacOS 11.0 or higher

## Why?

Datavyu was a piece of software built during a time where Java was in deep transition between Java 6, 8, and (later) 10.
This led to a lot of design decisions that were not very future proof -- the video stack in particular fell apart as 
video codecs required more CPU power or dedicated hardware to decode, and the interface was half developed in the relic that is Java Swing.

Datavyu is a unique tool deeply in need of improvements, but no other software exists to fill the gap.
Re-implementation in a modern framework (SwiftUI, specifically) will help to ensure future generations of researchers will be able to use this tool.

## Why SwiftUI?
SwiftUI was chosen for several reasons: It is Apple's brand new UI design language, so it will likely be supported for quite a while.
Additionally, the MacOS video playback stack is by far the best available out of the box for this project.
FFMpeg is too unwieldly and sensitive for interactive use in the way that Datavyu demands, and the Windows video playback stack is a joke.

## What about Datavyu 1 and people stuck on Windows?
Datavyu 2.0 aims to be interoperable with both .opf files from Datavyu 1 and Ruby scripts from Datavyu 1.
This means that files created in Datavyu 1.* will work in Datavyu 2, and vice versa.

## What is new?
There are four main new features in the design of Datavyu 2.0:

1. A proper JSON API that exposes Datavyu's internals to scripts running externally to Datavyu.
2. Quality-of-life features (resizable columns, pinned column names, rebindable keyboard shortcuts, non-numpad keyboard shortcuts, unified timeline/video UI, improved timeline, improved scripting)
3. Study/Project management
4. Project history

## What do you mean by "Project Management"?
When Datavyu was initially planned, it was one of three components: Datavyu for data coding, Databrary for data storage/sharing, 
and a project manager software to help facilitate interoperability between Databrary and Datavyu.
This last project never happened.
Datavyu 2.0 aims to rectify this by being able to manage a set of opf files and videos (either linked locally or linked to a remote server).
This will allow users to easily see their coding progress, keep column arguments in sync across the project, and run scripts across an entire study without having to program it directly into the script.

## What do you mean by "Project History"?
One of the limitations of Datavyu was that we did not keep previous versions of the .opf file anywhere -- the history of each file was simply lost.
Datavyu 2.0 will include the ability to see .opf as various historical states, so users can see coding progress, or roll back changes that a script made, etc.

## What about Windows?
Sadly, there is not a suitable cross-platform framework that has the feature set that Datavyu requires.
Web frameworks are all too limited in their video stack to work, and are subject to some fairly serious security issues if users (or us maintainers) do not keep everything perfectly up-to-date.
Java suffers in the video stack still as well, Rust's UI tools are too nascent and Python's UI tools are either too out of date or too limited.
Mono is an option, but is finicky on MacOS, which has always been the primary target of MacSHAPA, OpenSHAPA, and Datavyu.
The kind of heavyweight video playback Datavyu needs to be able to perform is best done using native code that lives as close to the operating system as possible.

So this means that Datavyu 2.0 will not be available on Windows or Linux and this will not change unless SwiftUI is ported to those systems (unlikely) or someone else wants to fork the code and re-work it in C#/mono or similar.
Interoperability with Datavyu 1.* will be supported, however.

## Timeline
When it's done.

More details will be added as development continues.

## Feature Implementation Checklist
- [x] Video Playback
- [x] Weak Temporal Ordering Layout
- [ ] Hidden Columns
- [x] File saving/loading
- [ ] Ordinal Layout
- [ ] Ruby Scripting
- [ ] API
- [x] Code Editor
- [ ] Options menu
- [ ] Auto update
- [ ] App Store Deployment
- [x] Track timeline
- [ ] Audio Visualizations
- [x] Video sync
