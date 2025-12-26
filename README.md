# Pronghorn Framework (Forked with Jolt Networking)

This is a **fork of the [Pronghorn Framework](https://github.com/Iron-Stag-Games/Pronghorn)** with an upgraded networking system using [**Jolt**](https://devforum.roblox.com/t/jolt-a-high-performance-type-safe-and-developer-friendly-networking-library-for-roblox/4095212)

Everything else works like the original Pronghorn Framework, but with slight network differences



### Example: Client
```lua
local Remotes = require(ReplicatedStorage.Pronghorn.Remotes)

-- Fire a remote to the server
Remotes.Server:Fire("Hi")
```

### Example: Server
```lua
function SignalListener:Deferred(): ()
    local clientSignalRemote = Remotes.Server("ClientSignal")
	
    clientSignalRemote:Connect(function(player: Player, ...: any)
        Print("Client signal received from", player.Name, ...)
    end)
end
```
