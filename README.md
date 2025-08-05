# wakatime.hx

a Helix plugin to interface with Wakatime

## Installation
Install [Helix with Steel support](https://github.com/mattwparas/helix/blob/steel-event-system/STEEL.md).
To install `wakatime.hx`, use Forge:
```sh
forge pkg install --git https://github.com/bigspeedfpv/wakatime.hx
```

Finally, load Wakatime somewhere in your config:
```scheme
(register-wakatime)
```

### TODO
- [x] send heartbeats
- [] download wakatime-cli
- [] better .wakatime.cfg parsing - allow setting values
- [] report wakatime errors
