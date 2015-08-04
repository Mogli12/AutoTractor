# AutoTractor for Farming Simulator 2015

## Description
AutoTractor is an alternative helper for tractors. 
 
## How does it work?
AutoTractor automatically inserts itself into all vehicles if they already have the specialization aiTractor. When starting this alternative helper it briefly scans the field at the current tractor position. 
But apart from this, AutoTractor has only a little idea of ​​where it is on the field. Instead, this mod looks, starting from the current position, for the border between untouched and already worked area is. 
This works much like AutoCombine. 

However, a combine is much easier to steer. The cutter is mounted rigidly forward. Turning to the left, then the cutter goes to the left.
In tractors, it is unfortunately more complicated. The tool can be mounted front or rear rigid. Larger tools are mounted in the rear and are movable. 
So turning to the left the cultivator or plough will first turn in the other direction. Therefore AutoTractor requires much more computing power. 
Actually, you can not calculate the route accurately enough without the FPS' going down strongly. 

## When you should not use AutoTractor?
On beautiful rectangular fields you can better use the normal hired worker. The headland settings in AutoTractor work for the normal hired worker as well. 
AutoTractor does not work together with other mods changing the behaviour of the hired worker .

If you want to go a a certain path on the field then I recommend using CoursePlay. For simple following tasks the mod FollowMe is great. I have the two mods together with AutoTractor in my mods folder.

## Known Issues
Unfortunately, it happens again and again that frame rates drop. When starting AutoTractor you should make sure that the rear wheels of the tractor are already on the correct field.
Concave field margins let the FPS decrease strongly. This problem I have not yet fully under control. Apparently, this phenomenon occurs less strong in circular mode.

For mowing grass you have to mow once around the area to be mowed around itself. The field-scanner then tries to determine the interior. Tedders are supported but windrows not.

## How to
With the 5 key to open the AutoTractor hud . There you will find 15 buttons . Here whose assignment is in the following scheme:
A1 A2 A3 A4 A5
B1 B2 B3 B4 B5
C1 C2 C3 C4 C5
D1 D2 D3 D4 D5
* A1: hired worker on/off
* A2: swap between the built-in helper of Giants and the AutoTractor helper (default)
* A3: switching between up-/down-mode (default) and circular mode
* A4: automatic steering. Here AutoTractor only takes over the steering. You have to operate throttle and brake on your own. 
* A5: during the turning maneuver you can jump to the next step . This is sometimes needed when the hired worker is stuck

* B1: headland on/off (default is off). Headland only works in up-/down-mode
* B2: small or big headland 
* B3: collision check on/off (default is off)
* B4: turning mode
* B5: Seed consumption (Default is On). From Patch 1.2 of helpers used basically the existing seed. If this button is on then hired worker will stop once no more seed is in the tank.

* C1: this button activates the left margin
* C2: this button activates the right edge
* C3: increase maximum steering angle
* C4: reduce maximum steering angle
* C5: support for cultivators in front of a sowing machine

* D1: increase working width
* D2: reduce working width
* D3: more space when turning / headland
* D4: less space when turning / headland
* D5: work in reverse (default off)

In addition, you can still change the speed by pressing buttons 1 and 2. With key 3 you can let pause the helper. 
The buttons for the headland (B1, B2, C3, C4) and seed consumption (B5) now work with the normal hired worker as well. 
AutoTractor supports all devices supported by the normal hired worker plus mowers, tedders, sprayers, fertilizer spreaders, manure spreaders and slurry barrels. 
Additionally, drawn harvesters and defoliators are supported, too. 

## Developer version
Please be aware you're using a developer version, which may and will contain errors, bugs, mistakes and unfinished code. 

You have been warned.

If you're still OK with this, please remember to post possible issues that you find in the developer version. 
That's the only way we can find sources of error and fix them. 
Be as specific as possible:

* tell us the version number
* only use the vehicles necessary, not 10 other ones at a time
* which vehicles are involved, what is the intended action?
* Post! The! Log! to [Gist](https://gist.github.com/) or [PasteBin](http://pastebin.com/)

## Credits
* Mogli12 (Stefan Biedenstein)