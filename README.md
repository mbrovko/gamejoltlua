# GameJolt.lua
Provides access to GameJolt's services for Lua-based projects.

# Projects using gamejolt.lua
[One Bit Arena](http://gamejolt.com/games/one-bit-arena/41484)   
[Random Rooms](http://gamejolt.com/games/random-rooms/85035)

# Usage
Put the files from the repo into your app's folder.

```lua
local GJ = require "gamejolt"

GJ.init(gameID, gameKey)
GJ.authUser(username, usertoken)
GJ.openSession()

-- your further manipulations
```

Haxe-styled interface for GameJolt module:

```haxe
interface GameJolt {
	static var username:String;
	static var userToken:String;
	static var isLoggedIn:Bool;
	static function init(id:Int, key:String, ?args:Dynamic):Void;
	// users
	static function authUser(name:String, token:String):Bool;
	static function fetchUserByName(name:String):UserInfo;
	static function fetchUserByID(id:Int):UserInfo;
	static function getCredentials(dir:String):Dynamic;
	// sessions
	static function openSession():Bool;
	static function pingSession(active:Bool):Bool;
	static function closeSession():Bool;
	// data store
	static function fetchData(key:String, ?isGlobal:Bool):Dynamic;
	static function setData(key:String, data:Dynamic, ?isGlobal:Bool):Bool;
	static function setBigData(key:String, data:Dynamic, ?isGlobal:Bool):Bool;
	static function updateData(key:String, value:String, operation:String, ?isGlobal:Bool):String;
	static function removeData(key:String, ?isGlobal:Bool):Bool;
	static function fetchStorageKeys(?isGlobal:Bool):Array<String>;
	// trophies
	static function giveTrophy(id:Int):Bool;
	static function fetchTrophy(id:Int):TrophyInfo;
	static function fetchTrophiesByStatus(achieved:Bool):Array<TrophyInfo>;
	static function fetchAllTrophies():Array<TrophyInfo>;
	// scores
	static function addScore(score:Float, desc:String, ?tableID:Int, ?guestName:String, ?extraData:String):Bool;
	static function fetchScores(limit:Int, ?tableID:Int):Array<ScoreInfo>;
	static function fetchTables():Array<TableInfo>;
}
```
Visit [wiki](https://github.com/insweater/gamejoltlua/wiki) / [docs](http://gamejolt.com/api/doc/game/) for more information.

# Credits
GameJolt.lua is using kikito's [MD5](https://github.com/kikito/md5.lua) and [LuaSocket](http://w3.impa.br/~diego/software/luasocket/home.html).

# License (MIT)
Copyright (c) 2015 [@insweater](http://github.com/insweater), [@Positive07](http://github.com/Positive07) and team.  
This library is released under the [MIT](http://opensource.org/licenses/MIT) license.
