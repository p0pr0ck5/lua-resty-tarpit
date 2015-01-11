##Name

FreeWAF - Non-blocking WAF built on the OpenResty stack
lua-resty-tarpit - capture and delay unwanted requests

##Status

lua-resty-tarpit is in early development and is considered production ready.

##Description

lua-resty-tarpit provides rate-limit protection for sensitive resources. It leverages Nginx's non-blocking archtitecture to artificially increase response latency for resources that are repeatedly accessed. This functionality is designed to protect resources are publicly accessible, but vulnerable to some form of brute-force attack (e.g., web application admnistrative login pages). It was inspired by the TARPIT iptables module.

##Installation

Clone the lua-resty-tarpit repo into Nginx/OpenResty's Lua package path. Module setup and configuration is detailed in the synopsis.

##Synopsis

```lua
	http {
		lua_shared_dict tarpit 10m;
	}

	server {
		location /login { # or whatever resource you want to protect
			access_by_lua '
				local t = require "tarpit"
				t.tarpit(
					5, -- request limit
					5, -- reset timer
					1, -- delay time
				)
			';
		}
	}
```

##Limitations

lua-resty-tarpit is undergoing continual development and improvement, and as such, may be limited in its functionality and performance. Currently known limitations can be found within the GitHub issue tracker for this repo. 

##License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>

##Bugs

Please report bugs by creating a ticket with the GitHub issue tracker.
